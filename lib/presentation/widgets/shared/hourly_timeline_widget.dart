import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/services/live_weather_service.dart';

class HourlyTimelineSection extends StatelessWidget {
  final LiveWeatherData data;
  /// When false, temperatures are converted to Fahrenheit.
  final bool isCelsius;

  const HourlyTimelineSection({super.key, required this.data, this.isCelsius = true});

  String _emojiForCode(int code) {
    if (code == 0) return '\u2600\uFE0F';
    if (code >= 1 && code <= 2) return '\u26C5';
    if (code == 3) return '\u2601\uFE0F';
    if (code >= 45 && code <= 48) return '\uD83C\uDF2B\uFE0F';
    if (code >= 51 && code <= 55) return '\uD83C\uDF27\uFE0F';
    if (code >= 56 && code <= 67) return '\uD83C\uDF27\uFE0F';
    if (code >= 71 && code <= 77) return '\u2744\uFE0F';
    if (code >= 80 && code <= 82) return '\uD83C\uDF26\uFE0F';
    if (code >= 85 && code <= 86) return '\u2744\uFE0F';
    if (code >= 95) return '\u26C8\uFE0F';
    return '\u2601\uFE0F';
  }

  @override
  Widget build(BuildContext context) {
    if (data.hourlyForecasts.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final showBriefing = now.hour >= 19;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBriefing) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _MicroBriefing(data: data, isCelsius: isCelsius),
          ),
          const SizedBox(height: 24),
        ],
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: data.hourlyForecasts.length,
            itemBuilder: (context, index) {
              final forecast = data.hourlyForecasts[index];
              final isFirst = index == 0;
              final timeStr = isFirst ? 'Now' : DateFormat('h a').format(forecast.time);

              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 68,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      color: isFirst
                          ? AppColors.pureWhite.withValues(alpha: 0.18)
                          : AppColors.pureWhite.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.pureWhite
                            .withValues(alpha: isFirst ? 0.35 : 0.12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timeStr,
                          style: AppTypography.monoCaption.copyWith(
                            color: isFirst
                                ? AppColors.pureWhite
                                : AppColors.concreteGrey,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _emojiForCode(forecast.weatherCode),
                          style: TextStyle(
                            fontSize: isFirst ? 22 : 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isCelsius
                              ? '${forecast.temperatureC.round()}°'
                              : '${((forecast.temperatureC * 9 / 5) + 32).round()}°',
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontWeight: FontWeight.bold,
                            fontSize: isFirst ? 16 : 15,
                            color: AppColors.pureWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MicroBriefing extends StatelessWidget {
  final LiveWeatherData data;
  final bool isCelsius;

  const _MicroBriefing({required this.data, this.isCelsius = true});

  @override
  Widget build(BuildContext context) {
    // Determine tomorrow's high by scanning the forecast
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    double highTemp = data.temperatureC;
    for (final f in data.hourlyForecasts) {
      if (f.time.day == tomorrow.day && f.temperatureC > highTemp) {
        highTemp = f.temperatureC;
      }
    }

    final unit = isCelsius ? '°C' : '°F';
    final displayHigh = isCelsius ? highTemp.round().toString() : ((highTemp * 9 / 5) + 32).round().toString();
    final brief = 'Partly cloudy tomorrow with a high of $displayHigh$unit. Sunrise at 6:15 AM.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          left: BorderSide(color: Color(0xFFE6FF00), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EVENING BRIEFING',
            style: AppTypography.monoCaption.copyWith(
              color: const Color(0xFFE6FF00),
              letterSpacing: 2,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            brief,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              height: 1.4,
              color: AppColors.pureWhite,
            ),
          ),
        ],
      ),
    );
  }
}
