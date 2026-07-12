/// live_weather_service.dart
///
/// Real-Time Live Meteorological Bridge — Open-Meteo Free API
/// ─────────────────────────────────────────────────────────────────────────
/// Zero-key. Zero authentication. CORS-friendly. Works in prod.
///
/// Defensive flow:
///   GPS available   → fetch with real coordinates
///   GPS denied/timeout → silent failover to Toronto defaults
///   Network OK      → parse + cache payload to SharedPreferences
///   SocketException → load last cached payload + set freshness = cached
///   No cache either → return hardcoded placeholder data
///
/// Open-Meteo endpoint used:
///   https://api.open-meteo.com/v1/forecast
///   ?latitude=&longitude=
///   &current=temperature_2m,relative_humidity_2m,apparent_temperature,
///            is_day,precipitation,rain,showers,snowfall,weather_code,
///            wind_speed_10m,wind_gusts_10m,dew_point_2m
///   &hourly=temperature_2m,precipitation_probability,uv_index,weather_code,
///           dew_point_2m
///   &timezone=auto
library live_weather_service;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show exp;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_sync_ca/domain/usecases/canadian_advice_engine.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/neo_brutalist_weather_canvas.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

/// Whether the current data came from a live API call, an offline cache,
/// or is entirely unavailable (first launch, offline, no cache).
enum DataFreshness { live, cached, unavailable }

/// Application-level weather mode: real data vs manual sim override.
enum AppWeatherMode { liveAir, devSimulation }

// ─────────────────────────────────────────────────────────────────────────────
// WMO WEATHER CODE HELPERS
// ─────────────────────────────────────────────────────────────────────────────

bool _isSnowCode(int code) =>
    (code >= 71 && code <= 77) || code == 85 || code == 86;

bool _isRainCode(int code) =>
    (code >= 51 && code <= 67) ||
    (code >= 80 && code <= 82) ||
    code == 95 || code == 96 || code == 99;

bool _isFogCode(int code) => code == 45 || code == 48;

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class HourlyForecast {
  const HourlyForecast({
    required this.time,
    required this.temperatureC,
    required this.weatherCode,
    required this.precipitationProbabilityPct,
    this.dewPointC,
    this.windGustKmh,
    this.precipitationMm,
  });
  final DateTime time;
  final double temperatureC;
  final int weatherCode;
  final double precipitationProbabilityPct;

  /// Dew-point temperature in °C from Open-Meteo `dew_point_2m`.
  /// Null when the API response predates this field being requested.
  final double? dewPointC;
  
  /// Maximum wind gust speed in km/h.
  final double? windGustKmh;
  
  /// Hourly precipitation accumulation in mm.
  final double? precipitationMm;

  /// Environment Canada Humidex (°C). Non-null only when
  /// [temperatureC] > 0 and [dewPointC] is available.
  double? get humidex {
    final dp = dewPointC;
    if (dp == null || temperatureC <= 0) return null;
    final h = temperatureC +
        0.5555 *
            (6.11 * exp(5417.7530 * (1 / 273.16 - 1 / (dp + 273.15))) - 10);
    return h > temperatureC ? h : null; // only meaningful when > ambient
  }

  Map<String, dynamic> toJson() => {
        'timeIso': time.toIso8601String(),
        'temperatureC': temperatureC,
        'weatherCode': weatherCode,
        'precipitationProbabilityPct': precipitationProbabilityPct,
        if (dewPointC != null) 'dewPointC': dewPointC,
        if (windGustKmh != null) 'windGustKmh': windGustKmh,
        if (precipitationMm != null) 'precipitationMm': precipitationMm,
      };

  factory HourlyForecast.fromJson(Map<String, dynamic> j) => HourlyForecast(
        time: DateTime.parse(j['timeIso'] as String),
        temperatureC: (j['temperatureC'] as num).toDouble(),
        weatherCode: (j['weatherCode'] as num).toInt(),
        precipitationProbabilityPct: (j['precipitationProbabilityPct'] as num).toDouble(),
        dewPointC: (j['dewPointC'] as num?)?.toDouble(),
        windGustKmh: (j['windGustKmh'] as num?)?.toDouble(),
        precipitationMm: (j['precipitationMm'] as num?)?.toDouble(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// DAILY FORECAST MODEL
// ─────────────────────────────────────────────────────────────────────────────

/// WMO weather codes indicating snow squalls / heavy snow.
bool _isHeavySnowCode(int code) =>
    code == 71 || code == 73 || code == 75 || code == 77 ||
    code == 85 || code == 86;

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipProbMax,
    required this.windMaxKmh,
    required this.weatherCode,
    this.snowfallSumCm = 0.0,
    this.uvIndexMax = 0.0,
  });

  final DateTime date;
  final double tempMax;
  final double tempMin;

  /// Max precipitation probability for the day (0–100%).
  final int precipProbMax;

  /// Max wind speed for the day in km/h.
  final double windMaxKmh;

  /// WMO weather code (daily representative).
  final int weatherCode;

  /// Total snowfall accumulation in cm.
  final double snowfallSumCm;

  /// Max UV index for the day.
  final double uvIndexMax;

  bool get isSnowDay => _isSnowCode(weatherCode) || snowfallSumCm > 0.5;
  bool get isRainDay => _isRainCode(weatherCode) && !isSnowDay;
  bool get isHeavySnowDay => _isHeavySnowCode(weatherCode) || snowfallSumCm >= 5.0;

  /// Resolves the best-matching WeatherProfile from the WeatherStateMatrix
  /// using this day's peak metrics. Deep winter blizzard is prioritized when
  /// snowfall_sum >= 5.0 cm or a heavy snow WMO code is present.
  ///
  /// Note: import of WeatherStateMatrix is done in the engine layer to avoid
  /// circular imports. This getter is declared as a method on the engine.

  Map<String, dynamic> toJson() => {
        'dateIso': date.toIso8601String(),
        'tempMax': tempMax,
        'tempMin': tempMin,
        'precipProbMax': precipProbMax,
        'windMaxKmh': windMaxKmh,
        'weatherCode': weatherCode,
        'snowfallSumCm': snowfallSumCm,
        'uvIndexMax': uvIndexMax,
      };

  factory DailyForecast.fromJson(Map<String, dynamic> j) => DailyForecast(
        date: DateTime.parse(j['dateIso'] as String),
        tempMax: (j['tempMax'] as num).toDouble(),
        tempMin: (j['tempMin'] as num).toDouble(),
        precipProbMax: (j['precipProbMax'] as num).toInt(),
        windMaxKmh: (j['windMaxKmh'] as num).toDouble(),
        weatherCode: (j['weatherCode'] as num).toInt(),
        snowfallSumCm: (j['snowfallSumCm'] as num?)?.toDouble() ?? 0.0,
        uvIndexMax: (j['uvIndexMax'] as num?)?.toDouble() ?? 0.0,
      );
}

class LiveWeatherData {
  const LiveWeatherData({
    required this.temperatureC,
    required this.humidity,
    required this.apparentTempC,
    required this.isDay,
    required this.precipitationMm,
    required this.rainMm,
    required this.snowfallCm,
    required this.weatherCode,
    required this.windSpeedKmh,
    required this.windGustKmh,
    required this.precipitationProbabilityPct,
    required this.uvIndex,
    required this.latitude,
    required this.longitude,
    required this.fetchTime,
    required this.freshness,
    required this.isUsingDefaultLocation,
    required this.hourlyForecasts,
    this.cityName,
    this.dewPointC,
    this.sunsetTime,
    this.dailyForecasts = const [],
  });

  final double temperatureC;
  final double humidity;
  final double apparentTempC;
  final bool isDay;
  final double precipitationMm;
  final double rainMm;
  final double snowfallCm;
  final int weatherCode;
  final double windSpeedKmh;
  final double windGustKmh;

  /// 0–100 %
  final double precipitationProbabilityPct;
  final double uvIndex;
  final double latitude;
  final double longitude;
  final DateTime fetchTime;
  final DataFreshness freshness;

  /// True when GPS was denied/timed out and we fell back to Toronto coords.
  final bool isUsingDefaultLocation;

  /// Human-readable city name from reverse geocoding, e.g. "Dundalk, ON".
  /// Null if geocoding is unavailable or running on Web.
  final String? cityName;

  /// 24-hour forecast data
  final List<HourlyForecast> hourlyForecasts;

  /// Current dew-point temperature in °C from Open-Meteo `dew_point_2m`.
  /// Null when not available (cached payload before this field was added).
  final double? dewPointC;

  /// Today's sunset time in local time from Open-Meteo `daily.sunset`.
  /// Null when unavailable or in cached payloads.
  final DateTime? sunsetTime;

  /// 7-day daily forecasts parsed from the Open-Meteo daily array.
  final List<DailyForecast> dailyForecasts;

  // ── Humidex ───────────────────────────────────────────────────────────────

  /// Environment Canada official Humidex formula (°C).
  /// Returns null when [dewPointC] is unavailable or [temperatureC] ≤ 0°C,
  /// or when Humidex would not exceed ambient temperature.
  double? get humidex {
    final dp = dewPointC;
    if (dp == null || temperatureC <= 0) return null;
    final h = temperatureC +
        0.5555 *
            (6.11 * exp(5417.7530 * (1 / 273.16 - 1 / (dp + 273.15))) - 10);
    return h > temperatureC ? h : null;
  }

  // ── Computed helpers ───────────────────────────────────────────────────────

  bool get isSnowing =>
      _isSnowCode(weatherCode) || snowfallCm > 0.3;

  bool get isRaining =>
      (_isRainCode(weatherCode) || precipitationMm > 0.3) && !isSnowing;

  bool get isFoggy => _isFogCode(weatherCode);

  bool get isFreezethaw =>
      temperatureC >= 0 &&
      temperatureC <= 5 &&
      precipitationMm > 0 &&
      !isSnowing;

  /// Maps current conditions to a WeatherAnimationMode canvas state.
  /// Priority order mirrors _SimPreset.canvasMode logic exactly.
  WeatherAnimationMode? get canvasMode {
    final hour = fetchTime.hour;
    if (isSnowing)                               return WeatherAnimationMode.snow;
    if (isRaining)                               return WeatherAnimationMode.rain;
    if (windGustKmh > 70)                        return WeatherAnimationMode.severeWind;
    if (isFreezethaw)                            return WeatherAnimationMode.slush;
    if (temperatureC > 24 && isDay && hour >= 10 && hour < 18)
                                                 return WeatherAnimationMode.summerDay;
    if (!isDay && (hour >= 21 || hour < 5))      return WeatherAnimationMode.clearNight;
    return null;
  }

  /// Maps to `CanadianAdviceParams` for the advice engine.
  CanadianAdviceParams toAdviceParams() => CanadianAdviceParams(
        temperatureC: temperatureC,
        snowfallCm: snowfallCm,
        isSnowing: isSnowing,
        currentHour: fetchTime.hour,
        humidity: humidity,
        uvIndex: uvIndex,
        isRaining: isRaining,
        precipitationMm: precipitationMm,
        isFoggy: isFoggy,
        windGustKmh: windGustKmh,
        isFreezethaw: isFreezethaw,
      );

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'temperatureC': temperatureC,
        'humidity': humidity,
        'apparentTempC': apparentTempC,
        'isDay': isDay,
        'precipitationMm': precipitationMm,
        'rainMm': rainMm,
        'snowfallCm': snowfallCm,
        'weatherCode': weatherCode,
        'windSpeedKmh': windSpeedKmh,
        'windGustKmh': windGustKmh,
        'precipitationProbabilityPct': precipitationProbabilityPct,
        'uvIndex': uvIndex,
        'latitude': latitude,
        'longitude': longitude,
        'fetchTimeIso': fetchTime.toIso8601String(),
        'isUsingDefaultLocation': isUsingDefaultLocation,
        'cityName': cityName,
        'hourlyForecasts': hourlyForecasts.map((e) => e.toJson()).toList(),
        if (dewPointC != null) 'dewPointC': dewPointC,
        'dailyForecasts': dailyForecasts.map((e) => e.toJson()).toList(),
      };

  factory LiveWeatherData.fromJson(Map<String, dynamic> j,
      {DataFreshness freshness = DataFreshness.cached}) =>
      LiveWeatherData(
        temperatureC: (j['temperatureC'] as num).toDouble(),
        humidity: (j['humidity'] as num).toDouble(),
        apparentTempC: (j['apparentTempC'] as num).toDouble(),
        isDay: j['isDay'] as bool,
        precipitationMm: (j['precipitationMm'] as num).toDouble(),
        rainMm: (j['rainMm'] as num).toDouble(),
        snowfallCm: (j['snowfallCm'] as num).toDouble(),
        weatherCode: (j['weatherCode'] as num).toInt(),
        windSpeedKmh: (j['windSpeedKmh'] as num).toDouble(),
        windGustKmh: (j['windGustKmh'] as num).toDouble(),
        precipitationProbabilityPct:
            (j['precipitationProbabilityPct'] as num).toDouble(),
        uvIndex: (j['uvIndex'] as num).toDouble(),
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        fetchTime: DateTime.parse(j['fetchTimeIso'] as String),
        freshness: freshness,
        isUsingDefaultLocation: j['isUsingDefaultLocation'] as bool? ?? false,
        cityName: j['cityName'] as String?,
        dewPointC: (j['dewPointC'] as num?)?.toDouble(),
        hourlyForecasts: (j['hourlyForecasts'] as List?)
                ?.map((e) => HourlyForecast.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        dailyForecasts: (j['dailyForecasts'] as List?)
                ?.map((e) => DailyForecast.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  String get conditionString {
    if (isSnowing) return 'SNOW';
    if (isRaining) return 'RAIN';
    if (isFoggy) return 'FOG';
    if (isFreezethaw) return 'FREEZING RAIN';
    return isDay ? 'CLEAR' : 'CLEAR_NIGHT';
  }

  String get timeOfDayString => isDay ? 'Day' : 'Night';
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class LiveWeatherService {
  LiveWeatherService({Dio? dio, SharedPreferences? prefs})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 8),
                                     receiveTimeout: const Duration(seconds: 8))),
        _prefs = prefs;

  final Dio _dio;
  SharedPreferences? _prefs;

  // ── Canadian regional fallback coordinates (Greater Toronto Area) ──────────
  static const _defaultLat = 43.65;
  static const _defaultLon = -79.38;

  static const _cacheKey      = 'cached_weather_payload';
  static const _cacheTimeKey  = 'cached_weather_time';

  // ── MAIN ENTRY POINT ───────────────────────────────────────────────────────

  /// Fetches live weather data with full defensive failover chain:
  ///   1. GPS → API → cache & return  (happy path)
  ///   2. GPS fail → default coords → API → cache & return
  ///   3. Any network error → cached payload
  ///   4. No cache → hardcoded placeholder
  Future<LiveWeatherData> fetchLiveWeather() async {
    _prefs ??= await SharedPreferences.getInstance();

    // ── Step 1: Resolve coordinates ──────────────────────────────────────────
    double lat, lon;
    bool usingDefault = false;
    String? cityName;

    try {
      final pos = await _resolveLocation();
      lat = pos.latitude;
      lon = pos.longitude;
      cityName = await _resolveCityName(lat, lon);
    } catch (_) {
      // Silent failover: GPS denied, timed out, or service disabled.
      lat = _defaultLat;
      lon = _defaultLon;
      usingDefault = true;
      cityName = 'Toronto, ON'; // canonical fallback label
    }

    // ── Step 2: Fetch from Open-Meteo ────────────────────────────────────────
    try {
      final data = await _fetchFromApi(lat, lon, usingDefault, cityName);
      await _cachePayload(data);
      return data;
    } on SocketException {
      return await _loadCached() ?? _placeholder(lat, lon, usingDefault, cityName);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        return await _loadCached() ?? _placeholder(lat, lon, usingDefault, cityName);
      }
      rethrow;
    }
  }

  // ── GPS RESOLUTION ─────────────────────────────────────────────────────────

  Future<Position> _resolveLocation() async {
    // Check if location services are enabled at system level.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    // 5-second hard timeout — if GPS hasn't fixed in 5s, failover silently.
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.reduced,
        timeLimit: Duration(seconds: 5),
      ),
    );
  }

  // ── REVERSE GEOCODING ─────────────────────────────────────────────────────

  /// Returns a human-readable city label (e.g., "Dundalk, ON").
  /// Gracefully returns null on Web or if geocoding fails.
  Future<String?> _resolveCityName(double lat, double lon) async {
    if (kIsWeb) return null; // geocoding package unsupported on web
    try {
      final geocoder = Geocoding();
      final placemarks = await geocoder.placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final city = p.locality ?? p.subAdministrativeArea ?? '';
      final province = p.administrativeArea ?? '';
      if (city.isEmpty) return province.isEmpty ? null : province;
      return province.isEmpty ? city : '$city, $province';
    } catch (_) {
      return null;
    }
  }

  // ── OPEN-METEO API CALL ───────────────────────────────────────────────────

  Future<LiveWeatherData> _fetchFromApi(
    double lat,
    double lon,
    bool usingDefault,
    String? cityName,
  ) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toStringAsFixed(4),
      'longitude': lon.toStringAsFixed(4),
      'current': [
        'temperature_2m',
        'relative_humidity_2m',
        'apparent_temperature',
        'is_day',
        'precipitation',
        'rain',
        'showers',
        'snowfall',
        'weather_code',
        'wind_speed_10m',
        'wind_gusts_10m',
        'dew_point_2m',
      ].join(','),
      'hourly': 'temperature_2m,precipitation_probability,uv_index,weather_code,dew_point_2m,wind_gusts_10m,precipitation',
      'timezone': 'auto',
      'daily': 'sunset,weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,uv_index_max,snowfall_sum',
    });

    final response = await _dio.getUri<Map<String, dynamic>>(uri);
    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Open-Meteo returned ${response.statusCode}');
    }

    return _parseResponse(response.data!, lat, lon, usingDefault, cityName);
  }

  // ── RESPONSE PARSER ────────────────────────────────────────────────────────

  LiveWeatherData _parseResponse(
    Map<String, dynamic> json,
    double lat,
    double lon,
    bool usingDefault,
    String? cityName,
  ) {
    final current = json['current'] as Map<String, dynamic>;
    final hourly  = json['hourly']  as Map<String, dynamic>;

    // Find index in hourly[] matching the current UTC hour.
    final now = DateTime.now().toUtc();
    final hourTag =
        '${now.year}-${_pad(now.month)}-${_pad(now.day)}T${_pad(now.hour)}:00';
    final hourlyTimes = (hourly['time'] as List).cast<String>();
    final hIdx = hourlyTimes.indexOf(hourTag);

    final precipProb = hIdx >= 0
        ? (hourly['precipitation_probability'][hIdx] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final uvIndex = hIdx >= 0
        ? (hourly['uv_index'][hIdx] as num?)?.toDouble() ?? 0.0
        : 0.0;

    final List<HourlyForecast> forecasts = [];
    final hourlyDewPoints = hourly['dew_point_2m'] as List?;
    final hourlyGusts = hourly['wind_gusts_10m'] as List?;
    final hourlyPrecip = hourly['precipitation'] as List?;
    if (hIdx >= 0) {
      for (int i = hIdx; i < hourlyTimes.length && forecasts.length < 24; i++) {
        forecasts.add(HourlyForecast(
          time: DateTime.parse(hourlyTimes[i]),
          temperatureC: (hourly['temperature_2m'][i] as num).toDouble(),
          weatherCode: (hourly['weather_code'][i] as num).toInt(),
          precipitationProbabilityPct: (hourly['precipitation_probability'][i] as num).toDouble(),
          dewPointC: (hourlyDewPoints?[i] as num?)?.toDouble(),
          windGustKmh: (hourlyGusts?[i] as num?)?.toDouble(),
          precipitationMm: (hourlyPrecip?[i] as num?)?.toDouble(),
        ));
      }
    }

    // ── Parse sunset time and 7-day daily forecasts ───────────────────────
    DateTime? sunsetTime;
    final List<DailyForecast> dailyForecasts = [];
    final daily = json['daily'] as Map<String, dynamic>?;
    if (daily != null) {
      final sunsets = daily['sunset'] as List?;
      if (sunsets != null && sunsets.isNotEmpty) {
        try {
          sunsetTime = DateTime.parse(sunsets[0] as String);
        } catch (_) { /* malformed date string, leave null */ }
      }

      // ── Parse 7-day daily forecasts ─────────────────────────────────────
      final dailyDates       = daily['time'] as List?;
      final dailyTempMax     = daily['temperature_2m_max'] as List?;
      final dailyTempMin     = daily['temperature_2m_min'] as List?;
      final dailyPrecipProb  = daily['precipitation_probability_max'] as List?;
      final dailyWindMax     = daily['wind_speed_10m_max'] as List?;
      final dailyWeatherCode = daily['weather_code'] as List?;
      final dailySnowfall    = daily['snowfall_sum'] as List?;
      final dailyUvMax       = daily['uv_index_max'] as List?;

      if (dailyDates != null) {
        for (int i = 0; i < dailyDates.length; i++) {
          try {
            dailyForecasts.add(DailyForecast(
              date: DateTime.parse(dailyDates[i] as String),
              tempMax: (dailyTempMax?[i] as num?)?.toDouble() ?? 15.0,
              tempMin: (dailyTempMin?[i] as num?)?.toDouble() ?? 5.0,
              precipProbMax: (dailyPrecipProb?[i] as num?)?.toInt() ?? 0,
              windMaxKmh: (dailyWindMax?[i] as num?)?.toDouble() ?? 0.0,
              weatherCode: (dailyWeatherCode?[i] as num?)?.toInt() ?? 0,
              snowfallSumCm: (dailySnowfall?[i] as num?)?.toDouble() ?? 0.0,
              uvIndexMax: (dailyUvMax?[i] as num?)?.toDouble() ?? 0.0,
            ));
          } catch (_) { /* skip malformed day entry */ }
        }
      }
    }

    return LiveWeatherData(
      temperatureC: (current['temperature_2m'] as num).toDouble(),
      humidity:     (current['relative_humidity_2m'] as num).toDouble(),
      apparentTempC:(current['apparent_temperature'] as num).toDouble(),
      isDay:        (current['is_day'] as num) == 1,
      precipitationMm: (current['precipitation'] as num).toDouble(),
      rainMm:       (current['rain'] as num).toDouble(),
      snowfallCm:   (current['snowfall'] as num).toDouble(),
      weatherCode:  (current['weather_code'] as num).toInt(),
      windSpeedKmh: (current['wind_speed_10m'] as num).toDouble(),
      windGustKmh:  (current['wind_gusts_10m'] as num).toDouble(),
      precipitationProbabilityPct: precipProb,
      uvIndex: uvIndex,
      latitude: lat,
      longitude: lon,
      fetchTime: DateTime.now(),
      freshness: DataFreshness.live,
      isUsingDefaultLocation: usingDefault,
      cityName: cityName,
      dewPointC: (current['dew_point_2m'] as num?)?.toDouble(),
      hourlyForecasts: forecasts,
      sunsetTime: sunsetTime,
      dailyForecasts: dailyForecasts,
    );
  }

  // ── CACHE ──────────────────────────────────────────────────────────────────

  Future<void> _cachePayload(LiveWeatherData data) async {
    await _prefs!.setString(_cacheKey, jsonEncode(data.toJson()));
    await _prefs!.setString(_cacheTimeKey, DateTime.now().toIso8601String());
  }

  Future<LiveWeatherData?> _loadCached() async {
    final raw = _prefs!.getString(_cacheKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return LiveWeatherData.fromJson(json, freshness: DataFreshness.cached);
    } catch (_) {
      return null;
    }
  }

  // ── PLACEHOLDER (absolute last resort) ────────────────────────────────────

  LiveWeatherData _placeholder(double lat, double lon, bool usingDefault, String? cityName) =>
      LiveWeatherData(
        temperatureC: 18.0,
        humidity: 65.0,
        apparentTempC: 17.0,
        isDay: true,
        precipitationMm: 0.0,
        rainMm: 0.0,
        snowfallCm: 0.0,
        weatherCode: 2,
        windSpeedKmh: 12.0,
        windGustKmh: 18.0,
        precipitationProbabilityPct: 10.0,
        uvIndex: 3.0,
        latitude: lat,
        longitude: lon,
        fetchTime: DateTime.now(),
        freshness: DataFreshness.unavailable,
        isUsingDefaultLocation: usingDefault,
        cityName: cityName,
        dewPointC: null, // unavailable on fallback
        hourlyForecasts: const [],
      );

  // ── UTILS ──────────────────────────────────────────────────────────────────

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
