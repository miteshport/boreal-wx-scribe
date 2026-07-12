/// seasonal_event.dart
///
/// Event definitions for the [SeasonalBloc].
/// ────────────────────────────────────────────
/// Events follow the Command pattern: each describes an *intent* or an
/// *external trigger* that the BLoC should react to. No business logic
/// lives here — events are pure data containers.
///
/// Event Hierarchy:
///   SeasonalEvent (sealed base)
///   ├── SeasonalStarted        — fired once on app cold start / BLoC init
///   ├── SeasonalDateChecked    — fired by the daily timer tick
///   └── SeasonalOverrideSet    — fired by developer debug override toggle

library seasonal_event;

import 'package:equatable/equatable.dart';
import 'package:weather_sync_ca/core/extensions/date_extensions.dart';

/// Base class for all events processed by [SeasonalBloc].
///
/// Sealed to guarantee exhaustive handling in switch expressions.
/// All subclasses must extend this class and mix in [Equatable] for
/// value-based equality used by BlocBuilder's rebuild optimisations.
sealed class SeasonalEvent extends Equatable {
  const SeasonalEvent();
}

// ─────────────────────────────────────────────────────────────────────────────
// LIFECYCLE EVENTS
// ─────────────────────────────────────────────────────────────────────────────

/// Dispatched exactly once when [SeasonalBloc] is first instantiated
/// (typically during app startup DI wiring in `main.dart`).
///
/// This event triggers the initial date evaluation and produces the first
/// authoritative [SeasonalState] emission, which determines which dashboard
/// (Winter or Summer) the user sees on launch.
///
/// No payload required — the BLoC reads [DateTime.now()] internally.
final class SeasonalStarted extends SeasonalEvent {
  const SeasonalStarted();

  @override
  List<Object?> get props => [];
}

// ─────────────────────────────────────────────────────────────────────────────
// PERIODIC CHECK EVENTS
// ─────────────────────────────────────────────────────────────────────────────

/// Dispatched by the BLoC's internal daily [Timer] to re-evaluate the
/// current season. The BLoC checks whether the season has changed since
/// the last emission and updates state only if necessary.
///
/// [evaluatedAt] carries the precise timestamp of the check so the BLoC
/// can correctly handle edge cases at midnight on the exact transition date
/// (May 1 and November 1).
final class SeasonalDateChecked extends SeasonalEvent {
  const SeasonalDateChecked({required this.evaluatedAt});

  /// The [DateTime] at which the periodic check was triggered.
  /// Injected explicitly rather than read inside the BLoC handler to
  /// allow deterministic unit testing of transition-boundary edge cases.
  final DateTime evaluatedAt;

  @override
  List<Object?> get props => [evaluatedAt];
}

// ─────────────────────────────────────────────────────────────────────────────
// DEVELOPER / QA OVERRIDE EVENTS
// ─────────────────────────────────────────────────────────────────────────────

/// Dispatched from the developer settings screen (accessible via a hidden
/// tap gesture in production) to force the app into a specific seasonal mode
/// regardless of the current calendar date.
///
/// Intended use cases:
///   • QA testing of Winter mode during July.
///   • Screenshot capture for App Store listing.
///   • Demo mode for stakeholder presentations.
///
/// IMPORTANT: This override is never persisted to storage and resets on
/// the next cold app launch or the next [SeasonalDateChecked] event.
final class SeasonalOverrideSet extends SeasonalEvent {
  const SeasonalOverrideSet({required this.forcedSeason});

  /// The [Season] to force the application into, regardless of date.
  final Season forcedSeason;

  @override
  List<Object?> get props => [forcedSeason];
}
