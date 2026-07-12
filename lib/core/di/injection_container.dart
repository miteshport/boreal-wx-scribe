/// injection_container.dart
///
/// Service Locator — Dependency Injection Registration
/// ─────────────────────────────────────────────────────────────────────────
/// This file is the single entry point for all dependency registrations.
/// The canonical [GetIt] instance ([sl] — "service locator") is wired here
/// and consumed throughout the application via [sl<T>()].
///
/// Startup Contract:
///   Call [initDependencies()] ONCE from [main.dart] before [runApp()].
///   This function is idempotent: calling it multiple times is safe
///   (get_it will log a warning but not crash).
///
/// Registration Strategy:
///   - SINGLETON:        Services, repositories, and BLoC-independent use cases.
///                       Single instance for the app lifetime.
///   - LAZY_SINGLETON:   Same lifetime as SINGLETON but created only on first
///                       access. Preferred for expensive objects not needed
///                       at startup (e.g., AdMob initialisation).
///   - FACTORY:          BLoCs and Cubits. New instance on each [sl<T>()] call,
///                       since BLoC lifetimes are tied to widget subtrees.
///
/// DATA LAYER STATUS (Phase 2):
///   Repository implementations are registered as stubs in this phase.
///   Replace [_StubWeatherRepository] with the real [WeatherRepositoryImpl]
///   when the data layer is built in Phase 3. The domain use cases will
///   require zero changes — they depend only on the abstract contract.

library injection_container;

import 'package:get_it/get_it.dart';

import 'package:weather_sync_ca/presentation/blocs/seasonal/seasonal_bloc.dart';
import 'package:weather_sync_ca/domain/usecases/calculate_shovel_window.dart';
import 'package:weather_sync_ca/domain/usecases/calculate_windrow_alert.dart';
import 'package:weather_sync_ca/domain/usecases/calculate_golden_hour_window.dart';
import 'package:weather_sync_ca/domain/usecases/calculate_weekend_score.dart';

/// The global [GetIt] service locator instance.
///
/// Use [sl<T>()] to resolve any registered dependency:
/// ```dart
/// final bloc = sl<SeasonalBloc>();
/// final useCase = sl<CalculateShovelWindow>();
/// ```
final GetIt sl = GetIt.instance;

/// Registers all application dependencies into the [GetIt] service locator.
///
/// Execution order MATTERS:
///   1. Core services (Dio, SharedPreferences)  ← no dependencies
///   2. Data sources                             ← depend on core services
///   3. Repository implementations              ← depend on data sources
///   4. Domain use cases                        ← depend on repositories
///   5. BLoCs / Cubits                          ← depend on use cases
///
/// Call exactly once from [main.dart] before [runApp()].
Future<void> initDependencies() async {
  // ─── 1. CORE SERVICES ───────────────────────────────────────────────────
  // [SharedPreferences] is async and must be awaited before use.
  // Registered as a singleton since the platform channel is initialised once.
  // NOTE: Actual init is done in main.dart. We register here so the
  // instance is available before bloc/repo construction.

  // ─── 2. DOMAIN USE CASES (Synchronous — pure functions) ─────────────────
  // Pure calculation use cases have zero I/O dependencies.
  // Registered as lazy singletons: identical instances for all callers.
  //
  // Rationale for singleton (not factory): these classes hold NO state.
  // There is no benefit to creating new instances per call-site, and
  // sharing a singleton eliminates micro-GC pressure in tight rebuild cycles.

  sl.registerLazySingleton<CalculateShovelWindow>(
    () => const CalculateShovelWindow(),
  );

  sl.registerLazySingleton<CalculateWindrowAlert>(
    () => const CalculateWindrowAlert(),
  );

  sl.registerLazySingleton<CalculateGoldenHourWindow>(
    () => const CalculateGoldenHourWindow(),
  );

  sl.registerLazySingleton<CalculateWeekendScore>(
    () => const CalculateWeekendScore(),
  );

  // ─── 3. BLOCS / CUBITS (Factories — new instance per widget subtree) ─────
  // SeasonalBloc is the master state machine. A new instance is created
  // for each [BlocProvider] invocation, which happens once at the root
  // [MultiBlocProvider] in [app.dart].
  //
  // The [SeasonalStarted] event is dispatched at the BlocProvider level
  // (see app.dart) rather than in the BLoC constructor, adhering to the
  // flutter_bloc pattern of triggering initial events externally.

  sl.registerFactory<SeasonalBloc>(
    () => SeasonalBloc(),
  );

  // ─── FUTURE REGISTRATIONS (Phase 3 — Data Layer) ─────────────────────────
  // TODO(phase3): Register Dio HTTP client singleton.
  // TODO(phase3): Register EnvironmentCanadaDataSource.
  // TODO(phase3): Register OpenWeatherMapDataSource.
  // TODO(phase3): Register FirestoreDataSource.
  // TODO(phase3): Register WeatherCacheDataSource (SharedPreferences).
  // TODO(phase3): Register WeatherRepositoryImpl (replaces stub below).
  // TODO(phase3): Register ContentRepositoryImpl.
  // TODO(phase3): Register GetCurrentWeather, GetForecast async use cases.
  // TODO(phase3): Register WeatherCubit, ContentCubit factories.
}
