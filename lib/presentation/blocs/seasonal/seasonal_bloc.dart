/// seasonal_bloc.dart
///
/// The Master Seasonal State Machine — [SeasonalBloc]
/// ────────────────────────────────────────────────────────────────────────────
/// This BLoC is the top-level orchestrator of the application's operational
/// mode. Its single responsibility is to determine and continuously maintain
/// the correct seasonal state ([SeasonalWinterActive] or [SeasonalSummerActive])
/// based on the current calendar date, and to emit updated state whenever the
/// season changes.
///
/// Lifecycle:
///   1. Created and provided at the root of the widget tree (in [app.dart]).
///   2. On creation, [SeasonalStarted] is dispatched by the provider.
///   3. The BLoC evaluates [DateTime.now().season] and emits the initial state.
///   4. An internal [Timer.periodic] fires every 4 hours to dispatch
///      [SeasonalDateChecked]. This catches the season flip at midnight on
///      May 1 / November 1 without relying on the user restarting the app.
///   5. [SeasonalOverrideSet] allows developer/QA to force a specific mode.
///
/// Dependency Injection:
///   The BLoC accepts an optional [DateTimeProvider] callback in its
///   constructor. In production, this defaults to [() => DateTime.now()].
///   In tests, pass [() => DateTime(2024, 1, 15)] to inject any fixed date.
///   This eliminates the need for any system-clock mocking in unit tests.
///
/// Thread Safety:
///   All [Timer] callbacks dispatch events through [add()], which is
///   thread-safe per the flutter_bloc guarantee. No direct [emit()] calls
///   are made from async contexts.

library seasonal_bloc;

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weather_sync_ca/core/extensions/date_extensions.dart';
import 'seasonal_event.dart';
import 'seasonal_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATE PROVIDER TYPE ALIAS
// ─────────────────────────────────────────────────────────────────────────────

/// A function type that returns the current [DateTime].
///
/// In production: `() => DateTime.now()`
/// In tests:      `() => DateTime(2024, 11, 15)` (inject any fixed date)
typedef DateTimeProvider = DateTime Function();

// ─────────────────────────────────────────────────────────────────────────────
// SEASONAL BLOC
// ─────────────────────────────────────────────────────────────────────────────

/// The master seasonal mode controller for the Weather Sync Engine.
///
/// Provides [SeasonalWinterActive] or [SeasonalSummerActive] as the
/// app's persistent operational state.
///
/// Usage (in DI root — [app.dart]):
/// ```dart
/// BlocProvider<SeasonalBloc>(
///   create: (_) => SeasonalBloc()..add(const SeasonalStarted()),
///   child: const AppShell(),
/// )
/// ```
///
/// Usage (in widgets):
/// ```dart
/// BlocBuilder<SeasonalBloc, SeasonalState>(
///   builder: (context, state) {
///     return switch (state) {
///       SeasonalInitial()      => const LoadingSkeleton(),
///       SeasonalWinterActive() => const WinterDashboardPage(),
///       SeasonalSummerActive() => const SummerDashboardPage(),
///     };
///   },
/// )
/// ```
class SeasonalBloc extends Bloc<SeasonalEvent, SeasonalState> {
  /// Creates a [SeasonalBloc].
  ///
  /// [dateTimeProvider] — injectable clock function. Defaults to
  /// `DateTime.now`. Override in tests for deterministic season simulation.
  ///
  /// [periodicCheckInterval] — how often the internal timer re-evaluates
  /// the season. Defaults to 4 hours. Override in tests to [Duration.zero]
  /// to prevent timer-related test hangs.
  SeasonalBloc({
    DateTimeProvider? dateTimeProvider,
    Duration periodicCheckInterval = const Duration(hours: 4),
  })  : _now = dateTimeProvider ?? (() => DateTime.now()),
        _periodicCheckInterval = periodicCheckInterval,
        super(const SeasonalInitial()) {
    // Register event handlers.
    on<SeasonalStarted>(_onSeasonalStarted);
    on<SeasonalDateChecked>(_onSeasonalDateChecked);
    on<SeasonalOverrideSet>(_onSeasonalOverrideSet);
  }

  // ─── Private Fields ─────────────────────────────────────────────────────

  /// The injected clock function. Always use [_now()] instead of
  /// [DateTime.now()] throughout this class to maintain testability.
  final DateTimeProvider _now;

  /// How frequently the periodic timer fires a [SeasonalDateChecked] event.
  final Duration _periodicCheckInterval;

  /// The internal periodic timer that watches for season transitions.
  /// Stored so it can be cancelled in [close()].
  Timer? _periodicTimer;

  // ─────────────────────────────────────────────────────────────────────────
  // EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Handles [SeasonalStarted] — the cold-start initialisation event.
  ///
  /// 1. Evaluates the current date to resolve the initial season.
  /// 2. Emits the appropriate operational state.
  /// 3. Starts the periodic timer for future date re-checks.
  ///
  /// This handler is guaranteed to run exactly once per BLoC instance.
  Future<void> _onSeasonalStarted(
    SeasonalStarted event,
    Emitter<SeasonalState> emit,
  ) async {
    final DateTime now = _now();

    // Resolve and emit the initial state.
    emit(_resolveState(now, isOverride: false));

    // Start the periodic timer to detect season flips (e.g., May 1 midnight).
    // The timer dispatches an event back through the BLoC's event stream
    // rather than calling emit() directly — this is the correct flutter_bloc
    // pattern for timer-driven state updates.
    _startPeriodicTimer();
  }

  /// Handles [SeasonalDateChecked] — the periodic re-evaluation event.
  ///
  /// Uses [evaluatedAt] from the event payload rather than calling [_now()]
  /// again, ensuring the check timestamp is exactly what the timer captured.
  ///
  /// Implements an optimisation: if the resolved season is identical to the
  /// currently active season, no new state is emitted, preventing unnecessary
  /// widget rebuilds on the 4-hour tick.
  Future<void> _onSeasonalDateChecked(
    SeasonalDateChecked event,
    Emitter<SeasonalState> emit,
  ) async {
    final SeasonalState resolvedState = _resolveState(
      event.evaluatedAt,
      isOverride: false,
    );

    // Optimisation: only emit if the season has actually changed.
    // Equatable's == handles this correctly since [resolvedAt] timestamps
    // would differ — so we compare [activeSeason] explicitly.
    final bool seasonChanged = resolvedState.activeSeason != state.activeSeason;

    if (seasonChanged) {
      emit(resolvedState);
    }
    // If no change: silent tick. No rebuild, no overhead.
  }

  /// Handles [SeasonalOverrideSet] — the developer/QA mode override.
  ///
  /// Forces a specific season regardless of the current date. The override
  /// flag is propagated in the emitted state for UI display purposes.
  /// The periodic timer continues running and will detect real season
  /// transitions, but since [_onSeasonalDateChecked] checks [activeSeason]
  /// for changes, it will naturally restore the calendar-correct state if
  /// the override's season happens to match the real season, or will
  /// override it back on the next periodic tick otherwise.
  ///
  /// NOTE: For a persistent override (e.g., a QA long-session lock),
  /// the periodic timer should be cancelled. This is intentionally NOT
  /// done here to keep the override lightweight and temporary.
  Future<void> _onSeasonalOverrideSet(
    SeasonalOverrideSet event,
    Emitter<SeasonalState> emit,
  ) async {
    final DateTime now = _now();
    emit(_buildStateForSeason(
      season: event.forcedSeason,
      resolvedAt: now,
      isOverride: true,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Resolves the correct [SeasonalState] for the given [dateTime] by
  /// delegating season detection to the [DateSeasonExtension].
  SeasonalState _resolveState(DateTime dateTime, {required bool isOverride}) {
    return _buildStateForSeason(
      season: dateTime.season,
      resolvedAt: dateTime,
      isOverride: isOverride,
    );
  }

  /// Constructs the appropriate [SeasonalState] subclass for a given
  /// [Season], computing the pre-cached transition proximity data.
  SeasonalState _buildStateForSeason({
    required Season season,
    required DateTime resolvedAt,
    required bool isOverride,
  }) {
    switch (season) {
      case Season.winter:
        return SeasonalWinterActive(
          resolvedAt: resolvedAt,
          // daysUntilSummer: delegates to the extension's pre-computed value.
          daysUntilSummer: resolvedAt.daysUntilSeasonTransition,
          isOverrideActive: isOverride,
        );

      case Season.summer:
        return SeasonalSummerActive(
          resolvedAt: resolvedAt,
          daysUntilWinter: resolvedAt.daysUntilSeasonTransition,
          isOverrideActive: isOverride,
        );
    }
  }

  /// Initialises the periodic [Timer] that dispatches [SeasonalDateChecked]
  /// on the configured interval.
  ///
  /// Called once during [_onSeasonalStarted]. Safe to call again if the
  /// timer needs to be restarted (e.g., after an [SeasonalOverrideSet]
  /// that cancelled it).
  void _startPeriodicTimer() {
    // Cancel any existing timer before creating a new one (defensive).
    _periodicTimer?.cancel();

    // Only start a timer if the interval is non-zero (avoids issues in tests
    // where [Duration.zero] is passed to disable the timer entirely).
    if (_periodicCheckInterval > Duration.zero) {
      _periodicTimer = Timer.periodic(_periodicCheckInterval, (_) {
        // Capture the timestamp at the moment the timer fires, then inject
        // it into the event for deterministic handler behaviour.
        if (!isClosed) {
          add(SeasonalDateChecked(evaluatedAt: _now()));
        }
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    // Cancel the periodic timer to prevent memory leaks and timer callbacks
    // attempting to add events to a closed BLoC stream.
    _periodicTimer?.cancel();
    _periodicTimer = null;
    return super.close();
  }
}
