/// use_case.dart
///
/// Abstract Use Case Contracts — Clean Architecture Domain Layer
/// ─────────────────────────────────────────────────────────────────────────
/// All application use cases implement one of these two abstract contracts.
/// This enforces the Dependency Inversion Principle: presentation-layer
/// BLoC/Cubits depend on these abstractions, never on concrete classes.
///
/// Conventions:
///   - Async use cases implement [UseCase<ReturnType, Params>].
///   - Synchronous (pure calculation) use cases implement [SyncUseCase<R, P>].
///   - Use cases with no input implement either variant with [NoParams].
///   - Every Params class extends [Equatable] for value equality in tests.
///
/// Why SyncUseCase?
///   The domain math use cases (Shovel Window, Golden Hour, Weekend Score)
///   are pure functions with zero I/O. Forcing them into Future<> wrappers
///   would add unnecessary async overhead and make the call-sites noisier.
///   SyncUseCase makes their synchronous, deterministic nature explicit.

library use_case;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ASYNC USE CASE
// ─────────────────────────────────────────────────────────────────────────────

/// Contract for use cases that involve I/O operations: repository calls,
/// network requests, database reads, or any async computation.
///
/// Type parameters:
///   [ReturnType] — the resolved value type on success.
///   [Params]     — the input parameter object (must extend [Equatable]).
///
/// Example:
/// ```dart
/// class GetCurrentWeather extends UseCase<WeatherEntity, GetWeatherParams> {
///   @override
///   Future<WeatherEntity> call(GetWeatherParams params) async {
///     return await _weatherRepository.getCurrentWeather(params.cityId);
///   }
/// }
/// ```
abstract class UseCase<ReturnType, Params> {
  const UseCase();

  /// Executes the use case.
  ///
  /// Implementations MUST NOT catch exceptions at this level — let them
  /// propagate to the BLoC/Cubit which maps them to error states. The
  /// only exception is domain-level validation, which should throw typed
  /// [DomainException] subclasses.
  Future<ReturnType> call(Params params);
}

// ─────────────────────────────────────────────────────────────────────────────
// SYNCHRONOUS USE CASE
// ─────────────────────────────────────────────────────────────────────────────

/// Contract for pure, synchronous use cases that perform deterministic
/// calculations with no I/O dependencies.
///
/// The [call] operator allows instances to be invoked like a function:
/// ```dart
/// final result = calculateShovelWindow(params);
/// ```
///
/// This is the contract implemented by all four domain math calculators:
///   - [CalculateShovelWindow]
///   - [CalculateWindrowAlert]
///   - [CalculateGoldenHourWindow]
///   - [CalculateWeekendScore]
abstract class SyncUseCase<ReturnType, Params> {
  const SyncUseCase();

  /// Executes the use case synchronously and returns [ReturnType].
  ReturnType call(Params params);
}

// ─────────────────────────────────────────────────────────────────────────────
// PARAMS PRIMITIVES
// ─────────────────────────────────────────────────────────────────────────────

/// Marker class for use cases that require no input parameters.
///
/// ```dart
/// class RefreshWeather extends UseCase<WeatherEntity, NoParams> {
///   Future<WeatherEntity> call(NoParams _) => _repo.refresh();
/// }
/// // Usage:
/// final weather = await refreshWeather(const NoParams());
/// ```
final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
