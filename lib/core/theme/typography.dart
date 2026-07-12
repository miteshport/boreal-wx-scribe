/// typography.dart
///
/// Nothing OS / Neo-Brutalist Type System
/// ──────────────────────────────────────────────────────────────────────────
/// Two typefaces form the entire typographic vocabulary of this application:
///
///   SPACE GROTESK  — The structural backbone. A geometric, grotesque sans
///                    with tight tracking and commanding stroke weight. Used
///                    for all headlines, dashboard numbers, and calls to
///                    action. Its sharp geometric terminals echo Nothing OS's
///                    hardware design language.
///
///   SPACE MONO     — The technical data readout face. A monospaced,
///                    fixed-pitch typeface that evokes dot-matrix displays,
///                    circuit board silkscreen printing, and terminal output.
///                    Used exclusively for numerical weather data, timestamps,
///                    temperature readouts, and the decorative grid accent
///                    elements that define the neo-brutalist grid aesthetic.
///
/// Type Scale Convention:
///   displayLarge  — Hero numbers (temperature, countdown timers). 64–72sp.
///   displayMedium — Section headers, dashboard titles. 36–48sp.
///   headlineLarge — Card titles, modal headings. 28–32sp.
///   headlineMedium — Sub-section labels. 22–26sp.
///   titleLarge    — List tile primaries, tab labels. 18–20sp.
///   bodyLarge     — Standard body copy, article text. 16sp.
///   bodyMedium    — Supporting body copy, card descriptions. 14sp.
///   labelLarge    — Button labels, chip text. 14sp uppercase.
///   labelMedium   — Badge text, metadata. 12sp.
///   monoDisplay   — Large technical readout (Space Mono). 48sp.
///   monoBody      — Inline data values (Space Mono). 14sp.
///   monoCaption   — Grid accent labels, timestamp ticks (Space Mono). 11sp.

library typography;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';

/// Provides the full type scale as static [TextStyle] accessors.
///
/// Usage in [ThemeData]:
/// ```dart
/// textTheme: AppTypography.textTheme,
/// ```
///
/// Usage in widgets (override color/size inline when needed):
/// ```dart
/// Text('−18°', style: AppTypography.monoDisplay),
/// Text('SHOVEL WINDOW', style: AppTypography.labelLarge),
/// ```
abstract final class AppTypography {
  AppTypography._();

  // ─────────────────────────────────────────────────────────────────────────
  // FONT FAMILY CONSTANTS
  // ─────────────────────────────────────────────────────────────────────────

  static const String _grotesk = 'SpaceGrotesk';
  static const String _mono = 'SpaceMono';

  // ─────────────────────────────────────────────────────────────────────────
  // SPACE GROTESK — DISPLAY (Hero Numbers & Countdown Timers)
  // ─────────────────────────────────────────────────────────────────────────

  /// 72sp · Bold · −1.5 tracking.
  /// Designed for full-width hero data: current temperature display,
  /// active countdown timers in their most prominent form factor.
  static TextStyle get displayLarge => GoogleFonts.spaceGrotesk(
        fontSize: 72,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: AppColors.textPrimary,
        height: 1.0,
      );

  /// 48sp · Bold · −1.0 tracking.
  /// Dashboard section hero values. Large-format temperature breakdowns.
  static TextStyle get displayMedium => GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  /// 36sp · SemiBold · −0.5 tracking.
  /// Weekend score numerics, comfort index display values.
  static TextStyle get displaySmall => GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SPACE GROTESK — HEADLINES (Section & Card Titles)
  // ─────────────────────────────────────────────────────────────────────────

  /// 32sp · Bold · 0.0 tracking.
  /// Card primary titles (e.g., "SHOVEL WINDOW", "GOLDEN HOUR").
  /// Full caps treatment applied at the widget level, not here.
  static TextStyle get headlineLarge => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.0,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  /// 26sp · SemiBold · 0.0 tracking.
  /// Card sub-titles, modal section headers.
  static TextStyle get headlineMedium => GoogleFonts.spaceGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  /// 22sp · SemiBold.
  /// In-card heading levels, survival article titles.
  static TextStyle get headlineSmall => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SPACE GROTESK — TITLES (Nav, Tabs, List Items)
  // ─────────────────────────────────────────────────────────────────────────

  /// 20sp · SemiBold. App bar title, page section labels.
  static TextStyle get titleLarge => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// 16sp · Medium. List tile primary text, tab labels.
  static TextStyle get titleMedium => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// 14sp · Medium. Dense list item labels, chip text.
  static TextStyle get titleSmall => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SPACE GROTESK — BODY (Article, Card Descriptions)
  // ─────────────────────────────────────────────────────────────────────────

  /// 16sp · Regular. Primary body copy. Survival Playbook article text,
  /// weather condition descriptions.
  static TextStyle get bodyLarge => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  /// 14sp · Regular. Supporting body copy, card description text.
  static TextStyle get bodyMedium => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  /// 12sp · Regular. Small supporting text, warning card detail copy.
  static TextStyle get bodySmall => GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: AppColors.textTertiary,
        height: 1.5,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SPACE GROTESK — LABELS (Buttons, Chips, Badges)
  // ─────────────────────────────────────────────────────────────────────────

  /// 14sp · Bold · +1.2 tracking. Button labels rendered in uppercase.
  /// The aggressive tracking gives a premium, printed-label quality.
  static TextStyle get labelLarge => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textPrimary,
        height: 1.0,
      );

  /// 12sp · SemiBold · +0.8 tracking. Chip labels, badge text.
  static TextStyle get labelMedium => GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
        height: 1.0,
      );

  /// 11sp · Medium · +0.4 tracking. Caption metadata, timestamps,
  /// icon sub-labels.
  static TextStyle get labelSmall => GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: AppColors.textTertiary,
        height: 1.0,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SPACE MONO — TECHNICAL READOUTS (Dot-Matrix Aesthetic)
  // ─────────────────────────────────────────────────────────────────────────

  /// 48sp · Bold · −0.5 tracking. Space Mono.
  /// Large numerical data displays: countdown timer digits, temperature
  /// values in the active Shovel Window or Golden Hour card.
  /// The monospaced character grid prevents layout jitter as digits change.
  static TextStyle get monoDisplay => GoogleFonts.spaceMono(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
        height: 1.0,
      );

  /// 28sp · Regular · 0.0 tracking. Space Mono.
  /// Mid-size data readouts: wind speed, UV index value, snow depth cm.
  static TextStyle get monoHeadline => GoogleFonts.spaceMono(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  /// 16sp · Regular · 0.0 tracking. Space Mono.
  /// Inline data values within cards: "14 km/h", "−3°C", "2.8 cm".
  /// Also used for the dot-matrix decorative grid accent lines.
  static TextStyle get monoBody => GoogleFonts.spaceMono(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        color: AppColors.dotMatrixAccent,
        height: 1.4,
      );

  /// 12sp · Regular · +0.2 tracking. Space Mono.
  /// Chart axis labels, timestamp tick marks, grid coordinate annotations.
  /// The defining aesthetic element of the dot-matrix visual language.
  static TextStyle get monoCaption => GoogleFonts.spaceMono(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: AppColors.textTertiary,
        height: 1.3,
      );

  /// 11sp · Regular · +0.4 tracking. Space Mono.
  /// The smallest dot-matrix accent: gear grid tile metadata,
  /// AdMob label integration zones, debug overlays.
  static TextStyle get monoMicro => GoogleFonts.spaceMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: AppColors.textTertiary,
        height: 1.2,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // FULL MATERIAL TEXT THEME
  // ─────────────────────────────────────────────────────────────────────────

  /// Pre-assembled [TextTheme] for direct assignment to [ThemeData.textTheme].
  ///
  /// Maps the custom type scale to Flutter's standard Material text role
  /// slots. This ensures third-party widgets and Flutter framework components
  /// (e.g., [AppBar], [BottomNavigationBar], [ListTile]) automatically
  /// inherit the correct typographic styles without per-widget overrides.
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
