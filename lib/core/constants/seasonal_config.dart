/// seasonal_config.dart
///
/// Central configuration registry for the Seasonal State Engine.
/// All hardcoded domain thresholds live here to allow future remote-config
/// overrides without touching business logic files.
///
/// Season Boundaries (Canadian Climate Model):
///   Winter → November 1 – April 30   (months 11, 12, 1, 2, 3, 4)
///   Summer → May 1    – October 31   (months 5, 6, 7, 8, 9, 10)

// ignore_for_file: constant_identifier_names

library seasonal_config;

/// Defines the calendar boundaries and operational thresholds used by
/// the Seasonal State Engine and all downstream use-case calculators.
abstract final class SeasonalConfig {
  SeasonalConfig._(); // Non-instantiable static registry.

  // ─────────────────────────────────────────────────────────────────────────
  // SEASON MONTH BOUNDARIES
  // ─────────────────────────────────────────────────────────────────────────

  /// First calendar month of Winter mode (November).
  static const int winterStartMonth = 11;

  /// Last calendar month of Winter mode (April).
  static const int winterEndMonth = 4;

  /// First calendar month of Summer mode (May).
  static const int summerStartMonth = 5;

  /// Last calendar month of Summer mode (October).
  static const int summerEndMonth = 10;

  // ─────────────────────────────────────────────────────────────────────────
  // SNOW ACCUMULATION ENGINE — SHOVEL WINDOW THRESHOLDS
  // ─────────────────────────────────────────────────────────────────────────

  /// Minimum snow accumulation (cm) within a rolling 1-hour window required
  /// to trigger a Shovel Window alert notification.
  /// Standard Canadian municipal guideline references ~2 cm for light duty.
  /// We use 2.5 cm to avoid noise from minor dustings.
  static const double snowAccumulationThresholdCm = 2.5;

  /// Duration of the Shovel Window analysis rolling window (minutes).
  static const int shovelWindowDurationMinutes = 60;

  /// Lookahead period (hours) within which the snow peak must fall
  /// for an alert to be considered actionable.
  static const int shovelWindowLookaheadHours = 6;

  // ─────────────────────────────────────────────────────────────────────────
  // WINDROW ALERT ENGINE — CITY PLOW TIME-OFFSET HEURISTICS
  // ─────────────────────────────────────────────────────────────────────────

  /// Time offset (hours) after storm-end for a Tier 1 (large metro: Toronto,
  /// Montréal, Calgary, Ottawa) city plow to complete primary arterial clearing
  /// and produce windrows at residential driveway entrances.
  static const int windrowOffsetTier1Hours = 2;

  /// Time offset for Tier 2 cities (mid-size: Hamilton, London, Québec City,
  /// Saskatoon, Regina) — reduced fleet density increases clearance delay.
  static const int windrowOffsetTier2Hours = 4;

  /// Time offset for Tier 3 municipalities (suburban/rural) — minimal dedicated
  /// plow infrastructure; windrow drop time is highly variable.
  static const int windrowOffsetTier3Hours = 6;

  /// Minimum storm duration (hours) before windrow heuristic is applied.
  /// Short flurries rarely prompt full plow deployment.
  static const int minStormDurationForWindrowHours = 2;

  // ─────────────────────────────────────────────────────────────────────────
  // GOLDEN HOUR ENGINE — COMFORT INDEX WEIGHTS
  // ─────────────────────────────────────────────────────────────────────────

  /// Minimum Comfort Index score (0–100) required to flag a window as
  /// "Optimal Outdoor" and trigger a Golden Hour Walker notification.
  static const int goldenHourMinComfortScore = 60;

  /// How many minutes before sunset the optimal Golden Hour window opens.
  static const int goldenHourWindowBeforeSunsetMinutes = 90;

  /// Weight applied to humidity percentage in the Comfort Index formula.
  /// Higher values penalise muggy, high-humidity conditions more aggressively.
  static const double comfortHumidityWeight = 0.40;

  /// Weight applied to UV Index value in the Comfort Index formula.
  /// Scales the UV penalty linearly (e.g., UV 8 → −40 comfort points).
  static const double comfortUvWeight = 5.0;

  /// Temperature bonus applied when ambient temp is within the ideal Canadian
  /// outdoor comfort band (18 °C – 26 °C).
  static const double comfortTempBonusIdeal = 10.0;

  /// Ideal temperature band lower bound (°C).
  static const double idealTempLowerBoundC = 18.0;

  /// Ideal temperature band upper bound (°C).
  static const double idealTempUpperBoundC = 26.0;

  // ─────────────────────────────────────────────────────────────────────────
  // WEEKEND MAXIMIZER ENGINE — SCORE WEIGHTS
  // ─────────────────────────────────────────────────────────────────────────

  /// Maximum weekend activity potential score (scale used in UI display).
  static const int weekendMaxScore = 10;

  /// Weight for precipitation probability in weekend score computation (0–1).
  static const double weekendPrecipWeight = 0.35;

  /// Weight for UV index contribution (higher UV on a nice day boosts score).
  static const double weekendUvWeight = 0.20;

  /// Weight for temperature range comfort in weekend score.
  static const double weekendTempWeight = 0.30;

  /// Weight for wind speed penalty in weekend score (gusts reduce score).
  static const double weekendWindWeight = 0.15;

  /// Wind speed threshold (km/h) above which a full wind penalty is applied.
  static const double weekendHighWindThresholdKmh = 30.0;

  // ─────────────────────────────────────────────────────────────────────────
  // DATA REFRESH & CACHE
  // ─────────────────────────────────────────────────────────────────────────

  /// How long (minutes) a locally cached weather response is considered fresh
  /// before triggering a remote re-fetch on the client side.
  static const int localCacheTtlMinutes = 30;

  /// Default Canadian timezone offset used as a fallback when device locale
  /// cannot be resolved (Eastern Time, UTC−5 standard / UTC−4 daylight).
  static const String defaultTimezoneId = 'America/Toronto';
}
