import 'package:flutter/material.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/services/live_weather_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SUNSET THERMAL SNAP CARD
// ─────────────────────────────────────────────────────────────────────────────
//
// Extracts the today's sunset time and computes the thermal drop between
// sunset hour and 2 hours post-sunset from the hourly forecast array.
// Delivers actionable Canadian lifestyle guidance for patio, walk, and
// evening bug management decisions.

class SunsetThermalSnapCard extends StatelessWidget {
  final LiveWeatherData data;

  const SunsetThermalSnapCard({super.key, required this.data});

  /// Returns the temperature at a given [target] hour from the hourly forecasts.
  /// Returns null if the hour isn't in the forecast window.
  static double? _tempAtHour(List<HourlyForecast> forecasts, int targetHour) {
    try {
      return forecasts
          .firstWhere((f) => f.time.hour == targetHour)
          .temperatureC;
    } catch (_) {
      return null;
    }
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final sunset = data.sunsetTime;

    // Only render if we have a valid sunset time
    if (sunset == null) return const SizedBox.shrink();

    final sunsetHour = sunset.hour;
    final postSunsetHour = (sunsetHour + 2).clamp(0, 23);

    final tempAtSunset = _tempAtHour(data.hourlyForecasts, sunsetHour);
    final tempPostSunset = _tempAtHour(data.hourlyForecasts, postSunsetHour);

    // Don't render without thermal data
    if (tempAtSunset == null) return const SizedBox.shrink();

    final double thermalDrop = tempPostSunset != null
        ? (tempAtSunset - tempPostSunset)
        : 0.0;

    final bool isSummer = data.temperatureC > 15;

    // ── Evening context message ──────────────────────────────────────────────
    final String alertCopy = _buildEveningCopy(
      tempAtSunset: tempAtSunset,
      thermalDrop: thermalDrop,
      isSummer: isSummer,
      sunsetHour: sunsetHour,
      precipChance: data.precipitationProbabilityPct,
    );

    // ── Accent color based on conditions ────────────────────────────────────
    final Color accentColor = thermalDrop >= 6
        ? const Color(0xFF00F0FF) // Cyan — significant drop
        : isSummer
            ? const Color(0xFFFF9F0A) // Amber — summer evening
            : const Color(0xFFE6FF00); // Electric yellow — mild

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      color: const Color(0xFF0C0C0C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label ─────────────────────────────────────────────────
          Text(
            '🌅  SUNSET THERMAL SNAP',
            style: AppTypography.monoCaption.copyWith(
              color: accentColor,
              letterSpacing: 3,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),

          // ── Sunset time + temperature row ─────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatTime(sunset),
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  height: 0.9,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUNSET',
                    style: AppTypography.monoCaption.copyWith(
                      color: AppColors.concreteGrey,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '${tempAtSunset.round()}°C',
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ── Thermal drop badge ────────────────────────────────────────
              if (thermalDrop != 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '▼ ${thermalDrop.abs().toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: thermalDrop >= 6
                            ? const Color(0xFF00F0FF)
                            : const Color(0xFFE6FF00),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'BY ${_formatTime(DateTime(sunset.year, sunset.month, sunset.day, postSunsetHour))}',
                      style: AppTypography.monoCaption.copyWith(
                        color: AppColors.concreteGrey,
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Divider ───────────────────────────────────────────────────────
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 16),

          // ── Alert copy ────────────────────────────────────────────────────
          Text(
            alertCopy,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 15,
              color: AppColors.pureWhite.withValues(alpha: 0.75),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  String _buildEveningCopy({
    required double tempAtSunset,
    required double thermalDrop,
    required bool isSummer,
    required int sunsetHour,
    required double precipChance,
  }) {
    if (precipChance > 60) {
      return 'Rain expected this evening. Wrap up your outdoor plans before sunset — wet conditions paired with falling temperatures make for a cold, miserable wind-chill combo.';
    }

    if (thermalDrop >= 8) {
      return 'Significant temperature drop incoming — ${thermalDrop.round()}°C in 2 hours. Grab a hoodie or light jacket before heading out. Evening walk or patio time is best done immediately after sunset while the warmth holds.';
    }

    if (thermalDrop >= 5) {
      final bug = isSummer && tempAtSunset > 18
          ? ' Mosquito activity peaks 30–60 min after sunset in humid air — bring bug spray if you\'re staying out.'
          : '';
      return 'Temperature drops ${thermalDrop.round()}°C in the 2 hours after sunset. A light layer is advisable for patio stays beyond ${_formatTime(DateTime(2000, 1, 1, (sunsetHour + 1).clamp(0, 23)))}.$bug';
    }

    if (isSummer && tempAtSunset > 22) {
      return 'Warm and comfortable post-sunset window tonight. Ideal patio conditions with minimal thermal shock. Prime time for outdoor dining, a trail walk, or a fire on the deck — this is the best part of the Canadian summer evening.';
    }

    if (!isSummer && tempAtSunset < 5) {
      return 'Cool evening ahead. Temperature at sunset is already at ${tempAtSunset.round()}°C — ensure anyone staying outdoors after dark has a proper shell layer. Shoulder season nights drop fast once the sun is down.';
    }

    return 'Stable evening temperatures around ${tempAtSunset.round()}°C through to midnight. Low thermal snap risk tonight — comfortable conditions for outdoor plans extending past sunset.';
  }
}
