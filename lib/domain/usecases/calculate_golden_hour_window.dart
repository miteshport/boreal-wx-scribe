/// calculate_golden_hour_window.dart
///
/// Domain Use Case: Summer Golden Hour Optimal Outdoor Window Calculator
/// ─────────────────────────────────────────────────────────────────────────
/// Determines whether conditions are optimal for outdoor activity in the
/// 90-minute window preceding sunset and returns a precise time window
/// alongside a computed Comfort Index score (0–100).
///
/// COMFORT INDEX MODEL
/// ────────────────────────────────────────────────────────────────────────
/// The Comfort Index is a composite score that quantifies how pleasant
/// outdoor conditions are for evening activity, tuned specifically for
/// the Canadian summer climate experience.
///
/// Formula:
///   baseScore = 100
///   - (humidity × comfortHumidityWeight)       // Humidity penalty  (max −40)
///   - (uvIndex × comfortUvWeight)              // UV penalty        (max −55)
///   + temperatureBonus                         // Temp bonus        (max +10)
///   → clamped to [0, 100]
///
/// Component Weights (from SeasonalConfig):
///   comfortHumidityWeight = 0.40  → At 100% humidity: −40 points
///   comfortUvWeight       = 5.0   → At UV 11:         −55 points
///   comfortTempBonusIdeal = 10.0  → When 18°C ≤ T ≤ 26°C: +10 points
///
/// Temperature Bonus Logic:
///   Ideal band (18–26°C):        +10.0 full bonus
///   Near-ideal bands:
///     15–18°C or 26–30°C:        +5.0 partial bonus (slightly cool/warm)
///     10–15°C or 30–35°C:        +2.0 marginal bonus
///     < 10°C or > 35°C:          0.0  no bonus (uncomfortable extremes)
///
/// GOLDEN HOUR WINDOW DEFINITION:
///   If ComfortIndex ≥ SeasonalConfig.goldenHourMinComfortScore (60):
///     windowStart = sunsetTime − 90 minutes
///     windowEnd   = sunsetTime + 30 minutes
///   Otherwise: no optimal window (below threshold result returned).
///
/// QUALITY TIERS:
///   90–100: Perfect       — Ideal evening conditions.
///   75–89:  Optimal       — Excellent, go out.
///   60–74:  Good          — Worth it; bring sunscreen or light layer.
///   40–59:  Fair          — Below threshold; conditions are marginal.
///   0–39:   Poor          — Stay in; heat, humidity, or UV too high.

library calculate_golden_hour_window;

import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:weather_sync_ca/core/constants/seasonal_config.dart';
import 'package:weather_sync_ca/domain/usecases/use_case.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PARAMS
// ─────────────────────────────────────────────────────────────────────────────

/// Input parameters for [CalculateGoldenHourWindow].
///
/// All values represent conditions at or near the projected sunset window.
/// Callers should pass values from the forecast hour closest to
/// [sunsetTime] − 90 minutes, not current real-time readings.
final class CalculateGoldenHourParams extends Equatable {
  const CalculateGoldenHourParams({
    required this.sunsetTime,
    required this.temperatureC,
    required this.humidity,
    required this.uvIndex,
    this.windSpeedKmh = 0.0,
  });

  /// UTC timestamp of today's astronomical sunset.
  final DateTime sunsetTime;

  /// Ambient temperature at the golden hour window (°C).
  final double temperatureC;

  /// Relative humidity at the golden hour window (0–100 percentage points).
  final double humidity;

  /// UV Index at the golden hour window (0–11+).
  /// Note: UV naturally drops in the final hour before sunset.
  final double uvIndex;

  /// Wind speed in km/h at the golden hour window. Optional scoring factor.
  final double windSpeedKmh;

  @override
  List<Object?> get props => [
        sunsetTime,
        temperatureC,
        humidity,
        uvIndex,
        windSpeedKmh,
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULT
// ─────────────────────────────────────────────────────────────────────────────

/// Output of [CalculateGoldenHourWindow].
///
/// Check [isAboveThreshold] to determine if an optimal window exists.
/// When false, [windowStart]/[windowEnd] are meaningless — use
/// [comfortIndex] and [qualityTier] to explain conditions to the user.
final class GoldenHourResult extends Equatable {
  const GoldenHourResult({
    required this.comfortIndex,
    required this.qualityTier,
    required this.sunsetTime,
    required this.isAboveThreshold,
    required this.windowStart,
    required this.windowEnd,
    required this.humidityPenalty,
    required this.uvPenalty,
    required this.temperatureBonus,
    required this.notificationMessage,
  });

  /// Named constructor for a below-threshold (no optimal window) result.
  factory GoldenHourResult.belowThreshold({
    required int comfortIndex,
    required DateTime sunset,
    required GoldenHourQualityTier qualityTier,
    required double humidityPenalty,
    required double uvPenalty,
    required double temperatureBonus,
  }) {
    return GoldenHourResult(
      comfortIndex: comfortIndex,
      qualityTier: qualityTier,
      sunsetTime: sunset,
      isAboveThreshold: false,
      windowStart: DateTime.utc(0),
      windowEnd: DateTime.utc(0),
      humidityPenalty: humidityPenalty,
      uvPenalty: uvPenalty,
      temperatureBonus: temperatureBonus,
      notificationMessage: _buildBelowThresholdMessage(comfortIndex, qualityTier),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  /// Computed Comfort Index (0–100).
  final int comfortIndex;

  /// Qualitative tier classification for UI display.
  final GoldenHourQualityTier qualityTier;

  /// UTC sunset time used in this calculation.
  final DateTime sunsetTime;

  /// `true` when [comfortIndex] ≥ [SeasonalConfig.goldenHourMinComfortScore].
  final bool isAboveThreshold;

  /// UTC start of the recommended outdoor window.
  /// Valid only when [isAboveThreshold] is true.
  final DateTime windowStart;

  /// UTC end of the recommended outdoor window.
  /// Valid only when [isAboveThreshold] is true.
  final DateTime windowEnd;

  // Decomposed score components (displayed in expanded card detail view).
  final double humidityPenalty;
  final double uvPenalty;
  final double temperatureBonus;

  /// Pre-built FCM/in-app notification message for this result.
  final String notificationMessage;

  /// Window duration (always 120 minutes when [isAboveThreshold] is true:
  /// 90 min before sunset + 30 min golden post-sunset window).
  Duration get windowDuration =>
      isAboveThreshold ? windowEnd.difference(windowStart) : Duration.zero;

  static String _buildBelowThresholdMessage(
      int ci, GoldenHourQualityTier tier) {
    return switch (tier) {
      GoldenHourQualityTier.fair =>
        'Conditions are marginal this evening (CI: $ci). '
            'Consider an indoor alternative.',
      GoldenHourQualityTier.poor =>
        'Outdoor conditions are uncomfortable this evening (CI: $ci). '
            'High humidity or UV makes it inadvisable.',
      _ => 'No optimal outdoor window tonight (CI: $ci).',
    };
  }

  @override
  List<Object?> get props => [
        comfortIndex,
        qualityTier,
        sunsetTime,
        isAboveThreshold,
        windowStart,
        windowEnd,
        humidityPenalty,
        uvPenalty,
        temperatureBonus,
        notificationMessage,
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// QUALITY TIER ENUM
// ─────────────────────────────────────────────────────────────────────────────

/// Qualitative Comfort Index classification tiers.
enum GoldenHourQualityTier {
  /// CI 90–100. Ideal evening conditions. Rare in humid Canadian summer.
  perfect,

  /// CI 75–89. Excellent. Most users' ideal evening activity window.
  optimal,

  /// CI 60–74. Good. Worth going out; minor caveats apply.
  good,

  /// CI 40–59. Marginal. Below threshold; conditions are uncomfortable.
  fair,

  /// CI 0–39. Poor. High heat, humidity, or UV; stay indoors.
  poor;

  /// Resolves the quality tier from a raw Comfort Index (0–100).
  static GoldenHourQualityTier fromComfortIndex(int ci) {
    if (ci >= 90) return GoldenHourQualityTier.perfect;
    if (ci >= 75) return GoldenHourQualityTier.optimal;
    if (ci >= 60) return GoldenHourQualityTier.good;
    if (ci >= 40) return GoldenHourQualityTier.fair;
    return GoldenHourQualityTier.poor;
  }

  String get displayLabel => switch (this) {
        GoldenHourQualityTier.perfect => 'PERFECT',
        GoldenHourQualityTier.optimal => 'OPTIMAL',
        GoldenHourQualityTier.good => 'GOOD',
        GoldenHourQualityTier.fair => 'FAIR',
        GoldenHourQualityTier.poor => 'POOR',
      };

  bool get isActionable => this == perfect || this == optimal || this == good;
}

// ─────────────────────────────────────────────────────────────────────────────
// USE CASE
// ─────────────────────────────────────────────────────────────────────────────

/// Synchronous pure-function use case computing the evening outdoor
/// comfort window and Comfort Index score.
///
/// Usage:
/// ```dart
/// final calculateGoldenHour = CalculateGoldenHourWindow();
/// final result = calculateGoldenHour(CalculateGoldenHourParams(
///   sunsetTime: todaySunset,
///   temperatureC: 22.0,
///   humidity: 55.0,
///   uvIndex: 3.0,
/// ));
/// if (result.isAboveThreshold) {
///   // Notify user: result.windowStart → result.windowEnd
/// }
/// ```
final class CalculateGoldenHourWindow
    extends SyncUseCase<GoldenHourResult, CalculateGoldenHourParams> {
  const CalculateGoldenHourWindow();

  // ─────────────────────────────────────────────────────────────────────────
  // ENTRY POINT
  // ─────────────────────────────────────────────────────────────────────────

  @override
  GoldenHourResult call(CalculateGoldenHourParams params) {
    // ── Step 1: Compute penalty components ──────────────────────────────
    final double humidityPenalty =
        (params.humidity * SeasonalConfig.comfortHumidityWeight)
            .clamp(0.0, 40.0);

    final double uvPenalty =
        (params.uvIndex * SeasonalConfig.comfortUvWeight)
            .clamp(0.0, 60.0);

    final double temperatureBonus = _computeTemperatureBonus(params.temperatureC);

    // ── Step 2: Assemble Comfort Index ───────────────────────────────────
    final int comfortIndex =
        (100.0 - humidityPenalty - uvPenalty + temperatureBonus)
            .round()
            .clamp(0, 100);

    final GoldenHourQualityTier tier =
        GoldenHourQualityTier.fromComfortIndex(comfortIndex);

    // ── Step 3: Threshold gate ───────────────────────────────────────────
    if (comfortIndex < SeasonalConfig.goldenHourMinComfortScore) {
      return GoldenHourResult.belowThreshold(
        comfortIndex: comfortIndex,
        sunset: params.sunsetTime,
        qualityTier: tier,
        humidityPenalty: humidityPenalty,
        uvPenalty: uvPenalty,
        temperatureBonus: temperatureBonus,
      );
    }

    // ── Step 4: Compute optimal window ───────────────────────────────────
    final DateTime windowStart = params.sunsetTime.subtract(
      Duration(
        minutes: SeasonalConfig.goldenHourWindowBeforeSunsetMinutes,
      ),
    );

    // Window closes 30 minutes after sunset (post-golden-hour dusk window).
    final DateTime windowEnd =
        params.sunsetTime.add(const Duration(minutes: 30));

    // ── Step 5: Build notification message ───────────────────────────────
    final String notification =
        _buildNotificationMessage(params, comfortIndex, tier, windowStart, windowEnd);

    return GoldenHourResult(
      comfortIndex: comfortIndex,
      qualityTier: tier,
      sunsetTime: params.sunsetTime,
      isAboveThreshold: true,
      windowStart: windowStart,
      windowEnd: windowEnd,
      humidityPenalty: humidityPenalty,
      uvPenalty: uvPenalty,
      temperatureBonus: temperatureBonus,
      notificationMessage: notification,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the temperature comfort bonus using a stepped proximity model.
  ///
  /// Full bonus applies only within the ideal Canadian summer comfort band
  /// (18–26°C). Partial bonuses apply for near-ideal ranges.
  double _computeTemperatureBonus(double tempC) {
    // Ideal band: full bonus.
    if (tempC >= SeasonalConfig.idealTempLowerBoundC &&
        tempC <= SeasonalConfig.idealTempUpperBoundC) {
      return SeasonalConfig.comfortTempBonusIdeal; // +10.0
    }

    // Slightly cool (15–18°C) or slightly warm (26–30°C): partial bonus.
    if ((tempC >= 15.0 && tempC < SeasonalConfig.idealTempLowerBoundC) ||
        (tempC > SeasonalConfig.idealTempUpperBoundC && tempC <= 30.0)) {
      return SeasonalConfig.comfortTempBonusIdeal * 0.5; // +5.0
    }

    // Marginal bands (10–15°C or 30–35°C): minimal bonus.
    if ((tempC >= 10.0 && tempC < 15.0) ||
        (tempC > 30.0 && tempC <= 35.0)) {
      return SeasonalConfig.comfortTempBonusIdeal * 0.2; // +2.0
    }

    // Extreme cold (< 10°C) or extreme heat (> 35°C): no bonus.
    return 0.0;
  }

  /// Constructs the FCM push and in-app notification body.
  String _buildNotificationMessage(
    CalculateGoldenHourParams params,
    int ci,
    GoldenHourQualityTier tier,
    DateTime start,
    DateTime end,
  ) {
    final String startStr = DateFormat('h:mm a').format(start.toLocal());
    final String endStr = DateFormat('h:mm a').format(end.toLocal());
    final String tempStr =
        '${params.temperatureC.toStringAsFixed(0)}°C';

    return switch (tier) {
      GoldenHourQualityTier.perfect =>
        '🌅 Perfect evening! $tempStr, CI $ci/100. '
            'Ideal outdoor window: $startStr – $endStr.',
      GoldenHourQualityTier.optimal =>
        '🌤 Excellent conditions this evening ($tempStr, CI $ci/100). '
            'Get outside: $startStr – $endStr.',
      GoldenHourQualityTier.good =>
        'Good evening window: $startStr – $endStr. '
            '$tempStr, comfort index $ci/100.',
      _ => 'Evening outdoor window: $startStr – $endStr (CI: $ci/100).',
    };
  }
}
