/// date_extensions.dart
///
/// Seasonal DateTime Extension for the Canadian Weather Sync Engine.
/// ─────────────────────────────────────────────────────────────────
/// Provides a clean, deterministic mapping from any [DateTime] value
/// to the app's operational [Season] mode.
///
/// Season Boundaries (Fixed Calendar Model — Canadian Climate):
///   Winter → November 1 (month 11) through April 30 (month 4), inclusive.
///   Summer → May 1 (month 5) through October 31 (month 10), inclusive.
///
/// Design Decisions:
///   1. The extension accepts any [DateTime], not just [DateTime.now()].
///      This is critical for unit testability: inject any date to simulate
///      season transitions in tests without mocking system clocks.
///   2. Logic is a pure function with zero side effects. No async, no I/O.
///   3. The boundary definition deliberately matches the Canadian federal
///      meteorological winter/summer classification used by Environment
///      and Climate Change Canada (ECCC) publications.

library date_extensions;

import 'package:weather_sync_ca/core/constants/seasonal_config.dart';

/// Enumerates the two operational seasonal modes of the application.
///
/// Values are intentionally uppercase-first to read cleanly in switch
/// expressions: `case Season.winter:` reads like natural language.
enum Season {
  /// Active November 1 – April 30.
  /// Unlocks: Shovel Window, Windrow Alert, Newcomer Survival Playbook.
  winter,

  /// Active May 1 – October 31.
  /// Unlocks: Golden Hour Walker, Weekend Maximizer, Activity Score Feed.
  summer,
}

/// Extension on [DateTime] that resolves the current [Season] based on
/// the calendar month alone. Time of day and year are intentionally
/// ignored — season classification is month-boundary only.
extension DateSeasonExtension on DateTime {
  // ───────────────────────────────────────────────────────────────────────
  // CORE SEASON RESOLVER
  // ───────────────────────────────────────────────────────────────────────

  /// Returns the [Season] corresponding to this [DateTime]'s calendar month.
  ///
  /// Algorithm:
  ///   Winter months span a year-boundary (Nov → Dec → Jan → ... → Apr),
  ///   so the condition checks for month ≥ [SeasonalConfig.winterStartMonth]
  ///   (November = 11) OR month ≤ [SeasonalConfig.winterEndMonth] (April = 4).
  ///   All remaining months (5 through 10) fall into Summer.
  ///
  /// Example:
  /// ```dart
  /// DateTime(2024, 1, 15).season  // → Season.winter
  /// DateTime(2024, 6, 21).season  // → Season.summer
  /// DateTime(2024, 11, 1).season  // → Season.winter
  /// DateTime(2024, 4, 30).season  // → Season.winter
  /// DateTime(2024, 5, 1).season   // → Season.summer
  /// ```
  Season get season {
    final int m = month;

    // Winter spans a year boundary: November (11), December (12),
    // January (1), February (2), March (3), April (4).
    final bool isWinterMonth =
        m >= SeasonalConfig.winterStartMonth || // Nov or Dec
        m <= SeasonalConfig.winterEndMonth;     // Jan through Apr

    return isWinterMonth ? Season.winter : Season.summer;
  }

  // ───────────────────────────────────────────────────────────────────────
  // CONVENIENCE BOOLEAN ACCESSORS
  // ───────────────────────────────────────────────────────────────────────

  /// Returns `true` if this date falls within the Winter operational window
  /// (November through April inclusive).
  bool get isWinter => season == Season.winter;

  /// Returns `true` if this date falls within the Summer operational window
  /// (May through October inclusive).
  bool get isSummer => season == Season.summer;

  // ───────────────────────────────────────────────────────────────────────
  // TRANSITION PROXIMITY HELPERS
  // ───────────────────────────────────────────────────────────────────────

  /// Returns the number of days remaining until the next season transition.
  ///
  /// Useful for surfacing "Switching to Summer mode in 5 days" system
  /// messages as the calendar approaches May 1 or November 1.
  int get daysUntilSeasonTransition {
    // Determine the next transition date.
    final DateTime nextTransition = _nextTransitionDate();
    return nextTransition.difference(DateTime(year, month, day)).inDays;
  }

  /// Returns `true` if a season transition is occurring within the next
  /// [withinDays] days. Defaults to 7 days (one week look-ahead).
  ///
  /// Use to trigger a "Seasonal mode change approaching" UI banner.
  bool isApproachingSeasonTransition({int withinDays = 7}) {
    return daysUntilSeasonTransition <= withinDays;
  }

  /// Returns the [Season] that will be active AFTER the next transition.
  Season get nextSeason {
    return season == Season.winter ? Season.summer : Season.winter;
  }

  // ───────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ───────────────────────────────────────────────────────────────────────

  /// Computes the [DateTime] of the next season boundary switch.
  ///
  /// Transitions occur on:
  ///   May 1  (Summer begins) — [SeasonalConfig.summerStartMonth]
  ///   Nov 1  (Winter begins) — [SeasonalConfig.winterStartMonth]
  DateTime _nextTransitionDate() {
    if (isWinter) {
      // Currently winter → next transition is May 1 of the current or next year.
      // If we haven't reached May yet this year (i.e., Jan–Apr), it's this year.
      // If we're in Nov–Dec, it's next year.
      final int targetYear =
          month >= SeasonalConfig.winterStartMonth ? year + 1 : year;
      return DateTime(targetYear, SeasonalConfig.summerStartMonth, 1);
    } else {
      // Currently summer → next transition is November 1 of the current year.
      return DateTime(year, SeasonalConfig.winterStartMonth, 1);
    }
  }
}
