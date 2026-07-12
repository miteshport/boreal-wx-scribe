/// calculate_windrow_alert.dart
///
/// Domain Use Case: City Plow Windrow Drop-Time Prediction Engine
/// ─────────────────────────────────────────────────────────────────────────
/// Calculates the estimated time window during which a city plow will
/// deposit a compressed ice/snow barrier ("windrow") at the bottom of
/// residential driveways following a winter storm.
///
/// WHAT IS A WINDROW?
/// ─────────────────────
/// During a storm response, city plows clear arterial roads first, then
/// residential streets. As plows pass a driveway entrance, they push a
/// compacted block of road ice and hard-packed snow across the driveway
/// opening. This "windrow" arrives AFTER the homeowner has already cleared
/// their driveway — a secondary clearing event that catches newcomers
/// completely off guard. For established Canadian homeowners, anticipating
/// this is a well-known but underdocumented skill.
///
/// ALGORITHM: Time-Offset Heuristic Model
/// ──────────────────────────────────────────────────────────────────────
/// Input:  Storm end timestamp + municipality tier + storm duration
/// Logic:  estimatedDropTime = stormEnd + offsetHours[tier]
/// Output: WindrowAlertResult with estimated drop time + warning window
///
/// The time offsets are empirical heuristics calibrated against real
/// Canadian municipal snow clearance operational data patterns:
///
///   METRO  (T1): 2 h — Large fleets; arterials clear fast, residentials ~2h.
///   SUBURB (T2): 4 h — Mixed fleet; residential pass takes ~4h post-storm.
///   RURAL  (T3): 6 h — Minimal fleet; county roads prioritised; 6h+ typical.
///
/// ALERT WINDOW:
///   The "danger zone" is a ±1 hour window around the estimated drop time.
///   The alert is escalated 30 minutes before the window opens.
///
/// MINIMUM STORM THRESHOLD:
///   Storms shorter than [SeasonalConfig.minStormDurationForWindrowHours]
///   rarely trigger a full plow deployment. A [WindrowAlertResult.noAlert]
///   is returned in these cases with an explanatory reason string.

library calculate_windrow_alert;

import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:weather_sync_ca/core/constants/seasonal_config.dart';
import 'package:weather_sync_ca/domain/entities/municipality_tier.dart';
import 'package:weather_sync_ca/domain/usecases/use_case.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PARAMS
// ─────────────────────────────────────────────────────────────────────────────

/// Input parameters for [CalculateWindrowAlert].
final class CalculateWindrowAlertParams extends Equatable {
  const CalculateWindrowAlertParams({
    required this.stormEndTime,
    required this.tier,
    required this.stormDurationHours,
    this.stormPeakAccumulationCm = 0.0,
  });

  /// The estimated UTC timestamp when the storm is forecast to end.
  /// Provided by the data layer from the OWM or EC precipitation timeline.
  final DateTime stormEndTime;

  /// The user's configured municipality tier, determining plow offset.
  final MunicipalityTier tier;

  /// Total duration of the storm event in hours.
  /// Used to gate the heuristic: short flurries don't trigger full plowing.
  final int stormDurationHours;

  /// Optional: peak hourly accumulation for context in the warning message.
  final double stormPeakAccumulationCm;

  @override
  List<Object?> get props => [
        stormEndTime,
        tier,
        stormDurationHours,
        stormPeakAccumulationCm,
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULT
// ─────────────────────────────────────────────────────────────────────────────

/// Output of the [CalculateWindrowAlert] use case.
///
/// Check [isActive] before accessing timing fields. If [isActive] is false,
/// read [suppressionReason] for the explanatory message to display in the UI.
final class WindrowAlertResult extends Equatable {
  const WindrowAlertResult({
    required this.isActive,
    required this.estimatedDropTime,
    required this.alertWindowStart,
    required this.alertWindowEnd,
    required this.escalationTime,
    required this.offsetHours,
    required this.tier,
    required this.primaryWarningMessage,
    required this.secondaryDetailMessage,
    this.suppressionReason,
  });

  /// Named constructor for a suppressed (no-alert) result.
  factory WindrowAlertResult.noAlert({required String reason}) {
    return WindrowAlertResult(
      isActive: false,
      estimatedDropTime: DateTime.utc(0),
      alertWindowStart: DateTime.utc(0),
      alertWindowEnd: DateTime.utc(0),
      escalationTime: DateTime.utc(0),
      offsetHours: 0,
      tier: MunicipalityTier.suburb,
      primaryWarningMessage: '',
      secondaryDetailMessage: '',
      suppressionReason: reason,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  /// `true` when a real windrow event is expected and the alert is valid.
  final bool isActive;

  /// Estimated UTC time the plow will deposit the windrow.
  final DateTime estimatedDropTime;

  /// Start of the ±1h "danger window" around [estimatedDropTime].
  final DateTime alertWindowStart;

  /// End of the ±1h "danger window" around [estimatedDropTime].
  final DateTime alertWindowEnd;

  /// Time to push the advance FCM notification (30 min before [alertWindowStart]).
  final DateTime escalationTime;

  /// Number of hours offset from storm end used in this calculation.
  final int offsetHours;

  /// The user's municipality tier that determined [offsetHours].
  final MunicipalityTier tier;

  /// Short primary warning displayed in the [WindrowAlertCard] header.
  final String primaryWarningMessage;

  /// Detailed secondary text describing the expected impact.
  final String secondaryDetailMessage;

  /// Non-null only when [isActive] is false. Explains why no alert was raised.
  final String? suppressionReason;

  @override
  List<Object?> get props => [
        isActive,
        estimatedDropTime,
        alertWindowStart,
        alertWindowEnd,
        escalationTime,
        offsetHours,
        tier,
        primaryWarningMessage,
        secondaryDetailMessage,
        suppressionReason,
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// USE CASE
// ─────────────────────────────────────────────────────────────────────────────

/// Synchronous pure-function use case computing the windrow drop-time window.
///
/// Usage:
/// ```dart
/// final calculateWindrowAlert = CalculateWindrowAlert();
/// final result = calculateWindrowAlert(CalculateWindrowAlertParams(
///   stormEndTime: storm.endTime,
///   tier: userSettings.municipalityTier,
///   stormDurationHours: storm.durationHours,
/// ));
/// if (result.isActive) {
///   // Show WindrowAlertCard with result.estimatedDropTime
/// }
/// ```
final class CalculateWindrowAlert
    extends SyncUseCase<WindrowAlertResult, CalculateWindrowAlertParams> {
  const CalculateWindrowAlert();

  // ─── Constants ─────────────────────────────────────────────────────────
  static const int _alertWindowRadiusHours = 1;
  static const int _escalationLeadMinutes = 30;

  // ─────────────────────────────────────────────────────────────────────────
  // ENTRY POINT
  // ─────────────────────────────────────────────────────────────────────────

  @override
  WindrowAlertResult call(CalculateWindrowAlertParams params) {
    // ── Gate: Minimum storm duration check ───────────────────────────────
    // Brief flurries (< configured minimum) rarely trigger full municipal
    // plow deployment. Suppress the alert with an explanatory reason.
    if (params.stormDurationHours <
        SeasonalConfig.minStormDurationForWindrowHours) {
      return WindrowAlertResult.noAlert(
        reason: 'Storm duration (${params.stormDurationHours}h) '
            'below minimum threshold for plow deployment '
            '(${SeasonalConfig.minStormDurationForWindrowHours}h required).',
      );
    }

    // ── Compute tier-specific offset ─────────────────────────────────────
    final int offsetHours = _offsetForTier(params.tier);

    // ── Compute timing boundaries ────────────────────────────────────────
    final DateTime estimatedDropTime =
        params.stormEndTime.add(Duration(hours: offsetHours));

    final DateTime alertWindowStart = estimatedDropTime
        .subtract(Duration(hours: _alertWindowRadiusHours));
    final DateTime alertWindowEnd = estimatedDropTime
        .add(Duration(hours: _alertWindowRadiusHours));

    // The FCM notification fires this many minutes before the window opens.
    final DateTime escalationTime = alertWindowStart
        .subtract(const Duration(minutes: _escalationLeadMinutes));

    // ── Build warning messages ───────────────────────────────────────────
    final String primary = _buildPrimaryMessage(estimatedDropTime, params.tier);
    final String secondary =
        _buildSecondaryMessage(params, offsetHours, alertWindowStart, alertWindowEnd);

    return WindrowAlertResult(
      isActive: true,
      estimatedDropTime: estimatedDropTime,
      alertWindowStart: alertWindowStart,
      alertWindowEnd: alertWindowEnd,
      escalationTime: escalationTime,
      offsetHours: offsetHours,
      tier: params.tier,
      primaryWarningMessage: primary,
      secondaryDetailMessage: secondary,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Resolves the plow time offset (hours) for the given [MunicipalityTier].
  int _offsetForTier(MunicipalityTier tier) => switch (tier) {
        MunicipalityTier.metro => SeasonalConfig.windrowOffsetTier1Hours,
        MunicipalityTier.suburb => SeasonalConfig.windrowOffsetTier2Hours,
        MunicipalityTier.rural => SeasonalConfig.windrowOffsetTier3Hours,
      };

  /// Constructs the short primary warning displayed in the card header.
  String _buildPrimaryMessage(DateTime dropTime, MunicipalityTier tier) {
    final String timeStr = DateFormat('h:mm a').format(dropTime.toLocal());
    return switch (tier) {
      MunicipalityTier.metro =>
        'City plow expected to block your driveway around $timeStr.',
      MunicipalityTier.suburb =>
        'Municipal plow windrow estimated near $timeStr.',
      MunicipalityTier.rural =>
        'County road plow may block entrance near $timeStr.',
    };
  }

  /// Constructs the detailed secondary description for the card body.
  String _buildSecondaryMessage(
    CalculateWindrowAlertParams params,
    int offsetHours,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final String startStr = DateFormat('h:mm a').format(windowStart.toLocal());
    final String endStr = DateFormat('h:mm a').format(windowEnd.toLocal());
    final String tierName = params.tier.displayName;

    final StringBuffer sb = StringBuffer()
      ..write('Based on $tierName plow patterns ($offsetHours h post-storm), ')
      ..write('a road-cleared ice barrier is expected between ')
      ..write('$startStr – $endStr. ')
      ..write('Keep the shovel ready after your initial clear. ');

    if (params.stormPeakAccumulationCm >= 10.0) {
      sb.write('Heavy accumulation (${params.stormPeakAccumulationCm.toStringAsFixed(1)} cm peak) '
          'may produce a particularly large windrow.');
    }

    return sb.toString();
  }
}
