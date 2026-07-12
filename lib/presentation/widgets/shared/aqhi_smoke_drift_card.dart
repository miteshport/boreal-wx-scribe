import 'package:flutter/material.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/glass_card.dart';
import 'package:weather_sync_ca/services/air_quality_service.dart';
import 'package:weather_sync_ca/services/live_weather_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AQHI & WILDFIRE SMOKE DRIFT CARD
// ─────────────────────────────────────────────────────────────────────────────
//
// Displays the Canadian AQHI score, a color-coded severity gauge, wind/plume
// geographic context, and tiered actionable Canadian health copy.
//
// Color palette by risk tier:
//   Low (1–3)       → Cyan        #00F0FF
//   Moderate (4–6)  → Amber       #FF9F0A
//   High (7–10)     → Burnt Org   #FF6B35
//   Very High (10+) → Purple      #BF5AF2

import 'dart:math';

class AqhiSmokeDriftCard extends StatefulWidget {
  final AirQualityData aq;
  final LiveWeatherData weather;

  const AqhiSmokeDriftCard({
    super.key,
    required this.aq,
    required this.weather,
  });

  @override
  State<AqhiSmokeDriftCard> createState() => _AqhiSmokeDriftCardState();
}

class _AqhiSmokeDriftCardState extends State<AqhiSmokeDriftCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600)
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isBackVisible = angle >= pi / 2;
          
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isBackVisible
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _AqhiBackSide(aq: widget.aq, weather: widget.weather),
                  )
                : _AqhiFrontSide(aq: widget.aq, weather: widget.weather),
          );
        },
      ),
    );
  }
}

// ── Shared Helper Functions ──────────────────────────────────────────────────
Color _accentForRisk(AqhiRisk risk) => switch (risk) {
      AqhiRisk.low => const Color(0xFF00F0FF),
      AqhiRisk.moderate => const Color(0xFFFF9F0A),
      AqhiRisk.high => const Color(0xFFFF6B35),
      AqhiRisk.veryHigh => const Color(0xFFBF5AF2),
    };

double _gaugeFraction(double aqhi) => (aqhi / 12.0).clamp(0.0, 1.0);

String _plumeContext(AirQualityData aq, LiveWeatherData weather) {
  final tempC = weather.temperatureC;
  final windKmh = weather.windSpeedKmh;
  final city = weather.cityName ?? 'your location';

  if (aq.risk == AqhiRisk.low) {
    if (windKmh > 20 && tempC > 10) {
      return 'Clean air circulating — $windKmh km/h winds are actively flushing the lower atmosphere over $city.';
    }
    return 'Clean air mass detected over $city. No wildfire smoke plumes detected in the regional upper atmosphere.';
  }

  if (aq.risk == AqhiRisk.moderate) {
    if (tempC > 20) {
      return 'Light smoke drift detected — elevated PM2.5 suggests a distant wildfire plume is affecting the upper atmosphere over $city. Conditions may worsen if winds shift southward.';
    }
    return 'Light particulate detected over $city. Possibly road dust or agricultural activity at low wind speeds. Monitor PM2.5 trend.';
  }

  if (aq.risk == AqhiRisk.high) {
    return '⚠️ WILDFIRE SMOKE PLUME over $city — PM2.5 at ${aq.pm2_5.toStringAsFixed(1)} µg/m³. Typical source: Northern Ontario / Quebec boreal shield fires drifting south on prevailing winds. Conditions deteriorating.';
  }

  return '🛑 HAZARDOUS SMOKE EVENT over $city — PM2.5 at ${aq.pm2_5.toStringAsFixed(1)} µg/m³ exceeds Health Canada emergency thresholds. This is consistent with a major wildfire event within 200–500 km. Treat as a public health emergency.';
}

String _healthCopy(AirQualityData aq) => switch (aq.risk) {
      AqhiRisk.low =>
        'Optimal air quality. Perfect conditions for long outdoor runs, open-window house flushing, and all-day patio time. Breathe deep.',
      AqhiRisk.moderate =>
        'Light smoke drift detected in the upper atmosphere. Unusually sensitive individuals (asthma, heart conditions) should monitor exertion and consider limiting prolonged outdoor activity.',
      AqhiRisk.high =>
        '⚠️ WILDFIRE SMOKE PLUME: Close windows immediately. Run indoor HEPA purifiers on max. Move outdoor cardio inside. Children, seniors, and anyone with respiratory conditions must stay indoors.',
      AqhiRisk.veryHigh =>
        '🛑 HAZARDOUS AIR QUALITY: Stay sealed indoors. N95 respirator required for any outdoor transit. Follow Environment Canada Air Quality Alerts at weather.gc.ca. Do not exercise outdoors.',
    };

TextStyle _scaleLabel() => TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontSize: 9,
      color: AppColors.concreteGrey.withValues(alpha: 0.5),
      letterSpacing: 0.5,
    );

// ── FRONT SIDE: SCORE & GAUGE ────────────────────────────────────────────────
class _AqhiFrontSide extends StatelessWidget {
  final AirQualityData aq;
  final LiveWeatherData weather;

  const _AqhiFrontSide({required this.aq, required this.weather});

  @override
  Widget build(BuildContext context) {
    final risk = aq.risk;
    final accent = _accentForRisk(risk);
    final fraction = _gaugeFraction(aq.aqhi);
    final scoreDisplay = aq.isVeryHigh ? '10+' : '${aq.aqhiDisplay}';

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 2, color: accent.withValues(alpha: 0.6)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🌫️  AQHI & SMOKE',
                        style: AppTypography.monoCaption.copyWith(
                          color: accent,
                          letterSpacing: 3,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        '(TAP TO FLIP)',
                        style: AppTypography.monoCaption.copyWith(
                          color: AppColors.concreteGrey,
                          letterSpacing: 1,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        scoreDisplay,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 80,
                          fontWeight: FontWeight.w900,
                          color: accent,
                          height: 0.85,
                          letterSpacing: -4,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CANADIAN AQHI',
                              style: AppTypography.monoCaption.copyWith(
                                color: AppColors.concreteGrey,
                                fontSize: 10,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              color: accent.withValues(alpha: 0.15),
                              child: Text(
                                aq.riskLabel,
                                style: AppTypography.monoCaption.copyWith(
                                  color: accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PM2.5',
                            style: AppTypography.monoCaption.copyWith(
                              color: AppColors.concreteGrey,
                              fontSize: 9,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '${aq.pm2_5.toStringAsFixed(1)} µg/m³',
                            style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'PM10',
                            style: AppTypography.monoCaption.copyWith(
                              color: AppColors.concreteGrey,
                              fontSize: 9,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '${aq.pm10.toStringAsFixed(0)} µg/m³',
                            style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _AqhiGauge(fraction: fraction),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1', style: _scaleLabel()),
                    Text('4', style: _scaleLabel()),
                    Text('7', style: _scaleLabel()),
                    Text('10+', style: _scaleLabel()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── BACK SIDE: CONTEXT & HEALTH ADVISORY ─────────────────────────────────────
class _AqhiBackSide extends StatelessWidget {
  final AirQualityData aq;
  final LiveWeatherData weather;

  const _AqhiBackSide({required this.aq, required this.weather});

  @override
  Widget build(BuildContext context) {
    final risk = aq.risk;
    final accent = _accentForRisk(risk);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 2, color: accent.withValues(alpha: 0.6)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WIND & PLUME CONTEXT',
                      style: AppTypography.monoCaption.copyWith(
                        color: accent,
                        letterSpacing: 3,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '(TAP TO FLIP)',
                      style: AppTypography.monoCaption.copyWith(
                        color: AppColors.concreteGrey,
                        letterSpacing: 1,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _plumeContext(aq, weather),
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 14,
                    color: AppColors.pureWhite.withValues(alpha: 0.65),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 16),
                Text(
                  'HEALTH ADVISORY',
                  style: AppTypography.monoCaption.copyWith(
                    color: AppColors.concreteGrey,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _healthCopy(aq),
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 15,
                    color: risk == AqhiRisk.low
                        ? AppColors.pureWhite.withValues(alpha: 0.75)
                        : AppColors.pureWhite,
                    height: 1.55,
                    fontWeight: risk.index >= 2 ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// AQHI SEVERITY GAUGE (Horizontal Progress Bar)
// ─────────────────────────────────────────────────────────────────────────────

class _AqhiGauge extends StatelessWidget {
  final double fraction; // 0.0 → 1.0

  const _AqhiGauge({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final filledWidth = (totalWidth * fraction).clamp(0.0, totalWidth);

        return Container(
          height: 10,
          width: totalWidth,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
          ),
          child: Row(
            children: [
              // Filled segment — uses a gradient across the full 4-tier palette
              if (filledWidth > 0)
                Container(
                  width: filledWidth,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF00F0FF),
                        Color(0xFFBF5AF2),
                      ],
                      stops: [0.0, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accentForFill(fraction).withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              // Notch indicator at the leading edge
            ],
          ),
        );
      },
    );
  }

  // Accent glow color for the filled bar tip — matches the active tier
  static Color _accentForFill(double f) {
    if (f <= 0.3) return const Color(0xFF00F0FF);
    if (f <= 0.55) return const Color(0xFFFF9F0A);
    if (f <= 0.85) return const Color(0xFFFF6B35);
    return const Color(0xFFBF5AF2);
  }
}
