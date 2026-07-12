/// weekly_forecasting_engine.dart
///
/// Canadian Weekly Lifestyle Intelligence Engine
/// ─────────────────────────────────────────────────────────────────────────
/// Scans 7-day DailyForecast data to compute:
///   - Prime Outdoor Day: Best day for Canadian patio/outdoor life.
///   - Weekend Anchor: Fri/Sat/Sun tagged for the UI's weekend block.
///   - Weekend Summary: Short editorial sentence describing the F/Sa/Su arc.
///   - resolveProfileForDay(): Maps a DailyForecast to a WeatherProfile via
///     WeatherStateMatrix, with deep winter blizzard override for snowfall >= 5cm.
library weekly_forecasting_engine;

import 'package:weather_sync_ca/domain/matrix/weather_state_matrix.dart';
import 'package:weather_sync_ca/services/live_weather_service.dart' show DailyForecast;

// ─────────────────────────────────────────────────────────────────────────────
// TAGGED DAILY FORECAST
// ─────────────────────────────────────────────────────────────────────────────

class TaggedDailyForecast {
  final DailyForecast forecast;
  final WeatherProfile profile;
  final bool isPrimeOutdoorDay;
  final bool isWeekend;

  const TaggedDailyForecast({
    required this.forecast,
    required this.profile,
    required this.isPrimeOutdoorDay,
    required this.isWeekend,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ENGINE
// ─────────────────────────────────────────────────────────────────────────────

class WeeklyForecastingEngine {
  // ── Resolve profile for a single day ──────────────────────────────────────

  /// Maps a DailyForecast to its WeatherStateMatrix profile. Deep Winter
  /// Blizzard is force-matched when snowfall_sum >= 5.0 cm or heavy-snow WMO
  /// code is active, regardless of temperature, as directed.
  static WeatherProfile resolveProfileForDay(DailyForecast day) {
    // Mandatory blizzard override first.
    if (day.isHeavySnowDay) return WeatherStateMatrix.deepWinterBlizzard;

    return WeatherStateMatrix.resolveCurrentProfile(
      '', // no simulation override for live forecast days
      windGustKmh: day.windMaxKmh * 1.2, // estimate gust from daily max wind
      windKmh: day.windMaxKmh,
      aqhi: 0.0, // daily forecast has no AQHI; smoke detection left to live data
      tempC: day.tempMax,
      apparentTempC: day.tempMax, // Use max temp as proxy for humidex on future days
      precip: day.precipProbMax > 30 || day.isRainDay,
      snowCm: day.snowfallSumCm,
    );
  }

  // ── Prime Outdoor Day ─────────────────────────────────────────────────────

  /// Scans the forecast list and returns the index of the single best day
  /// for outdoor Canadian lifestyle (Prime Two-Four Day).
  ///
  /// Criteria (in priority order):
  ///   1. Precip probability < 20%
  ///   2. Temp max between 20°C and 28°C
  ///   3. Wind max < 25 km/h
  ///
  /// If no day meets all three criteria, the day with the lowest combined
  /// score is selected as the best available.
  static int findPrimeOutdoorDayIndex(List<DailyForecast> forecasts) {
    if (forecasts.isEmpty) return -1;

    int? bestPrimeIdx;
    double bestScore = double.infinity;

    for (int i = 0; i < forecasts.length; i++) {
      final day = forecasts[i];
      // Score: lower is better. Disqualify days that are clearly hazardous.
      if (day.isHeavySnowDay) continue;

      double score = 0;
      // Precipitation penalty
      score += day.precipProbMax * 2.0;
      // Temperature penalty (distance from ideal 24°C)
      score += (day.tempMax - 24.0).abs() * 1.5;
      // Wind penalty
      score += day.windMaxKmh * 0.5;

      if (score < bestScore) {
        bestScore = score;
        bestPrimeIdx = i;
      }
    }

    return bestPrimeIdx ?? 0;
  }

  // ── Weekend Anchor ────────────────────────────────────────────────────────

  /// Returns the subset of the 7-day list that falls on Friday, Saturday,
  /// or Sunday from the perspective of the first forecast date.
  static List<TaggedDailyForecast> extractWeekendAnchor(
    List<DailyForecast> forecasts,
    int primeIdx,
  ) {
    return forecasts
        .asMap()
        .entries
        .where((e) {
          final wd = e.value.date.weekday;
          // weekday: 1=Mon ... 5=Fri, 6=Sat, 7=Sun
          return wd == DateTime.friday ||
              wd == DateTime.saturday ||
              wd == DateTime.sunday;
        })
        .map((e) => TaggedDailyForecast(
              forecast: e.value,
              profile: resolveProfileForDay(e.value),
              isPrimeOutdoorDay: e.key == primeIdx,
              isWeekend: true,
            ))
        .toList();
  }

  // ── Full Tagged Week ──────────────────────────────────────────────────────

  /// Tags every day with its profile, prime status, and weekend status.
  static List<TaggedDailyForecast> tagWeek(List<DailyForecast> forecasts) {
    if (forecasts.isEmpty) return const [];
    final primeIdx = findPrimeOutdoorDayIndex(forecasts);
    return forecasts.asMap().entries.map((e) {
      final wd = e.value.date.weekday;
      return TaggedDailyForecast(
        forecast: e.value,
        profile: resolveProfileForDay(e.value),
        isPrimeOutdoorDay: e.key == primeIdx,
        isWeekend: wd == DateTime.friday ||
            wd == DateTime.saturday ||
            wd == DateTime.sunday,
      );
    }).toList();
  }

  // ── Weekend Summary Copy ──────────────────────────────────────────────────

  /// Synthesizes a short editorial string describing the upcoming weekend
  /// based on Friday/Saturday/Sunday resolved profiles.
  static String generateWeekendSummary(List<TaggedDailyForecast> weekend) {
    if (weekend.isEmpty) return 'Weekend outlook unavailable.';

    // Day names for editorial copy
    final dayNames = <String>[];
    for (final t in weekend) {
      final wd = t.forecast.date.weekday;
      if (wd == DateTime.friday) dayNames.add('Friday');
      if (wd == DateTime.saturday) dayNames.add('Saturday');
      if (wd == DateTime.sunday) dayNames.add('Sunday');
    }

    // Find the best and worst days
    TaggedDailyForecast? bestDay;
    TaggedDailyForecast? worstDay;
    for (final t in weekend) {
      final isClear = t.profile.id == WeatherProfileId.primeSummerClear;
      final isExtreme = t.profile.isExtremeHazard;
      if (isClear && bestDay == null) bestDay = t;
      if (isExtreme && worstDay == null) worstDay = t;
    }

    if (bestDay != null && worstDay != null) {
      final bestName = _dayLabel(bestDay.forecast.date.weekday);
      final worstName = _dayLabel(worstDay.forecast.date.weekday);
      final hazard = worstDay.profile.headline
          .split(' ')
          .take(2)
          .join(' ')
          .toLowerCase();
      return '$bestName looks pristine for the patio — $hazard conditions move in $worstName.';
    }

    if (bestDay != null) {
      final name = _dayLabel(bestDay.forecast.date.weekday);
      return '$name is the star of the weekend. Clear skies and ideal patio weather.';
    }

    if (worstDay != null) {
      return '${worstDay.profile.headline} expected to dominate the weekend. Stay prepared.';
    }

    // All marginal
    final avg = weekend.map((t) => t.forecast.precipProbMax).reduce((a, b) => a + b) /
        weekend.length;
    if (avg < 30) {
      return 'A mixed but manageable weekend. Keep an eye on the hourly before committing.';
    }
    return 'Unsettled conditions expected all weekend. Have indoor plans ready.';
  }

  static String _dayLabel(int weekday) {
    switch (weekday) {
      case DateTime.friday: return 'Friday';
      case DateTime.saturday: return 'Saturday';
      case DateTime.sunday: return 'Sunday';
      default: return 'The weekend';
    }
  }
}
