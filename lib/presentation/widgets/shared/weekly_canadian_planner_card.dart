/// weekly_canadian_planner_card.dart
///
/// Neo-Brutalist 7-Day Canadian Lifestyle Outlook Card
/// ─────────────────────────────────────────────────────────────────────────
/// Renders a full editorial weekly forecast driven by the WeatherStateMatrix.
/// - Weekend Anchor block with short editorial copy.
/// - 7 day rows with day name, temp range, Matrix headline tag.
/// - Prime Two-Four Day badge in signature Solar-Yellow.
/// - Tap → Solar-Yellow 3-part Canadian Survival Sheet.
library weekly_canadian_planner_card;

import 'package:flutter/material.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/domain/matrix/weather_state_matrix.dart';
import 'package:weather_sync_ca/domain/usecases/weekly_forecasting_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const Color _solarYellow = Color(0xFFD4FF00);
const Color _deepBlack = Color(0xFF0A0A0A);
const Color _cardBg = Color(0xFF111111);
const Color _borderColor = Color(0xFF2A2A2A);

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class WeeklyCanadianPlannerCard extends StatelessWidget {
  final List<TaggedDailyForecast> taggedWeek;
  final String weekendSummary;

  const WeeklyCanadianPlannerCard({
    super.key,
    required this.taggedWeek,
    required this.weekendSummary,
  });

  @override
  Widget build(BuildContext context) {
    if (taggedWeek.isEmpty) return const SizedBox.shrink();

    final weekendDays = taggedWeek.where((t) => t.isWeekend).toList();

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.glassBorder, width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: _solarYellow, size: 16),
                const SizedBox(width: 10),
                Text(
                  '7-DAY CANADIAN OUTLOOK',
                  style: AppTypography.monoCaption.copyWith(
                    color: _solarYellow,
                    letterSpacing: 3,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // ── 7-Day Rows ───────────────────────────────────────────────────
          ...taggedWeek.asMap().entries.map((e) => _DayRow(
                tagged: e.value,
                index: e.key,
                isLast: e.key == taggedWeek.length - 1,
                onTap: () => _openSurvivalSheet(context, e.value),
              )),
        ],
      ),
    );
  }

  // ── Solar-Yellow Survival Sheet ──────────────────────────────────────────

  void _openSurvivalSheet(BuildContext context, TaggedDailyForecast tagged) {
    final profile = tagged.profile;
    final day = tagged.forecast;
    const Color sheetBg = _solarYellow;
    const Color textBlack = _deepBlack;
    const Color dividerClr = Color(0xFF1A1A00);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Pull tab ──────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 28),
                        decoration: BoxDecoration(
                          color: textBlack.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // ── Day label ─────────────────────────────────────────
                    Text(
                      _fullDayName(day.date.weekday).toUpperCase(),
                      style: AppTypography.monoCaption.copyWith(
                        color: textBlack.withValues(alpha: 0.55),
                        letterSpacing: 3,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // ── Headline ──────────────────────────────────────────
                    Text(
                      profile.headline,
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: textBlack,
                        height: 1.05,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Temp range ────────────────────────────────────────
                    Text(
                      '${day.tempMin.round()}° / ${day.tempMax.round()}°C',
                      style: AppTypography.monoCaption.copyWith(
                        color: textBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Container(height: 2, color: dividerClr),
                    ),

                    // ── Part 1: Immediate Action ──────────────────────────
                    Text(
                      '01 — IMMEDIATE ACTION',
                      style: AppTypography.monoCaption.copyWith(
                        color: textBlack.withValues(alpha: 0.55),
                        letterSpacing: 3,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      profile.immediateAction,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: textBlack,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Container(height: 1, color: dividerClr),
                    ),

                    // ── Part 2: Canadian Context ──────────────────────────
                    Text(
                      '02 — CANADIAN CONTEXT',
                      style: AppTypography.monoCaption.copyWith(
                        color: textBlack.withValues(alpha: 0.55),
                        letterSpacing: 3,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      profile.canadianContext,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: textBlack,
                        height: 1.6,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Container(height: 1, color: dividerClr),
                    ),

                    // ── Part 3: Escape Tab Status ─────────────────────────
                    Text(
                      '03 — WEEKEND ESCAPE STATUS',
                      style: AppTypography.monoCaption.copyWith(
                        color: textBlack.withValues(alpha: 0.55),
                        letterSpacing: 3,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _SheetStatusRow(
                      icon: Icons.directions_car,
                      label: 'HIGHWAY',
                      value: profile.escapeHighwayStatus.split(' — ').first,
                    ),
                    const SizedBox(height: 8),
                    _SheetStatusRow(
                      icon: Icons.park,
                      label: 'CAMPFIRE / OUTDOORS',
                      value: profile.escapeCampfireStatus.split(' — ').first,
                    ),
                    const SizedBox(height: 8),
                    _SheetStatusRow(
                      icon: Icons.deck,
                      label: 'PATIO INDEX',
                      value:
                          '${profile.escapePatioIndex}/10 — ${profile.escapePatioMessage.split('.').first}.',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _fullDayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekday >= 1 && weekday <= 7 ? names[weekday - 1] : '—';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEEKEND ANCHOR BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class WeekendAnchorBlock extends StatelessWidget {
  final List<TaggedDailyForecast> weekendDays;
  final String summary;

  const WeekendAnchorBlock({
    required this.weekendDays,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border:
            Border.all(color: _solarYellow.withValues(alpha: 0.35), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THE WEEKEND OUTLOOK',
            style: AppTypography.monoCaption.copyWith(
              color: _solarYellow,
              letterSpacing: 3,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.pureWhite,
              height: 1.5,
            ),
          ),
          if (weekendDays.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children:
                  weekendDays.map((t) => WeekendChip(tagged: t)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class WeekendChip extends StatelessWidget {
  final TaggedDailyForecast tagged;
  const WeekendChip({required this.tagged});

  @override
  Widget build(BuildContext context) {
    final isClear = tagged.profile.id == WeatherProfileId.primeSummerClear;
    final bg = isClear ? _solarYellow : const Color(0xFF1E1E1E);
    final fg = isClear ? _deepBlack : AppColors.pureWhite;
    final label = _shortDayLabel(tagged.forecast.date.weekday);
    final temp = '${tagged.forecast.tempMax.round()}°';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        '$label $temp',
        style: AppTypography.monoCaption.copyWith(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  static String _shortDayLabel(int weekday) {
    const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return weekday >= 1 && weekday <= 7 ? names[weekday - 1] : '—';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY ROW
// ─────────────────────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final TaggedDailyForecast tagged;
  final int index;
  final bool isLast;
  final VoidCallback onTap;

  const _DayRow({
    required this.tagged,
    required this.index,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final day = tagged.forecast;
    final profile = tagged.profile;
    final isToday = index == 0;

    // Tag colour based on profile severity
    Color tagBg;
    Color tagFg;
    if (tagged.isPrimeOutdoorDay) {
      tagBg = _solarYellow;
      tagFg = _deepBlack;
    } else if (profile.isExtremeHazard) {
      tagBg = const Color(0xFF1A0000);
      tagFg = const Color(0xFFFF3B30);
    } else {
      tagBg = const Color(0xFF1A1A1A);
      tagFg = const Color(0xFF00FF87);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isToday ? AppColors.glassWhite.withValues(alpha: 0.05) : Colors.transparent,
          border: !isLast
              ? Border(
                  bottom: BorderSide(color: AppColors.glassBorder, width: 1),
                )
              : null,
        ),
        child: Row(
          children: [
            // ── Day name ─────────────────────────────────────────────────
            SizedBox(
              width: 36,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _shortDay(day.date.weekday),
                    style: AppTypography.monoCaption.copyWith(
                      color: isToday ? _solarYellow : AppColors.pureWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  if (isToday)
                    Text(
                      'NOW',
                      style: AppTypography.monoCaption.copyWith(
                        color: _solarYellow.withValues(alpha: 0.6),
                        fontSize: 8,
                        letterSpacing: 1,
                      ),
                    ),
                ],
              ),
            ),

            // ── Weather icon ─────────────────────────────────────────────
            const SizedBox(width: 12),
            _wmoIconWidget(day.weatherCode, day.isSnowDay, day.isRainDay),

            // ── Temp range ───────────────────────────────────────────────
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              child: Text(
                '${day.tempMin.round()}° / ${day.tempMax.round()}°',
                style: AppTypography.monoCaption.copyWith(
                  color: AppColors.concreteGrey,
                  fontSize: 12,
                ),
              ),
            ),

            // ── Profile headline tag ─────────────────────────────────────
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    color: tagBg,
                    child: Text(
                      tagged.isPrimeOutdoorDay
                          ? 'PRIME TWO-FOUR DAY'
                          : _shortTag(profile),
                      style: AppTypography.monoCaption.copyWith(
                        color: tagFg,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Precip probability ────────────────────────────────────────
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${day.precipProbMax}%',
                  style: AppTypography.monoCaption.copyWith(
                    color: day.precipProbMax > 50
                        ? const Color(0xFFFF9F0A)
                        : AppColors.concreteGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(Icons.water_drop, color: AppColors.concreteGrey, size: 10),
              ],
            ),

            // ── Chevron ───────────────────────────────────────────────────
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF444444),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  static String _shortDay(int weekday) {
    const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return weekday >= 1 && weekday <= 7 ? names[weekday - 1] : '—';
  }

  static String _shortTag(WeatherProfile profile) {
    switch (profile.id) {
      case WeatherProfileId.galeWindstorm:
        return 'GALE PREP';
      case WeatherProfileId.shoulderFreezeThaw:
        return 'BLACK ICE RISK';
      case WeatherProfileId.wildfireSmokeHigh:
        return 'SMOKE HAZARD';
      case WeatherProfileId.deepWinterBlizzard:
        return 'BLIZZARD OPS';
      case WeatherProfileId.extremeHeatHumidex:
        return 'HUMIDEX VAULT';
      case WeatherProfileId.heavyRainDownpour:
        return 'HEAVY RAIN';
      case WeatherProfileId.primeSummerClear:
        return 'CLEAR SKIES';
      case WeatherProfileId.clearNightStarry:
        return 'STARLIGHT';
      default:
        return 'CLEAR SKIES';
    }
  }

  static Widget _wmoIconWidget(int code, bool isSnow, bool isRain) {
    if (isSnow) return _buildAnimatedIcon(Icons.ac_unit, Colors.white, shouldSpin: true);
    if (isRain) return _buildAnimatedIcon(Icons.water_drop, AppColors.concreteGrey, shouldBounce: true);
    if (code == 45 || code == 48) return _buildAnimatedIcon(Icons.cloudy_snowing, AppColors.concreteGrey);
    if (code >= 95) return _buildAnimatedIcon(Icons.flash_on, _solarYellow, shouldPulse: true);
    if (code >= 3) return _buildAnimatedIcon(Icons.cloud_rounded, AppColors.concreteGrey);
    if (code >= 1) return _buildAnimatedIcon(Icons.wb_cloudy_outlined, AppColors.concreteGrey);
    return _buildAnimatedIcon(Icons.wb_sunny_rounded, _solarYellow, shouldSpin: true);
  }

  static Widget _buildAnimatedIcon(IconData icon, Color color, {bool shouldSpin = false, bool shouldPulse = false, bool shouldBounce = false}) {
    // In a stateless widget, we can't easily use AnimationController without a Stateful wrapper.
    // For Stage 4 polish, we wrap in a local StatefulWidget to handle the animation.
    return _AnimatedWeatherIcon(
      icon: icon,
      color: color,
      shouldSpin: shouldSpin,
      shouldPulse: shouldPulse,
      shouldBounce: shouldBounce,
    );
  }
}

class _AnimatedWeatherIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool shouldSpin;
  final bool shouldPulse;
  final bool shouldBounce;

  const _AnimatedWeatherIcon({
    required this.icon,
    required this.color,
    this.shouldSpin = false,
    this.shouldPulse = false,
    this.shouldBounce = false,
  });

  @override
  State<_AnimatedWeatherIcon> createState() => _AnimatedWeatherIconState();
}

class _AnimatedWeatherIconState extends State<_AnimatedWeatherIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: widget.shouldPulse || widget.shouldBounce);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Icon(widget.icon, color: widget.color, size: 20);

    if (widget.shouldSpin) {
      return RotationTransition(
        turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
        child: child,
      );
    }
    
    if (widget.shouldPulse) {
      return FadeTransition(
        opacity: Tween(begin: 0.5, end: 1.0).animate(_controller),
        child: child,
      );
    }
    
    if (widget.shouldBounce) {
      return SlideTransition(
        position: Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.1)).animate(_controller),
        child: child,
      );
    }

    return child;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHEET STATUS ROW
// ─────────────────────────────────────────────────────────────────────────────

class _SheetStatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SheetStatusRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _solarYellow, size: 14),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.monoCaption.copyWith(
                  color: _deepBlack.withValues(alpha: 0.5),
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: _deepBlack,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
