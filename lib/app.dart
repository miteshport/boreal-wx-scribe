/// app.dart
///
/// Application Root — MaterialApp Frame
/// ─────────────────────────────────────────────────────────────────────────
/// Assembles the [MaterialApp] with the Nothing OS dark theme, installs the
/// [MultiBlocProvider] that delivers persistent BLoC streams to the entire
/// widget tree, and establishes the root navigation route.
///
/// Architecture Notes:
///   - [WeatherSyncApp] is a [StatelessWidget]. All mutable state lives in
///     BLoCs provided below. This widget never calls [setState].
///   - The [MultiBlocProvider] wraps [MaterialApp]'s `home` subtree so
///     [BlocBuilder]s anywhere in the tree can access their BLoC without
///     walking up past the [MaterialApp] navigation boundary.
///   - [SeasonalBloc] is created via the [GetIt] factory and immediately
///     receives [SeasonalStarted] to trigger the first state evaluation.
///   - Additional BLoCs (WeatherCubit, ContentCubit) are added here in
///     Phase 3 as lazy factories in the [MultiBlocProvider.providers] list.

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:weather_sync_ca/core/theme/app_theme.dart';
import 'package:weather_sync_ca/core/di/injection_container.dart';
import 'package:weather_sync_ca/presentation/blocs/seasonal/seasonal_bloc.dart';
import 'package:weather_sync_ca/presentation/blocs/seasonal/seasonal_event.dart';
import 'package:weather_sync_ca/presentation/pages/redesign/redesign_dashboard_page.dart';

/// The root application widget.
///
/// Wired once in [main.dart] as the argument to [runApp()].
/// Provides the [MaterialApp] configuration, the global theme,
/// and the top-level BLoC providers.
class WeatherSyncApp extends StatelessWidget {
  const WeatherSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // ─── BLoC PROVIDER REGISTRY ──────────────────────────────────────────
      // Order does not affect functionality but should follow dependency order:
      // providers listed earlier can be depended upon by providers listed later.
      providers: [
        // SEASONAL BLOC — Master State Machine
        // Creates a new [SeasonalBloc] instance via the get_it factory,
        // then immediately dispatches [SeasonalStarted] to boot the engine.
        // The [..] cascade ensures the event is dispatched in the same
        // expression, before any child widget has a chance to subscribe.
        BlocProvider<SeasonalBloc>(
          create: (_) => sl<SeasonalBloc>()..add(const SeasonalStarted()),
          lazy: false, // Must be alive before first frame — not lazy.
        ),

        // TODO(phase3): Add WeatherCubit BlocProvider here.
        // BlocProvider<WeatherCubit>(
        //   create: (_) => sl<WeatherCubit>(),
        // ),

        // TODO(phase3): Add ContentCubit BlocProvider here.
        // BlocProvider<ContentCubit>(
        //   create: (_) => sl<ContentCubit>(),
        // ),
      ],

      // ─── MATERIAL APP ─────────────────────────────────────────────────────
      child: MaterialApp(
        // ─── App Identity ──────────────────────────────────────────────
        title: 'WeatherSync CA',
        debugShowCheckedModeBanner: false,

        // ─── Theme ────────────────────────────────────────────────────
        // Only a dark theme is provided. The app does not support
        // a system-defined light mode — the monochrome aesthetic requires
        // the dark surface. [themeMode] is hardcoded to [ThemeMode.dark].
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,

        // ─── System UI Overlay ────────────────────────────────────────
        // Transparency is set here as a belt-and-suspenders fallback;
        // the primary overlay configuration lives in AppBar's
        // [SystemUiOverlayStyle] in [app_theme.dart].
        builder: (context, child) {
          // Apply system chrome settings once at the app level.
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: Color(0xFF000000),
              systemNavigationBarIconBrightness: Brightness.light,
            ),
          );

          // Text scale cap — prevents data-dense grid from breaking at
          // accessibility-level font size increases.
          final scaledChild = MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.3),
              ),
            ),
            child: child!,
          );

          // Return child directly so Android foldables can use their full native screen bounds
          // instead of being artificially boxed into a 430px web frame.
          return scaledChild;
        },

        // ─── Navigation ───────────────────────────────────────────────
        // Phase 2 uses named routes for simplicity.
        // Phase 4 will migrate to go_router for deep-linking support
        // (required for FCM notification-driven navigation).
        home: const RedesignDashboardPage(),

        // Named route table for Phase 3 page navigation.
        // All routes are defined here to maintain a single navigation registry.
        routes: {
          '/home': (_) => const RedesignDashboardPage(),
          // TODO(phase3): '/winter/dashboard' → WinterDashboardPage
          // TODO(phase3): '/winter/playbook'  → SurvivalPlaybookPage
          // TODO(phase3): '/summer/dashboard' → SummerDashboardPage
          // TODO(phase3): '/summer/weekend'   → WeekendScorePage
          // TODO(phase3): '/gear'             → GearGridPage
          // TODO(phase3): '/settings'         → SettingsPage
        },

        // ─── Locale ───────────────────────────────────────────────────
        // English Canada locale for all intl date/number formatting.
        // French Canada support is a planned Phase 5 localisation milestone.
        locale: const Locale('en', 'CA'),
      ),
    );
  }
}
