/// calculate_weekend_score.dart
///
/// Domain Use Case: Summer Weekend Outdoor Activity Potential Scorer
/// ─────────────────────────────────────────────────────────────────────────
/// Synthesises a 48-hour hourly forecast array for a target weekend period
/// into a single 1–10 lifestyle adequacy score along with component
/// subscores, qualitative label, and a contextually generated suggestion set.
///
/// SCORING MODEL: Weighted Composite Matrix
/// ────────────────────────────────────────────────────────────────────────
/// The score is computed from four independently normalised component
/// scores (each 0.0–1.0), combined via a fixed weight vector, then
/// mapped to the 1–10 integer display scale.
///
/// COMPONENT WEIGHTS (from SeasonalConfig):
///   Precipitation probability:  35% (highest weight — rain cancels everything)
///   Temperature comfort:        30% (second — cold/heat makes it miserable)
///   UV index quality:           20% (third — too high means sunburn risk)
///   Wind speed penalty:         15% (last — wind is a minor nuisance, not fatal)
///
/// COMPONENT SCORING FUNCTIONS:
///
///   precipScore = 1.0 − (avgPrecipProbability / 100.0)
///     → Linear: 0% chance = perfect (1.0); 100% chance = worst (0.0)
///
///   tempScore = normalise(avgTemperatureC):
///     < 5°C      → 0.0  (too cold for Canadian outdoor comfort)
///     5–12°C     → 0.1  (chilly — jacket weather but manageable)
///     12–18°C    → 0.4  (cool — some outdoor activities viable)
///     18–26°C    → 1.0  (ideal — peak Canadian summer comfort band)
///     26–32°C    → 0.7  (warm — active outdoor slightly uncomfortable)
///     32–38°C    → 0.3  (hot — humidex risk for strenuous activity)
///     > 38°C     → 0.0  (extreme heat — Health Canada advisory range)
///
///   uvScore = normalise(avgUvIndex):
///     0–2        → 0.9  (low UV — pleasant; minor sunscreen not needed)
///     3–5        → 1.0  (moderate — ideal; safe for extended outdoor time)
///     6–7        → 0.8  (high — apply SPF 30; limit 11am–3pm exposure)
///     8–10       → 0.5  (very high — seek shade; score penalty applied)
///     > 10       → 0.2  (extreme — Health Canada risk level)
///
///   windScore:
///     ≤ 20 km/h  → 1.0  (calm — ideal)
///     20–30 km/h → 0.8  (light — noticeable but fine)
///     30–50 km/h → 0.5  (moderate — some outdoor activities affected)
///     50–70 km/h → 0.2  (strong — Environment Canada strong wind advisory)
///     > 70 km/h  → 0.0  (storm-level — full score penalty)
///
/// FINAL SCORE MAPPING:
///   rawWeightedScore ∈ [0.0, 1.0]
///   displayScore = round(rawWeightedScore × 9.0 + 1.0).clamp(1, 10)
///
///   This maps [0.0 → 1, 1.0 → 10] ensuring the display scale always uses
///   the full 1–10 range with 1 representing "genuinely terrible" conditions
///   and 10 representing a rare, perfect Canadian summer weekend.
///
/// ACTIVITY SUGGESTIONS:
///   Generated contextually from the final score and dominant limiting factor.
///   Example: high UV score but good precip → suggest shaded trail activities.

library calculate_weekend_score;

import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:weather_sync_ca/core/constants/seasonal_config.dart';
import 'package:weather_sync_ca/domain/entities/hourly_forecast.dart';
import 'package:weather_sync_ca/domain/usecases/use_case.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PARAMS
// ─────────────────────────────────────────────────────────────────────────────

/// Input parameters for [CalculateWeekendScore].
final class CalculateWeekendScoreParams extends Equatable {
  const CalculateWeekendScoreParams({
    required this.forecasts,
    required this.weekendLabel,
  });

  /// 48-hour hourly forecast array covering the full Saturday–Sunday period.
  /// Must contain at least 2 entries; ideally 48 (one per hour).
  /// The use case gracefully handles partial datasets (e.g., 12h forecasts).
  final List<HourlyForecast> forecasts;

  /// Human-readable label for this weekend (e.g., "This Weekend", "Canada Day").
  /// Passed through to the result for display in the [WeekendScoreCard].
  final String weekendLabel;

  @override
  List<Object?> get props => [forecasts, weekendLabel];
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULT
// ─────────────────────────────────────────────────────────────────────────────

/// Output of [CalculateWeekendScore].
///
/// The [score] field is the primary display value. [subscores] are
/// for the expanded detail view. [suggestions] drive the content feed.
final class WeekendScoreResult extends Equatable {
  const WeekendScoreResult({
    required this.score,
    required this.label,
    required this.weekendLabel,
    required this.qualityDescription,
    required this.subscores,
    required this.suggestions,
    required this.limitingFactor,
    required this.analyzedHours,
    required this.avgTemperatureC,
    required this.avgPrecipProbabilityPercent,
    required this.avgUvIndex,
    required this.maxWindSpeedKmh,
  });

  /// Final lifestyle score, 1–10. The primary display value.
  final int score;

  /// Short qualitative label for the score (e.g., "EXCELLENT", "POOR").
  final String label;

  /// The weekend label passed from [CalculateWeekendScoreParams].
  final String weekendLabel;

  /// Full qualitative description sentence for the card body.
  final String qualityDescription;

  /// Decomposed component subscores (each 0.0–1.0) for detail display.
  final WeekendSubscores subscores;

  /// Context-driven activity suggestions based on the score profile.
  final List<String> suggestions;

  /// The primary factor limiting the score (for "why not higher?" context).
  final WeekendLimitingFactor limitingFactor;

  // Aggregated input metrics (for transparency in UI detail view).
  final int analyzedHours;
  final double avgTemperatureC;
  final double avgPrecipProbabilityPercent;
  final double avgUvIndex;
  final double maxWindSpeedKmh;

  @override
  List<Object?> get props => [
        score,
        label,
        weekendLabel,
        subscores,
        suggestions,
        limitingFactor,
        analyzedHours,
      ];
}

/// Decomposed component subscores for the detail/expand view.
final class WeekendSubscores extends Equatable {
  const WeekendSubscores({
    required this.precipitation,
    required this.temperature,
    required this.uvIndex,
    required this.wind,
    required this.composite,
  });

  final double precipitation; // 0.0–1.0
  final double temperature;   // 0.0–1.0
  final double uvIndex;       // 0.0–1.0
  final double wind;          // 0.0–1.0
  final double composite;     // weighted sum 0.0–1.0

  @override
  List<Object?> get props => [precipitation, temperature, uvIndex, wind, composite];
}

/// Identifies the single factor most responsible for limiting the score.
/// Used in the "Here's what's holding your score back" UI copy.
enum WeekendLimitingFactor {
  precipitation,
  temperature,
  uvIndex,
  wind,
  none, // All factors are good — no limiting factor to report.
}

// ─────────────────────────────────────────────────────────────────────────────
// USE CASE
// ─────────────────────────────────────────────────────────────────────────────

/// Synchronous pure-function use case synthesising a 48-hour forecast
/// into a 1–10 weekend lifestyle adequacy score.
///
/// Usage:
/// ```dart
/// final calculateWeekendScore = CalculateWeekendScore();
/// final result = calculateWeekendScore(CalculateWeekendScoreParams(
///   forecasts: weekendForecasts,
///   weekendLabel: 'This Weekend',
/// ));
/// // Display result.score (1–10) and result.suggestions
/// ```
final class CalculateWeekendScore
    extends SyncUseCase<WeekendScoreResult, CalculateWeekendScoreParams> {
  const CalculateWeekendScore();

  // ─────────────────────────────────────────────────────────────────────────
  // ENTRY POINT
  // ─────────────────────────────────────────────────────────────────────────

  @override
  WeekendScoreResult call(CalculateWeekendScoreParams params) {
    assert(
      params.forecasts.isNotEmpty,
      'CalculateWeekendScore requires at least one forecast entry.',
    );

    // ── Step 1: Aggregate input metrics ─────────────────────────────────
    final int n = params.forecasts.length;

    final double avgPrecipProb = _mean(
      params.forecasts.map((f) => f.precipProbabilityPercent),
    );
    final double avgTempC = _mean(
      params.forecasts.map((f) => f.temperatureC),
    );
    final double avgUvIndex = _mean(
      params.forecasts.map((f) => f.uvIndex),
    );
    final double maxWindKmh = params.forecasts
        .map((f) => f.windSpeedKmh)
        .reduce(max);

    // ── Step 2: Compute component scores (0.0–1.0) ───────────────────────
    final double precipScore = _scorePrecipitation(avgPrecipProb);
    final double tempScore = _scoreTemperature(avgTempC);
    final double uvScore = _scoreUvIndex(avgUvIndex);
    final double windScore = _scoreWind(maxWindKmh);

    // ── Step 3: Weighted composite ───────────────────────────────────────
    final double compositeScore =
        (precipScore * SeasonalConfig.weekendPrecipWeight) +
            (tempScore * SeasonalConfig.weekendTempWeight) +
            (uvScore * SeasonalConfig.weekendUvWeight) +
            (windScore * SeasonalConfig.weekendWindWeight);

    // ── Step 4: Map composite (0.0–1.0) to display scale (1–10) ─────────
    // Linear mapping: 0.0 → 1, 1.0 → 10.
    final int displayScore =
        (compositeScore * 9.0 + 1.0).round().clamp(1, 10);

    // ── Step 5: Determine limiting factor ────────────────────────────────
    final WeekendLimitingFactor limiting = _identifyLimitingFactor(
      precipScore: precipScore,
      tempScore: tempScore,
      uvScore: uvScore,
      windScore: windScore,
    );

    // ── Step 6: Build qualitative output ─────────────────────────────────
    final String label = _scoreLabel(displayScore);
    final String description = _buildDescription(
      displayScore,
      avgTempC,
      avgPrecipProb,
      avgUvIndex,
      limiting,
    );
    final List<String> suggestions = _buildSuggestions(
      displayScore,
      avgTempC,
      avgUvIndex,
      avgPrecipProb,
      maxWindKmh,
      limiting,
    );

    return WeekendScoreResult(
      score: displayScore,
      label: label,
      weekendLabel: params.weekendLabel,
      qualityDescription: description,
      subscores: WeekendSubscores(
        precipitation: precipScore,
        temperature: tempScore,
        uvIndex: uvScore,
        wind: windScore,
        composite: compositeScore,
      ),
      suggestions: suggestions,
      limitingFactor: limiting,
      analyzedHours: n,
      avgTemperatureC: avgTempC,
      avgPrecipProbabilityPercent: avgPrecipProb,
      avgUvIndex: avgUvIndex,
      maxWindSpeedKmh: maxWindKmh,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT SCORING FUNCTIONS
  // Each returns a score in [0.0, 1.0] unless documented otherwise.
  // ─────────────────────────────────────────────────────────────────────────

  /// Linear precipitation score. 0% probability = 1.0, 100% = 0.0.
  double _scorePrecipitation(double avgProbPercent) =>
      1.0 - (avgProbPercent / 100.0).clamp(0.0, 1.0);

  /// Stepped temperature comfort function tuned for Canadian summer range.
  double _scoreTemperature(double avgTempC) {
    if (avgTempC < 5.0) return 0.0;
    if (avgTempC < 12.0) return 0.1;
    if (avgTempC < 18.0) return 0.4;
    if (avgTempC <= 26.0) return 1.0; // ← ideal band
    if (avgTempC <= 32.0) return 0.7;
    if (avgTempC <= 38.0) return 0.3;
    return 0.0; // > 38°C: extreme heat
  }

  /// Stepped UV index quality function.
  double _scoreUvIndex(double avgUv) {
    if (avgUv <= 2.0) return 0.9;
    if (avgUv <= 5.0) return 1.0; // ideal moderate UV
    if (avgUv <= 7.0) return 0.8;
    if (avgUv <= 10.0) return 0.5;
    return 0.2; // > 10: extreme UV
  }

  /// Stepped wind speed penalty function.
  double _scoreWind(double maxWindKmh) {
    if (maxWindKmh <= 20.0) return 1.0;
    if (maxWindKmh <= 30.0) return 0.8;
    if (maxWindKmh <= 50.0) return 0.5;
    if (maxWindKmh <= 70.0) return 0.2;
    return 0.0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // QUALITATIVE OUTPUT BUILDERS
  // ─────────────────────────────────────────────────────────────────────────

  String _scoreLabel(int score) => switch (score) {
        10 || 9 => 'EXCELLENT',
        8 => 'GREAT',
        7 => 'GOOD',
        6 => 'FAIR',
        5 => 'AVERAGE',
        4 => 'BELOW AVG',
        3 => 'POOR',
        _ => 'VERY POOR',
      };

  /// Identifies the component with the lowest weighted contribution.
  WeekendLimitingFactor _identifyLimitingFactor({
    required double precipScore,
    required double tempScore,
    required double uvScore,
    required double windScore,
  }) {
    // Weight the scores to find which one drags the composite down the most.
    final Map<WeekendLimitingFactor, double> weightedPenalties = {
      WeekendLimitingFactor.precipitation:
          (1.0 - precipScore) * SeasonalConfig.weekendPrecipWeight,
      WeekendLimitingFactor.temperature:
          (1.0 - tempScore) * SeasonalConfig.weekendTempWeight,
      WeekendLimitingFactor.uvIndex:
          (1.0 - uvScore) * SeasonalConfig.weekendUvWeight,
      WeekendLimitingFactor.wind:
          (1.0 - windScore) * SeasonalConfig.weekendWindWeight,
    };

    final double maxPenalty =
        weightedPenalties.values.reduce(max);

    // If the largest penalty is small, no factor is meaningfully limiting.
    if (maxPenalty < 0.05) return WeekendLimitingFactor.none;

    return weightedPenalties.entries
        .firstWhere((e) => e.value == maxPenalty)
        .key;
  }

  String _buildDescription(
    int score,
    double avgTemp,
    double avgPrecipProb,
    double avgUv,
    WeekendLimitingFactor limiting,
  ) {
    final String tempStr = '${avgTemp.toStringAsFixed(0)}°C';
    final String precipStr =
        '${avgPrecipProb.toStringAsFixed(0)}% precipitation chance';

    if (score >= 8) {
      return 'Outstanding weekend ahead. $tempStr with $precipStr. '
          'Get outside — conditions are near-ideal for any activity.';
    }
    if (score >= 6) {
      final String limitStr = switch (limiting) {
        WeekendLimitingFactor.precipitation => 'some rain risk',
        WeekendLimitingFactor.temperature => 'temperature considerations',
        WeekendLimitingFactor.uvIndex => 'elevated UV',
        WeekendLimitingFactor.wind => 'wind gusts',
        WeekendLimitingFactor.none => 'mixed conditions',
      };
      return 'Decent weekend with $limitStr. $tempStr, $precipStr. '
          'Plan around the limiting factor and it\'s manageable.';
    }
    if (score >= 4) {
      return 'Average conditions. $tempStr and $precipStr. '
          'Indoor alternatives are worth considering.';
    }
    return 'Challenging weekend weather. $tempStr, $precipStr. '
        'Prioritise indoor activities or covered outdoor venues.';
  }

  List<String> _buildSuggestions(
    int score,
    double avgTemp,
    double avgUv,
    double avgPrecipProb,
    double maxWind,
    WeekendLimitingFactor limiting,
  ) {
    final List<String> suggestions = [];

    if (score >= 8) {
      suggestions.addAll([
        'Farmers market or outdoor brunch',
        'Park picnic or waterfront walk',
        'Cycling trail or light hiking',
        'Patio dining — perfect conditions',
      ]);
    } else if (score >= 6) {
      if (limiting == WeekendLimitingFactor.uvIndex && avgUv > 7) {
        suggestions.add('Apply SPF 50+ — UV index elevated (${avgUv.toStringAsFixed(1)})');
        suggestions.add('Shaded trail walk or tree-covered park');
      } else if (limiting == WeekendLimitingFactor.precipitation) {
        suggestions.add('Covered patio dining — bring a light layer');
        suggestions.add('Indoor market or gallery if rain arrives');
      }
      suggestions.addAll([
        'Morning walk (best window before 11 AM)',
        'Outdoor activity with a flexible rain backup',
      ]);
    } else if (score >= 4) {
      suggestions.addAll([
        'Indoor café or museum day',
        'Quick errands — check hourly forecast for dry windows',
        'Evening drive if rain clears by sunset',
      ]);
    } else {
      suggestions.addAll([
        'Stay-in weekend — meal prep or home project',
        'Covered recreational facility (indoor pool, rec centre)',
        'Check next weekend\'s forecast for better conditions',
      ]);
    }

    return suggestions;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MATH UTILITIES
  // ─────────────────────────────────────────────────────────────────────────

  /// Computes the arithmetic mean of an iterable of doubles.
  double _mean(Iterable<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
