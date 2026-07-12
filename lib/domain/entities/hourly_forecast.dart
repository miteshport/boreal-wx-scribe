/// hourly_forecast.dart
///
/// Domain Entity: Hourly General Weather Forecast Data Point
/// ─────────────────────────────────────────────────────────────────────────
/// Represents a single hour's complete weather metrics as consumed by
/// both Summer mode use cases:
///   - [CalculateGoldenHourWindow]: uses temperature, humidity, UV index
///   - [CalculateWeekendScore]:     uses all fields as scoring inputs
///
/// This entity is distinct from [HourlySnowForecast] by design —
/// separating winter-specific snow metrics from general weather data
/// prevents the domain model from becoming a kitchen-sink entity with
/// too many nullable fields.
///
/// Data Sources (resolved by data-layer adapters):
///   Primary:  OpenWeatherMap One Call API 3.0 (hourly.* array)
///   Fallback: Environment Canada RSS feed (reduced field set)
///
/// Unit Conventions (all adapters MUST normalise to these):
///   Temperature:   Celsius (°C)
///   Wind speed:    Kilometres per hour (km/h)
///   Precipitation: Millimetres (mm)
///   Humidity:      Percentage points (0–100, not 0.0–1.0)
///   UV Index:      WHO standard scale (0–11+, float)

library hourly_forecast;

import 'package:equatable/equatable.dart';

/// Immutable domain entity representing one hour's complete weather forecast.
///
/// Consumed by [CalculateGoldenHourWindow] and [CalculateWeekendScore].
/// Populated exclusively by the data layer repository adapters.
final class HourlyForecast extends Equatable {
  const HourlyForecast({
    required this.timestamp,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.uvIndex,
    required this.precipProbabilityPercent,
    required this.windSpeedKmh,
    this.windGustKmh = 0.0,
    this.precipitationMm = 0.0,
    this.cloudCoverPercent = 0.0,
    this.description = '',
    this.weatherCode = 0,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // REQUIRED FIELDS
  // ─────────────────────────────────────────────────────────────────────────

  /// UTC timestamp marking the START of this forecast hour.
  final DateTime timestamp;

  /// Ambient temperature in Celsius at this hour.
  /// Range: typically −50 to +45 for Canadian climate range.
  final double temperatureC;

  /// Perceived ("feels like") temperature in Celsius.
  /// Accounts for wind chill (winter) and humidex (summer).
  final double feelsLikeC;

  /// Relative humidity, in percentage points (0–100).
  final double humidity;

  /// WHO UV Index (0–11+). Values above 11 indicate extreme conditions.
  /// Note: UV is typically 0 at night — callers should handle this.
  final double uvIndex;

  /// Probability of any precipitation during this hour (0–100).
  final double precipProbabilityPercent;

  /// Wind speed at 10m elevation, in km/h.
  final double windSpeedKmh;

  // ─────────────────────────────────────────────────────────────────────────
  // OPTIONAL FIELDS (with sensible defaults)
  // ─────────────────────────────────────────────────────────────────────────

  /// Wind gust speed in km/h. 0.0 when not available.
  final double windGustKmh;

  /// Expected liquid precipitation (or liquid equivalent) in mm. 0.0 if dry.
  final double precipitationMm;

  /// Sky cloud cover in percentage (0 = clear, 100 = overcast).
  final double cloudCoverPercent;

  /// Short human-readable weather description (e.g., "Partly Cloudy").
  /// Sourced from the API; not used in calculations, only in display.
  final String description;

  /// Numeric weather condition code (OWM codes: 200–804, EC codes vary).
  /// Used by [WeatherStateIcon] to select the correct geometric SVG.
  final int weatherCode;

  // ─────────────────────────────────────────────────────────────────────────
  // DERIVED PROPERTIES
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns `true` if conditions indicate a precipitation event.
  /// Threshold: probability ≥ 30% AND precipitation > 0.1 mm.
  bool get hasPrecipitation =>
      precipProbabilityPercent >= 30.0 && precipitationMm > 0.1;

  /// Returns `true` if wind is categorised as "High Wind" by Environment
  /// Canada standards (sustained > 60 km/h or gusts > 90 km/h).
  bool get isHighWind =>
      windSpeedKmh > 60.0 || (windGustKmh > 0.0 && windGustKmh > 90.0);

  /// Returns `true` if UV Index meets the Health Canada "High" threshold.
  bool get isHighUv => uvIndex >= 8.0;

  /// Returns the end of this forecast hour (timestamp + 60 minutes).
  DateTime get hourEnd => timestamp.add(const Duration(hours: 1));

  // ─────────────────────────────────────────────────────────────────────────
  // VALUE EQUALITY
  // ─────────────────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        timestamp,
        temperatureC,
        feelsLikeC,
        humidity,
        uvIndex,
        precipProbabilityPercent,
        windSpeedKmh,
        windGustKmh,
        precipitationMm,
        cloudCoverPercent,
        description,
        weatherCode,
      ];

  @override
  String toString() =>
      'HourlyForecast(${timestamp.toIso8601String()}: '
      '${temperatureC.toStringAsFixed(1)}°C, '
      'UV=${uvIndex.toStringAsFixed(1)}, '
      'humidity=${humidity.toStringAsFixed(0)}%, '
      'wind=${windSpeedKmh.toStringAsFixed(0)}km/h)';
}
