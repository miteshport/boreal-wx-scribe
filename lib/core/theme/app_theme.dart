/// app_theme.dart
///
/// Nothing OS / Neo-Brutalist ThemeData Assembly
/// ────────────────────────────────────────────────────────────────────────────
/// This file is the single source of truth for the application's Material
/// [ThemeData]. Every component theme (buttons, cards, navigation, inputs,
/// dialogs, etc.) is locked to the monochrome palette and the two-typeface
/// type scale defined in [AppColors] and [AppTypography].
///
/// Architecture:
///   [AppTheme] exposes one static getter: [AppTheme.dark].
///   The app only ships a Dark theme (monochrome / Nothing OS aesthetic).
///   If a Light theme is ever required, add [AppTheme.light] following
///   the same structure with inverted surface/text token assignments.
///
/// Core Aesthetic Rules encoded in this file:
///   1. Elevation → expressed through border stroke, NOT drop shadows.
///      Material's default shadow-based elevation is globally overridden
///      to zero; borders do the structural work instead.
///   2. Border radius → geometric, minimal. Cards: 0dp (sharp corners).
///      Buttons: 0dp. Chips: 0dp. Nothing OS hardware is cornered, not
///      rounded. Departure from this requires explicit justification.
///   3. Color scheme → derived exclusively from [AppColors] tokens.
///      No raw Color() literals are used in this file.
///   4. Typography → delegated entirely to [AppTypography.textTheme].

library app_theme;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';

/// Static factory for the application's [ThemeData].
abstract final class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────────────────────────────────
  // DARK THEME (PRIMARY / ONLY PRODUCTION THEME)
  // ─────────────────────────────────────────────────────────────────────────

  /// The canonical Nothing OS-inspired dark [ThemeData].
  ///
  /// Assign to [MaterialApp.theme] and [MaterialApp.darkTheme].
  static ThemeData get dark {
    // Build the core ColorScheme from monochrome tokens.
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.pureWhite,         // Active interactive elements
      onPrimary: AppColors.voidBlack,       // Content on primary surfaces
      primaryContainer: AppColors.surfaceElevated,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.concreteGrey,    // Secondary interactive elements
      onSecondary: AppColors.voidBlack,
      secondaryContainer: AppColors.surfaceHigh,
      onSecondaryContainer: AppColors.textSecondary,
      tertiary: AppColors.dotMatrixAccent,  // Dot-matrix accent
      onTertiary: AppColors.voidBlack,
      tertiaryContainer: AppColors.borderStroke,
      onTertiaryContainer: AppColors.textTertiary,
      error: AppColors.iceSpark,            // Alerts use iceSpark, not red
      onError: AppColors.voidBlack,
      errorContainer: AppColors.surfaceHigh,
      onErrorContainer: AppColors.iceSpark,
      surface: AppColors.surfaceDim,        // Card/tile background
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceHigh,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderStroke,      // Borders and dividers
      outlineVariant: AppColors.borderMuted,
      shadow: AppColors.voidBlack,          // Shadow (minimised/zeroed out)
      scrim: AppColors.scrim,
      inverseSurface: AppColors.pureWhite,
      onInverseSurface: AppColors.voidBlack,
      inversePrimary: AppColors.voidBlack,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,

      // ─── Typography ───────────────────────────────────────────────────
      textTheme: AppTypography.textTheme,
      primaryTextTheme: AppTypography.textTheme,

      // ─── Scaffold & Background ────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.voidBlack,
      canvasColor: AppColors.voidBlack,

      // ─── AppBar ───────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.voidBlack,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          letterSpacing: 1.5,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.iconActive,
          size: 22,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.iconActive,
          size: 22,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // White status icons
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.voidBlack,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // ─── Cards ────────────────────────────────────────────────────────
      // Sharp corners (0dp radius), border-defined elevation, zero shadow.
      // The borderOnForeground: true ensures the stroke renders above content.
      cardTheme: const CardThemeData(
        color: AppColors.surfaceElevated,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Sharp Nothing OS corners
          side: BorderSide(
            color: AppColors.borderStroke,
            width: 1.0,
          ),
        ),
      ),

      // ─── Divider ──────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.borderStroke,
        thickness: 1.0,
        space: 1.0, // No padding around divider — let callers control spacing
        indent: 0,
        endIndent: 0,
      ),

      // ─── ElevatedButton ───────────────────────────────────────────────
      // Primary action: white fill, black text, zero radius, uppercase label.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.borderStroke;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.concreteGrey;
            }
            return AppColors.pureWhite;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textTertiary;
            }
            return AppColors.voidBlack;
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(0),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          textStyle: WidgetStateProperty.all(AppTypography.labelLarge),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          side: WidgetStateProperty.resolveWith<BorderSide>((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: AppColors.pureWhite, width: 2);
            }
            return BorderSide.none;
          }),
        ),
      ),

      // ─── OutlinedButton ───────────────────────────────────────────────
      // Secondary action: transparent fill, white border, white text.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textTertiary;
            }
            return AppColors.pureWhite;
          }),
          overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.pureWhite.withOpacity(0.05);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.pureWhite.withOpacity(0.03);
            }
            return Colors.transparent;
          }),
          elevation: WidgetStateProperty.all(0),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          textStyle: WidgetStateProperty.all(AppTypography.labelLarge),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          side: WidgetStateProperty.resolveWith<BorderSide>((states) {
            if (states.contains(WidgetState.disabled)) {
              return const BorderSide(color: AppColors.borderStroke, width: 1);
            }
            if (states.contains(WidgetState.pressed)) {
              return const BorderSide(color: AppColors.pureWhite, width: 1.5);
            }
            return const BorderSide(color: AppColors.borderActive, width: 1);
          }),
        ),
      ),

      // ─── TextButton ───────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textTertiary;
            }
            return AppColors.textSecondary;
          }),
          overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.pureWhite.withOpacity(0.05);
            }
            return Colors.transparent;
          }),
          textStyle: WidgetStateProperty.all(AppTypography.labelMedium),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),

      // ─── Bottom Navigation Bar ────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.voidBlack,
        indicatorColor: AppColors.surfaceElevated,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.borderActive, width: 1),
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final bool isSelected = states.contains(WidgetState.selected);
          return AppTypography.monoCaption.copyWith(
            color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
            letterSpacing: 0.8,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          final bool isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? AppColors.iconActive : AppColors.iconInactive,
            size: 22,
          );
        }),
      ),

      // ─── Input Decoration (TextField, Search) ─────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        hoverColor: AppColors.surfaceHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        labelStyle: AppTypography.titleSmall,
        floatingLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        prefixIconColor: AppColors.iconInactive,
        suffixIconColor: AppColors.iconInactive,
        // Border: always visible stroke, no rounded corners.
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.borderStroke, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.borderStroke, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.pureWhite, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.iceSpark, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.iceSpark, width: 1.5),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.borderMuted, width: 1),
        ),
        errorStyle:
            AppTypography.labelSmall.copyWith(color: AppColors.iceSpark),
      ),

      // ─── Chip ─────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.pureWhite,
        disabledColor: AppColors.surfaceDim,
        surfaceTintColor: Colors.transparent,
        side: const BorderSide(color: AppColors.borderStroke, width: 1),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        labelStyle: AppTypography.labelMedium,
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.voidBlack,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        elevation: 0,
        pressElevation: 0,
        shadowColor: Colors.transparent,
      ),

      // ─── List Tile ────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.surfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        minLeadingWidth: 24,
        minVerticalPadding: 12,
        titleTextStyle: AppTypography.titleMedium,
        subtitleTextStyle: AppTypography.bodySmall,
        leadingAndTrailingTextStyle: AppTypography.labelSmall,
        iconColor: AppColors.iconInactive,
        selectedColor: AppColors.pureWhite,
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderMuted, width: 1),
        ),
      ),

      // ─── Progress Indicator ───────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.pureWhite,
        linearTrackColor: AppColors.borderStroke,
        circularTrackColor: AppColors.borderStroke,
        linearMinHeight: 1.5, // Hair-thin — consistent with dot-matrix style
      ),

      // ─── Switch / Toggle ──────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.voidBlack;
          }
          return AppColors.concreteGrey;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.pureWhite;
          }
          return AppColors.borderStroke;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ─── Dialog ───────────────────────────────────────────────────────
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.borderStroke, width: 1),
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // ─── Bottom Sheet ─────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surfaceElevated,
        modalElevation: 0,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.borderStroke, width: 1),
        ),
        dragHandleColor: AppColors.borderActive,
        dragHandleSize: Size(36, 3),
      ),

      // ─── Snack Bar ────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle:
            AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        actionTextColor: AppColors.pureWhite,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.borderActive, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ─── Icon ─────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.iconActive,
        size: 22,
      ),
      primaryIconTheme: const IconThemeData(
        color: AppColors.iconActive,
        size: 22,
      ),

      // ─── Global Material Overrides ────────────────────────────────────
      // Disable all Material ink splashes — they look out of place in a
      // neo-brutalist design. Taps should feel precise, not organic.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: AppColors.pureWhite.withOpacity(0.03),
      focusColor: AppColors.pureWhite.withOpacity(0.05),
    );
  }
}
