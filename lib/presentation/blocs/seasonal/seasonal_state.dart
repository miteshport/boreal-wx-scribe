/// seasonal_state.dart
///
/// State definitions for the [SeasonalBloc].
/// ────────────────────────────────────────────
/// States represent the authoritative, computed reality of the application's
/// seasonal mode at any given moment. Unlike events, states ARE held by the
/// BLoC and emitted to the widget tree.
///
/// Design Principles:
///   1. States carry all pre-computed context widgets need. Widgets should
///      never derive season logic themselves — they receive resolved state.
///   2. [SeasonalInitial] is a transient loading state, displayed for the
///      few milliseconds between BLoC creation and first event processing.
///   3. [SeasonalWinterActive] and [SeasonalSummerActive] are the two
///      persistent operational states. All downstream UI is driven by these.
///   4. Equatable ensures [BlocBuilder] does not rebuild when re-emitting
///      the same season state (e.g., daily tick confirming no change).

library seasonal_state;

import 'package:equatable/equatable.dart';
import 'package:weather_sync_ca/core/extensions/date_extensions.dart';

/// Base class for all states emitted by [SeasonalBloc].
sealed class SeasonalState extends Equatable {
  const SeasonalState();

  /// Convenience getter: returns the active [Season] or null during
  /// the [SeasonalInitial] loading phase.
  Season? get activeSeason => null;
}

// ─────────────────────────────────────────────────────────────────────────────
// TRANSIENT STATES
// ─────────────────────────────────────────────────────────────────────────────

/// The BLoC's initial state before [SeasonalStarted] has been processed.
///
/// Widgets observing this state should render a minimal loading skeleton
/// (e.g., a pulsing [voidBlack] screen) for the brief window before the
/// first authoritative state is emitted.
///
/// Expected duration: < 16ms (single frame) under normal app startup.
final class SeasonalInitial extends SeasonalState {
  const SeasonalInitial();

  @override
  Season? get activeSeason => null;

  @override
  List<Object?> get props => [];
}

// ─────────────────────────────────────────────────────────────────────────────
// OPERATIONAL STATES
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when the current date resolves to Winter mode (November–April)
/// or when a [SeasonalOverrideSet(forcedSeason: Season.winter)] is processed.
///
/// This state authorises the widget tree to render:
///   • [WinterDashboardPage] as the home content
///   • [ShovelWindowCard] and [WindrowAlertCard]
///   • [SurvivalPlaybookPage] navigation tab
///   • Winter-mode AdMob banner placements
///
/// [resolvedAt]       — timestamp of the evaluation that produced this state.
/// [daysUntilSummer]  — pre-computed days until next Summer transition.
/// [isOverrideActive] — true when forced via developer settings; false for
///                      calendar-driven resolution.
final class SeasonalWinterActive extends SeasonalState {
  const SeasonalWinterActive({
    required this.resolvedAt,
    required this.daysUntilSummer,
    this.isOverrideActive = false,
  });

  /// The [DateTime] at which this state was evaluated and emitted.
  final DateTime resolvedAt;

  /// Number of days from [resolvedAt] until May 1 (Summer transition).
  /// Pre-computed here to avoid recalculation on each widget rebuild.
  final int daysUntilSummer;

  /// Whether this state was produced by a developer override rather than
  /// the live calendar date. Used to display a debug indicator in the UI.
  final bool isOverrideActive;

  @override
  Season get activeSeason => Season.winter;

  /// Returns `true` if the Summer transition is within 7 days.
  /// Used to surface the "Switching to Summer Mode Soon" banner.
  bool get isApproachingTransition => daysUntilSummer <= 7;

  @override
  List<Object?> get props => [
        resolvedAt,
        daysUntilSummer,
        isOverrideActive,
      ];
}

/// Emitted when the current date resolves to Summer mode (May–October)
/// or when a [SeasonalOverrideSet(forcedSeason: Season.summer)] is processed.
///
/// This state authorises the widget tree to render:
///   • [SummerDashboardPage] as the home content
///   • [GoldenHourCard] and [WeekendScoreCard]
///   • Weekend Maximizer navigation tab
///   • Summer-mode AdMob banner placements
///
/// [resolvedAt]       — timestamp of the evaluation that produced this state.
/// [daysUntilWinter]  — pre-computed days until next Winter transition.
/// [isOverrideActive] — true when forced via developer settings.
final class SeasonalSummerActive extends SeasonalState {
  const SeasonalSummerActive({
    required this.resolvedAt,
    required this.daysUntilWinter,
    this.isOverrideActive = false,
  });

  /// The [DateTime] at which this state was evaluated and emitted.
  final DateTime resolvedAt;

  /// Number of days from [resolvedAt] until November 1 (Winter transition).
  final int daysUntilWinter;

  /// Whether this state was produced by a developer override.
  final bool isOverrideActive;

  @override
  Season get activeSeason => Season.summer;

  /// Returns `true` if the Winter transition is within 7 days.
  bool get isApproachingTransition => daysUntilWinter <= 7;

  @override
  List<Object?> get props => [
        resolvedAt,
        daysUntilWinter,
        isOverrideActive,
      ];
}
