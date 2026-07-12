/// hourly_snow_forecast.dart
///
/// Domain Entity: Hourly Snow Accumulation Forecast Data Point
/// ─────────────────────────────────────────────────────────────────────────
/// Represents a single hour's expected snowfall metrics as consumed by the
/// [CalculateShovelWindow] use case. This entity is populated by the data
/// layer from either the OpenWeatherMap hourly forecast API response or
/// an Environment Canada RSS XML parse result.
///
/// Immutability Guarantee:
///   All fields are final. Instances are created via const constructor
///   and compared by value through [Equatable]. No mutation methods exist.
///
/// Unit Convention:
///   All accumulation values are expressed in centimetres (cm).
///   OpenWeatherMap returns precipitation in mm — the data layer adapter
///   is responsible for the mm → cm division before constructing this entity.

library hourly_snow_forecast;

import 'package:equatable/equatable.dart';

/// Immutable domain entity representing one hour's snowfall forecast.
///
/// Constructed exclusively by the data layer repository adapters and
/// consumed exclusively by [CalculateShovelWindow]. No widget should
/// ever instantiate this class directly.
final class HourlySnowForecast extends Equatable {
  const HourlySnowForecast({
    required this.timestamp,
    required this.accumulationCm,
    required this.precipProbabilityPercent,
    this.snowDepthOnGroundCm = 0.0,
    this.snowfallIntensityCode = SnowfallIntensity.light,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FIELDS
  // ─────────────────────────────────────────────────────────────────────────

  /// The UTC timestamp marking the START of this forecast hour.
  /// Always stored in UTC; convert to local time at the presentation layer.
  final DateTime timestamp;

  /// Expected new snowfall accumulation DURING this specific hour, in cm.
  ///
  /// This is a per-hour delta, NOT a running total. The [CalculateShovelWindow]
  /// use case aggregates deltas across windows internally.
  ///
  /// Invariant: must be >= 0.0. Negative values indicate a data error
  /// in the upstream API response and should be coerced to 0.0 in the adapter.
  final double accumulationCm;

  /// Probability that precipitation (as snow) will fall during this hour.
  /// Range: 0.0 (certain no snow) – 100.0 (certain snowfall).
  final double precipProbabilityPercent;

  /// Total snow depth on the ground at the START of this hour (cm).
  /// Derived from Environment Canada snowpack data where available.
  /// Defaults to 0.0 when unavailable (OpenWeatherMap does not provide this).
  final double snowDepthOnGroundCm;

  /// Qualitative snowfall intensity classification for display purposes.
  final SnowfallIntensity snowfallIntensityCode;

  // ─────────────────────────────────────────────────────────────────────────
  // DERIVED PROPERTIES
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns `true` if accumulation meets or exceeds the standard forecast
  /// significance threshold (≥ 0.2 cm — trace amounts excluded).
  bool get isSignificant => accumulationCm >= 0.2;

  /// Returns the end of this forecast hour (timestamp + 60 minutes).
  DateTime get hourEnd => timestamp.add(const Duration(hours: 1));

  // ─────────────────────────────────────────────────────────────────────────
  // VALUE EQUALITY
  // ─────────────────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        timestamp,
        accumulationCm,
        precipProbabilityPercent,
        snowDepthOnGroundCm,
        snowfallIntensityCode,
      ];

  @override
  String toString() =>
      'HourlySnowForecast(${timestamp.toIso8601String()}: '
      '${accumulationCm.toStringAsFixed(1)}cm, '
      'prob=${precipProbabilityPercent.toStringAsFixed(0)}%)';
}

// ─────────────────────────────────────────────────────────────────────────────
// SUPPORTING ENUM
// ─────────────────────────────────────────────────────────────────────────────

/// Qualitative snowfall intensity classification.
/// Thresholds align with Environment Canada's public terminology.
enum SnowfallIntensity {
  /// Trace to 0.5 cm/hour.
  trace,

  /// 0.5 – 2.0 cm/hour.
  light,

  /// 2.0 – 5.0 cm/hour.
  moderate,

  /// > 5.0 cm/hour. Blizzard-adjacent conditions.
  heavy;

  /// Resolves intensity from a per-hour accumulation value (cm).
  static SnowfallIntensity fromAccumulationCm(double cm) {
    if (cm < 0.2) return SnowfallIntensity.trace;
    if (cm < 2.0) return SnowfallIntensity.light;
    if (cm < 5.0) return SnowfallIntensity.moderate;
    return SnowfallIntensity.heavy;
  }

  String get displayLabel => switch (this) {
        SnowfallIntensity.trace => 'Trace',
        SnowfallIntensity.light => 'Light',
        SnowfallIntensity.moderate => 'Moderate',
        SnowfallIntensity.heavy => 'Heavy',
      };
}
