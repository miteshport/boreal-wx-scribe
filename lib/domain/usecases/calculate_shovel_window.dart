/// calculate_shovel_window.dart
///
/// Domain Use Case: Predictive Driveway Shovel Window Calculator
/// ─────────────────────────────────────────────────────────────────────────
/// Determines the optimal 1-hour window for a homeowner to clear their
/// driveway based on a lookahead hourly snowfall forecast.
///
/// ALGORITHM: Sliding Peak-Taper Window
/// ─────────────────────────────────────
/// The fundamental insight: shovelling at peak snowfall intensity wastes
/// effort — cleared snow is immediately covered again. The optimal window
/// is the 1-hour period AFTER peak accumulation rate has been observed
/// and the storm is visibly tapering, minimising total shovel cycles.
///
/// Phase 1 — THRESHOLD GATE:
///   Sum all forecast-hour accumulations over the lookahead window.
///   If total < SeasonalConfig.snowAccumulationThresholdCm (2.5 cm),
///   return null (no action required — minor dustings are noise).
///
/// Phase 2 — PEAK IDENTIFICATION:
///   Identify the "peak hour": the forecast entry with maximum
///   per-hour accumulation. This is the heart of the storm.
///
/// Phase 3 — TAPER DETECTION:
///   The optimal shovel window begins 1 hour AFTER the peak hour.
///   If the peak is the final hour of the forecast, the window IS the
///   peak hour (shovel as early as possible to avoid max depth).
///
/// Phase 4 — URGENCY CLASSIFICATION:
///   Mark result as "urgent" when peak per-hour accumulation exceeds
///   2× the base threshold (≥ 5.0 cm/hour) — heavy snowfall events
///   that require immediate response regardless of timing optimisation.
///
/// OUTPUT CONTRACT:
///   Returns [ShovelWindowResult?]. A null result means no action
///   is required (below threshold). A non-null result contains the
///   calculated window boundaries and supporting metrics for display.

library calculate_shovel_window;

import 'package:equatable/equatable.dart';
import 'package:weather_sync_ca/core/constants/seasonal_config.dart';
import 'package:weather_sync_ca/domain/entities/hourly_snow_forecast.dart';
import 'package:weather_sync_ca/domain/usecases/use_case.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PARAMS
// ─────────────────────────────────────────────────────────────────────────────

/// Input parameters for [CalculateShovelWindow].
final class CalculateShovelWindowParams extends Equatable {
  const CalculateShovelWindowParams({
    required this.forecasts,
    required this.referenceTime,
  });

  /// The hourly snowfall forecasts to analyse. Must be non-empty.
  /// Does NOT need to be pre-sorted — the use case sorts internally.
  final List<HourlySnowForecast> forecasts;

  /// The reference timestamp used to filter forecasts to the lookahead window.
  /// In production: [DateTime.now()]. In tests: any injected [DateTime].
  final DateTime referenceTime;

  @override
  List<Object?> get props => [forecasts, referenceTime];
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULT
// ─────────────────────────────────────────────────────────────────────────────

/// The output of a successful [CalculateShovelWindow] computation.
///
/// All timestamps are in UTC. Presentation layer is responsible for
/// converting to the user's local timezone.
final class ShovelWindowResult extends Equatable {
  const ShovelWindowResult({
    required this.optimalWindowStart,
    required this.optimalWindowEnd,
    required this.peakAccumulationCm,
    required this.windowAccumulationCm,
    required this.totalForecastedAccumulationCm,
    required this.peakHourTimestamp,
    required this.isUrgent,
    required this.intensityCode,
  });

  /// UTC start of the recommended 1-hour shovelling window.
  final DateTime optimalWindowStart;

  /// UTC end of the recommended 1-hour shovelling window.
  final DateTime optimalWindowEnd;

  /// Peak per-hour accumulation (cm) — the maximum single-hour snowfall
  /// in the lookahead window. Used to display storm intensity context.
  final double peakAccumulationCm;

  /// Expected accumulation during the optimal window itself (cm).
  /// Non-zero because storms taper — there will still be some snowfall
  /// during the recommended clearing window.
  final double windowAccumulationCm;

  /// Total accumulation across all analysed forecast hours (cm).
  final double totalForecastedAccumulationCm;

  /// The timestamp of the peak snowfall hour. Displayed as "storm peak"
  /// context in the [ShovelWindowCard].
  final DateTime peakHourTimestamp;

  /// `true` when peak per-hour accumulation ≥ 2× the base threshold (5.0 cm).
  /// Triggers a higher-urgency visual state in the [ShovelWindowCard].
  final bool isUrgent;

  /// The snowfall intensity classification at peak.
  final SnowfallIntensity intensityCode;

  /// Duration of the recommended window (always [SeasonalConfig.shovelWindowDurationMinutes]).
  Duration get windowDuration => optimalWindowEnd.difference(optimalWindowStart);

  @override
  List<Object?> get props => [
        optimalWindowStart,
        optimalWindowEnd,
        peakAccumulationCm,
        windowAccumulationCm,
        totalForecastedAccumulationCm,
        peakHourTimestamp,
        isUrgent,
        intensityCode,
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// USE CASE
// ─────────────────────────────────────────────────────────────────────────────

/// Synchronous pure-function use case that computes the optimal driveway
/// clearing window from a set of hourly snowfall forecasts.
///
/// Pure function guarantees:
///   - No I/O, no network calls, no database reads.
///   - Identical inputs always produce identical outputs.
///   - No mutable state. Thread-safe.
///
/// Usage:
/// ```dart
/// final calculateShovelWindow = CalculateShovelWindow();
/// final result = calculateShovelWindow(CalculateShovelWindowParams(
///   forecasts: hourlyForecasts,
///   referenceTime: DateTime.now(),
/// ));
/// if (result != null) {
///   // Display shovel window card
/// }
/// ```
final class CalculateShovelWindow
    extends SyncUseCase<ShovelWindowResult?, CalculateShovelWindowParams> {
  const CalculateShovelWindow();

  // ─── Constants ─────────────────────────────────────────────────────────

  static const double _urgencyMultiplier = 2.0;

  // ─────────────────────────────────────────────────────────────────────────
  // ENTRY POINT
  // ─────────────────────────────────────────────────────────────────────────

  @override
  ShovelWindowResult? call(CalculateShovelWindowParams params) {
    // ── Phase 0: Pre-process and sort forecasts ──────────────────────────
    // Filter to the configured lookahead window, exclude past hours,
    // then sort chronologically for the sliding window algorithm.
    final DateTime lookaheadCutoff = params.referenceTime.add(
      Duration(hours: SeasonalConfig.shovelWindowLookaheadHours),
    );

    final List<HourlySnowForecast> window = params.forecasts
        .where((f) => f.timestamp.isAfter(params.referenceTime) &&
            f.timestamp.isBefore(lookaheadCutoff))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (window.isEmpty) return null;

    // ── Phase 1: Threshold Gate ──────────────────────────────────────────
    // Sum all per-hour accumulations. If the storm won't deposit enough
    // snow to justify clearing, return null — no alert needed.
    final double totalAccumulationCm = window.fold(
      0.0,
      (sum, f) => sum + f.accumulationCm,
    );

    if (totalAccumulationCm < SeasonalConfig.snowAccumulationThresholdCm) {
      return null; // Below threshold — no action required.
    }

    // ── Phase 2: Peak Hour Identification ───────────────────────────────
    // Find the forecast hour with the highest per-hour snowfall rate.
    // This is the "eye" of the storm — the worst period of clearing.
    final HourlySnowForecast peakForecast = window.reduce(
      (a, b) => a.accumulationCm >= b.accumulationCm ? a : b,
    );
    final int peakIndex = window.indexOf(peakForecast);

    // ── Phase 3: Taper Zone Selection ───────────────────────────────────
    // The optimal window starts one hour AFTER the peak. At this point
    // the storm is tapering and clearing effort will hold longer.
    // Edge case: if the peak IS the final hour, shovel at peak onset.
    final int optimalIndex =
        (peakIndex + 1 < window.length) ? peakIndex + 1 : peakIndex;
    final HourlySnowForecast optimalForecast = window[optimalIndex];

    // Accumulation expected DURING the optimal clearing window.
    // (Typically tapering, so low — but non-zero.)
    final double windowAccumulationCm = window
        .skip(optimalIndex)
        .take(SeasonalConfig.shovelWindowDurationMinutes ~/ 60)
        .fold(0.0, (sum, f) => sum + f.accumulationCm);

    // ── Phase 4: Urgency Classification ─────────────────────────────────
    // Heavy storms (peak ≥ 2× threshold) require immediate response
    // regardless of timing optimisation. Flag them as urgent.
    final bool isUrgent = peakForecast.accumulationCm >=
        (SeasonalConfig.snowAccumulationThresholdCm * _urgencyMultiplier);

    // ── Assemble Result ──────────────────────────────────────────────────
    final DateTime windowStart = optimalForecast.timestamp;
    final DateTime windowEnd = windowStart.add(
      Duration(minutes: SeasonalConfig.shovelWindowDurationMinutes),
    );

    return ShovelWindowResult(
      optimalWindowStart: windowStart,
      optimalWindowEnd: windowEnd,
      peakAccumulationCm: peakForecast.accumulationCm,
      windowAccumulationCm: windowAccumulationCm,
      totalForecastedAccumulationCm: totalAccumulationCm,
      peakHourTimestamp: peakForecast.timestamp,
      isUrgent: isUrgent,
      intensityCode:
          SnowfallIntensity.fromAccumulationCm(peakForecast.accumulationCm),
    );
  }
}
