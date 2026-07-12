/// color_palette.dart
///
/// Nothing OS / Neo-Brutalist Monochrome Color System
/// ────────────────────────────────────────────────────
/// All color values in the application MUST be referenced from this registry.
/// No widget file should ever declare a raw Color(...) literal; always import
/// and use these named semantic tokens. This enforces visual consistency and
/// makes a future light-mode or high-contrast accessibility mode trivially
/// achievable by swapping a single palette variant.
///
/// Design Philosophy:
///   - Strictly monochrome: zero hue, zero saturation across the core palette.
///   - A single functional accent (iceSpark) is permitted exclusively for
///     critical alerts (Shovel Window, Windrow alert) — it must never be
///     used decoratively.
///   - Every surface is a shade of black or grey. White is reserved for
///     primary typographic content only.

library color_palette;

import 'package:flutter/material.dart';

/// Primary color registry. Import this class wherever colors are needed.
abstract final class AppColors {
  AppColors._(); // Non-instantiable.

  // ─────────────────────────────────────────────────────────────────────────
  // FOUNDATION — ABSOLUTE VALUES
  // ─────────────────────────────────────────────────────────────────────────

  /// Absolute void. The deepest background — used for the root scaffold,
  /// bottom navigation bar background, and card bases in the dark theme.
  /// Matches Nothing OS's signature jet-black panel aesthetic.
  static const Color voidBlack = Color(0xFF000000);

  /// Absolute white. Reserved for primary headline text, active icons,
  /// and the highest-priority data readouts. Never use as a background.
  static const Color pureWhite = Color(0xFFFFFFFF);

  /// Mid-tone concrete grey. The workhorse neutral — used for secondary
  /// body text, disabled states, placeholder labels, and decorative
  /// dot-matrix accent elements.
  static const Color concreteGrey = Color(0xFF7F7F7F);

  // ─────────────────────────────────────────────────────────────────────────
  // SURFACES — LAYERED ELEVATION SYSTEM
  // ─────────────────────────────────────────────────────────────────────────

  /// Slightly lifted surface. Used for Cards, modal sheets, and list-tile
  /// backgrounds. Provides subtle perceived elevation over [voidBlack]
  /// without breaking the monochrome contract.
  static const Color surfaceDim = Color(0xFF0D0D0D);

  /// Standard elevated surface. Used for interactive tile backgrounds and
  /// the primary content card layer.
  static const Color surfaceElevated = Color(0xFF141414);

  /// High elevation surface. Used for snack bars, tooltips, and floating
  /// action containers that need to sit clearly above [surfaceElevated].
  static const Color surfaceHigh = Color(0xFF1F1F1F);

  // ─────────────────────────────────────────────────────────────────────────
  // BORDER & STROKE TOKENS
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary layout border stroke. Used for all card outlines, dividers,
  /// and the modular grid's bounding lines. Emulates the crisp, engraved
  /// panel borders characteristic of Nothing OS hardware and software.
  static const Color borderStroke = Color(0xFF2C2C2C);

  /// Subtle muted border. Used for inner section dividers and secondary
  /// structural separators where the primary [borderStroke] would be too
  /// visually heavy (e.g., within a card's internal layout).
  static const Color borderMuted = Color(0xFF1A1A1A);

  /// Active/selected border. Applied to focused input fields, active
  /// navigation items, and selected state outlines.
  static const Color borderActive = Color(0xFF5A5A5A);

  // ─────────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY TOKENS
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary text. Headlines, key data values, active labels.
  /// Always renders on a dark surface. Alias for [pureWhite].
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text. Subheadings, descriptive body copy, timestamps.
  /// A slightly dimmed off-white to create clear visual hierarchy.
  static const Color textSecondary = Color(0xFFB3B3B3);

  /// Tertiary / disabled text. Placeholder text, inactive labels,
  /// metadata annotations. Maps to a restrained mid-grey.
  static const Color textTertiary = Color(0xFF5C5C5C);

  /// Inverted text. Used exclusively on white/light backgrounds
  /// (e.g., AdMob banner integration areas). Alias for [voidBlack].
  static const Color textInverted = Color(0xFF000000);

  // ─────────────────────────────────────────────────────────────────────────
  // ICON & VECTOR TOKENS
  // ─────────────────────────────────────────────────────────────────────────

  /// Active icon fill. Full-opacity white for primary actionable icons.
  static const Color iconActive = Color(0xFFFFFFFF);

  /// Inactive icon fill. Used for unselected nav bar icons and
  /// decorative geometric weather state vectors.
  static const Color iconInactive = Color(0xFF4D4D4D);

  /// Dot-matrix accent. A slightly dimmer white used for the decorative
  /// Space Mono dot-matrix readouts and technical data grid lines.
  /// Gives the subtle "printed circuit board" aesthetic without
  /// distracting from primary content.
  static const Color dotMatrixAccent = Color(0xFFD9D9D9);

  // ─────────────────────────────────────────────────────────────────────────
  // FUNCTIONAL ACCENT — OLED MATTE PALETTE (STAGE 4)
  // ─────────────────────────────────────────────────────────────────────────

  /// The Crown Jewel: Matte Solar-Yellow.
  /// Used for Survival Guide borders, titles, and primary action buttons.
  static const Color solarYellow = Color(0xFFD4FF00);

  /// Warnings & Alerts: Matte Caution-Orange.
  static const Color cautionOrange = Color(0xFFFF9500);

  /// Telemetry Accents: Muted Cyber-Cyan.
  /// Used for standard dividers, borders, and secondary data nodes.
  /// Encoded at ~60% opacity (0x99 alpha) for a matte look.
  static const Color cyberCyan = Color(0x9900F0FF);
  
  /// (Legacy) Ice Spark — preserved for existing widget logic until fully migrated
  static const Color iceSpark = Color(0xFFB8E8FF);

  /// (Legacy) Warmth Amber — preserved for existing widget logic until fully migrated
  static const Color warmthAmber = Color(0xFFFFE0A3);

  // ─────────────────────────────────────────────────────────────────────────
  // SEMANTIC ALIASES — State Communication
  // ─────────────────────────────────────────────────────────────────────────

  /// Applied to "safe/clear" state chips (e.g., no accumulation risk).
  /// Uses a light grey — monochrome system has no green.
  static const Color statePositive = Color(0xFFD9D9D9);

  /// Applied to "warning" state indicators (e.g., approaching threshold).
  static const Color stateWarning = Color(0xFFB3B3B3);

  /// Applied to "critical" state indicators. Maps to [iceSpark] in winter
  /// context or [warmthAmber] in summer context for contextual semantics.
  static const Color stateCritical = Color(0xFFFFFFFF);

  // ─────────────────────────────────────────────────────────────────────────
  // SCRIM & OVERLAY
  // ─────────────────────────────────────────────────────────────────────────

  /// Modal barrier scrim. Semi-transparent black overlay.
  static const Color scrim = Color(0xCC000000); // 80% opacity

  /// Shimmer base (loading skeleton animation).
  static const Color shimmerBase = Color(0xFF1A1A1A);

  /// Shimmer highlight (loading skeleton animation).
  static const Color shimmerHighlight = Color(0xFF2E2E2E);

  // ─────────────────────────────────────────────────────────────────────────
  // GLASS MORPHISM — Stage 6 Glass Card System
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary glass card surface. Semi-transparent white used as the fill for
  /// all glass cards. Allows the NeoBrutalistWeatherCanvas to bleed through.
  static const Color glassWhite = Color(0x1AFFFFFF); // 10% white

  /// Glass card border line. A 20%-opacity white outline on all glass cards.
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white

  /// Inner top-edge highlight on glass cards — mimics light refraction.
  static const Color glassHighlight = Color(0x0DFFFFFF); // 5% white

  /// Dark glass surface for high-contrast elements (e.g., active header rows).
  /// Used when a glass card needs heavier opacity to ensure text legibility.
  static const Color glassDark = Color(0x99000000); // 60% black

  /// Cyan-tinted glass surface — used exclusively for the Canadian Survival
  /// Guide card to visually distinguish it from standard weather cards.
  static const Color glassCyan = Color(0x1A00F0FF); // 10% cyan
}
