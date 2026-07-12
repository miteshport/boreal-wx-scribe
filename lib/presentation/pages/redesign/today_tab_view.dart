import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/domain/matrix/weather_state_matrix.dart';
import 'package:weather_sync_ca/domain/usecases/activity_scoring_engine.dart';
import 'package:weather_sync_ca/domain/usecases/weekly_forecasting_engine.dart';
import 'package:weather_sync_ca/presentation/widgets/redesign/bento_animations.dart';
import 'package:weather_sync_ca/presentation/widgets/redesign/bento_control_center.dart';
import 'package:weather_sync_ca/presentation/widgets/redesign/sun_flip_card.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/aqhi_smoke_drift_card.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/glass_card.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/hourly_timeline_widget.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/weekly_canadian_planner_card.dart';
import 'package:weather_sync_ca/services/air_quality_service.dart';
import 'package:weather_sync_ca/services/live_weather_service.dart';
import 'package:weather_sync_ca/services/boreal_content_engine.dart';
import 'package:weather_sync_ca/presentation/widgets/redesign/tactical_briefing_modal.dart';
import 'package:weather_sync_ca/core/settings/app_settings_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TODAY TAB VIEW — Stage 6 Glass Redesign
// ─────────────────────────────────────────────────────────────────────────────

class TodayTabView extends StatelessWidget {
  final LiveWeatherData? liveData;
  final AirQualityData? airQuality;
  final WeatherProfile activeProfile;
  final List<ActivityScore> activityScores;
  final VoidCallback? onNavigateToGetaway;

  const TodayTabView({
    super.key,
    required this.liveData,
    this.airQuality,
    required this.activeProfile,
    required this.activityScores,
    this.onNavigateToGetaway,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettingsController.instance,
      builder: (context, _) {
        final settings = AppSettingsController.instance;
        final filteredScores = settings.filterScores(activityScores);

        double simTemp = liveData?.temperatureC ?? 15.0;
        String simCond = liveData?.conditionString ?? 'CLEAR';
        int simAqhi = airQuality?.aqhiDisplay ?? 1;
        String simTimeOfDay = liveData?.timeOfDayString ?? 'Day';

        double simWindSpeed = liveData?.windSpeedKmh ?? 10.0;
        double simWindGust = liveData?.windGustKmh ?? 15.0;
        double simHumidex = liveData?.humidex ?? 15.0;
        double simPrecipProb = liveData?.precipitationProbabilityPct ?? 0.0;
        double simExpectedRain = liveData?.precipitationMm ?? 0.0;
        double simSnowfall = liveData?.snowfallCm ?? 0.0;

        if (activeProfile.id == WeatherProfileId.galeWindstorm) {
          simWindSpeed = 50.0;
          simWindGust = 80.0;
          simCond = 'WINDSTORM';
        } else if (activeProfile.id == WeatherProfileId.wildfireSmokeHigh) {
          simAqhi = 10;
        } else if (activeProfile.id == WeatherProfileId.shoulderFreezeThaw) {
          simTemp = 0.0;
          simCond = 'FREEZING RAIN';
        } else if (activeProfile.id == WeatherProfileId.deepWinterBlizzard) {
          simTemp = -26.0;
          simSnowfall = 10.0;
          simWindGust = 70.0;
          simCond = 'BLIZZARD';
        } else if (activeProfile.id == WeatherProfileId.extremeHeatHumidex) {
          simTemp = 32.0;
          simHumidex = 42.0;
        } else if (activeProfile.id == WeatherProfileId.heavyRainDownpour) {
          simPrecipProb = 90.0;
          simExpectedRain = 5.0;
          simCond = 'HEAVY RAIN';
        } else if (activeProfile.id == WeatherProfileId.clearNightStarry) {
          simCond = 'CLEAR';
          simTimeOfDay = 'Night';
        }

        final canadianIntelFuture = BorealContentEngine.getCanadianIntel(
          latitude: liveData?.latitude ?? 43.6532,
          longitude: liveData?.longitude ?? -79.3832,
          temperature: simTemp,
          condition: simCond,
          aqhi: simAqhi,
          month: DateTime.now().month,
          isWeekend: DateTime.now().weekday >= 6,
          timeOfDay: simTimeOfDay,
          windSpeed: simWindSpeed,
          windGust: simWindGust,
          humidex: simHumidex,
          precipitationProbability: simPrecipProb,
          expectedRainfall: simExpectedRain,
          snowfallAccumulation: simSnowfall,
          activeProfileId: activeProfile.id.name,
        );

        return FutureBuilder<CanadianIntelPayload>(
          future: canadianIntelFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final intel = snapshot.data;

            // ── Box 1: Glass Hero Card ────────────────────────────────────────
            final box1 = BentoEntrance(
              delay: const Duration(milliseconds: 0),
              child: _GlassHeroCard(
                liveData: liveData,
                settings: settings,
                intel: intel,
                isLoading: isLoading,
              ),
            );

            // ── Canadian Survival Guide Card ──────────────────────────────────
            final survivalCard = BentoEntrance(
              delay: const Duration(milliseconds: 80),
              child: _GlassSurvivalGuideCard(
                intel: intel,
                isLoading: isLoading,
              ),
            );

            // ── Box 2: The Horizon — 7-Day Planner ───────────────────────────
            Widget box2 = const SizedBox.shrink();
            Widget weekendAnchorBlock = const SizedBox.shrink();
            if (liveData?.dailyForecasts.isNotEmpty ?? false) {
              final dailyForecasts = liveData!.dailyForecasts;
              final taggedWeek =
                  WeeklyForecastingEngine.tagWeek(dailyForecasts);
              final weekendDays =
                  taggedWeek.where((t) => t.isWeekend).toList();
              final weekendSummary =
                  WeeklyForecastingEngine.generateWeekendSummary(weekendDays);

              if (weekendDays.isNotEmpty) {
                weekendAnchorBlock = WeekendAnchorBlock(
                  weekendDays: weekendDays,
                  summary: weekendSummary,
                );
              }

              box2 = BentoEntrance(
                delay: const Duration(milliseconds: 150),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: WeeklyCanadianPlannerCard(
                      taggedWeek: taggedWeek,
                      weekendSummary: weekendSummary,
                    ),
                  ),
                ),
              );
            }

            // ── Box 3: Activity Carousel ──────────────────────────────────────
            final activityCarousel = filteredScores.isNotEmpty
                ? BentoEntrance(
                    delay: const Duration(milliseconds: 220),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: _ActivityCarouselCard(scores: filteredScores),
                    ),
                  )
                : const SizedBox.shrink();

            // ── Box 4: AQHI + Sun (2-col row) ────────────────────────────────
            final aqhiCard = liveData != null && airQuality != null
                ? AqhiSmokeDriftCard(
                    aq: airQuality!,
                    weather: liveData!,
                  )
                : const SizedBox.shrink();

            final sunCard = SunFlipCard(liveData: liveData);

            final box4 = BentoEntrance(
              delay: const Duration(milliseconds: 300),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: aqhiCard),
                      const SizedBox(width: 12),
                      Expanded(child: sunCard),
                    ],
                  ),
                ),
              ),
            );

            // ── Box 5: Weekend Anchor ─────────────────────────────────────────
            final box5 = weekendAnchorBlock is! SizedBox
                ? BentoEntrance(
                    delay: const Duration(milliseconds: 380),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: GlassCard(
                        padding: EdgeInsets.zero,
                        child: weekendAnchorBlock,
                      ),
                    ),
                  )
                : const SizedBox.shrink();

            // ── Box 6: Radar Mini-Map ─────────────────────────────────────────
            final box6 = BentoEntrance(
              delay: const Duration(milliseconds: 440),
              child: _RadarMiniMapCard(liveData: liveData),
            );

            // ── The Layout Scaffolding ────────────────────────────────────────
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      box1,
                      survivalCard,
                      box2,
                      activityCarousel,
                      box4,
                      box5,
                      box6,
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS HERO CARD (Box 1)
// ─────────────────────────────────────────────────────────────────────────────

class _GlassHeroCard extends StatelessWidget {
  final LiveWeatherData? liveData;
  final AppSettingsController settings;
  final CanadianIntelPayload? intel;
  final bool isLoading;

  const _GlassHeroCard({
    required this.liveData,
    required this.settings,
    this.intel,
    this.isLoading = false,
  });

  IconData _weatherIcon(String? condition) {
    if (condition == null) return Icons.wb_sunny_outlined;
    final c = condition.toUpperCase();
    if (c.contains('SNOW') || c.contains('BLIZZARD')) return Icons.ac_unit;
    if (c.contains('RAIN') || c.contains('DRIZZLE')) return Icons.water_drop;
    if (c.contains('THUNDER') || c.contains('STORM')) return Icons.thunderstorm;
    if (c.contains('WIND')) return Icons.air;
    if (c.contains('FOG') || c.contains('MIST')) return Icons.foggy;
    if (c.contains('CLOUD') || c.contains('OVERCAST')) return Icons.cloud;
    if (c.contains('NIGHT') || c.contains('CLEAR')) return Icons.nights_stay;
    return Icons.wb_sunny;
  }

  @override
  Widget build(BuildContext context) {
    final tempStr = liveData != null
        ? settings.formatTemp(liveData!.temperatureC, showUnit: false)
        : '--';
    final unitLabel = settings.useFahrenheit ? '°F' : '°C';
    final condStr = liveData?.conditionString ?? 'CLEAR';
    final humidexStr = liveData?.humidex != null
        ? 'Feels ${settings.formatTemp(liveData!.humidex!)}'
        : '';
    final hiStr = liveData?.dailyForecasts.isNotEmpty == true
        ? settings.formatTemp(liveData!.dailyForecasts.first.tempMax)
        : '--';
    final loStr = liveData?.dailyForecasts.isNotEmpty == true
        ? settings.formatTemp(liveData!.dailyForecasts.first.tempMin)
        : '--';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Row: temp + condition art ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: temp block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              tempStr,
                              style: const TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 72,
                                fontWeight: FontWeight.w900,
                                color: AppColors.pureWhite,
                                letterSpacing: -3,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              unitLabel,
                              style: const TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 22,
                                color: AppColors.concreteGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          condStr.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pureWhite,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (humidexStr.isNotEmpty)
                          Text(
                            humidexStr,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.concreteGrey,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          '↑$hiStr  ↓$loStr',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.concreteGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right: condition icon + settings
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => showBentoControlCenter(context),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.concreteGrey,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Icon(
                        _weatherIcon(liveData?.conditionString),
                        size: 72,
                        color: AppColors.pureWhite.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Tactical Warning banner ──
            if (!isLoading && intel?.slangHeadline != null) ...[
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4FF00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFD4FF00).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFD4FF00), size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        intel!.slangHeadline,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          color: Color(0xFFD4FF00),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // ── Hourly Timeline Strip ──
            if (liveData != null && liveData!.hourlyForecasts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: AppColors.glassBorder,
              ),
              const SizedBox(height: 12),
              HourlyTimelineSection(
                data: liveData!,
                isCelsius: !settings.useFahrenheit,
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS SURVIVAL GUIDE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _GlassSurvivalGuideCard extends StatelessWidget {
  final CanadianIntelPayload? intel;
  final bool isLoading;

  const _GlassSurvivalGuideCard({this.intel, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GlassCard(
        tint: AppColors.glassCyan,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined,
                    color: Color(0xFF00F0FF), size: 16),
                const SizedBox(width: 10),
                Text(
                  'CANADIAN SURVIVAL GUIDE',
                  style: AppTypography.monoCaption.copyWith(
                    color: const Color(0xFF00F0FF),
                    letterSpacing: 2,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isLoading
                  ? 'Establishing uplink...'
                  : (intel?.lifestyleActivity ??
                      'Active Cargo Uplink Verified // Route Intercept Status Nominal'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.pureWhite,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: _CyberCyanButton(intel: intel),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CYBER-CYAN BUTTON (scale tap animation)
// ─────────────────────────────────────────────────────────────────────────────

class _CyberCyanButton extends StatefulWidget {
  final CanadianIntelPayload? intel;
  const _CyberCyanButton({this.intel});

  @override
  State<_CyberCyanButton> createState() => _CyberCyanButtonState();
}

class _CyberCyanButtonState extends State<_CyberCyanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) => _controller.forward();
  void _handleTapUp(TapUpDetails _) {
    _controller.reverse();
    TacticalBriefingModal.show(context, widget.intel);
  }
  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF00F0FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '[ FULL BRIEFING  ➔ ]',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0A0A0A),
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY CAROUSEL CARD (Phase D — replaces PlanYourDayBadges grid)
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityCarouselCard extends StatefulWidget {
  final List<ActivityScore> scores;
  const _ActivityCarouselCard({required this.scores});

  @override
  State<_ActivityCarouselCard> createState() => _ActivityCarouselCardState();
}

class _ActivityCarouselCardState extends State<_ActivityCarouselCard>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Scale animation for the activity icon on page arrival
  late AnimationController _iconController;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );
    _iconScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _iconController.forward(from: 0.0);
  }

  Color _statusColor(ActivityStatus status) => switch (status) {
        ActivityStatus.good => const Color(0xFF00FF87),
        ActivityStatus.fair => const Color(0xFFFF9F0A),
        ActivityStatus.poor || ActivityStatus.hazardous => const Color(0xFFFF3B30),
      };

  String _statusLabel(ActivityStatus status) => switch (status) {
        ActivityStatus.good => 'PRIME',
        ActivityStatus.fair => 'FAIR',
        ActivityStatus.poor => 'POOR',
        ActivityStatus.hazardous => 'HAZARDOUS',
      };

  String _statusSubtitle(ActivityScore score) {
    final label = _statusLabel(score.status);
    switch (score.status) {
      case ActivityStatus.good:
        return 'Great conditions for ${score.title.toLowerCase()} today';
      case ActivityStatus.fair:
        return 'Marginal conditions — monitor weather closely';
      case ActivityStatus.poor:
      case ActivityStatus.hazardous:
        return 'Not recommended — weather conditions are unfavourable';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scores = widget.scores;
    if (scores.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 148,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              itemCount: scores.length,
              itemBuilder: (context, index) {
                final score = scores[index];
                final color = _statusColor(score.status);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: icon + label
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ScaleTransition(
                            scale: _iconScale,
                            child: Icon(score.icon,
                                size: 40,
                                color:
                                    AppColors.pureWhite.withValues(alpha: 0.9)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _statusLabel(score.status),
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: color,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            score.title.toUpperCase(),
                            style: AppTypography.monoCaption.copyWith(
                              color: AppColors.concreteGrey,
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Right: multi-day chips
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3 && i < scores.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _DayChip(
                                day: ['Today', 'Tmrw', 'Wed'][i],
                                status: scores[(index + i) % scores.length].status,
                                statusColor: _statusColor(
                                    scores[(index + i) % scores.length].status),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Subtitle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              _statusSubtitle(scores[_currentPage]),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.concreteGrey,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Page dots
          Padding(
            padding: const EdgeInsets.only(bottom: 14, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(scores.length, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.pureWhite
                        : AppColors.concreteGrey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String day;
  final ActivityStatus status;
  final Color statusColor;

  const _DayChip({
    required this.day,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          day,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.concreteGrey,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RADAR MINI-MAP CARD (Phase F)
// ─────────────────────────────────────────────────────────────────────────────

class _RadarMiniMapCard extends StatelessWidget {
  final LiveWeatherData? liveData;
  const _RadarMiniMapCard({this.liveData});

  Future<void> _launchECCC() async {
    final lat = liveData?.latitude;
    final lon = liveData?.longitude;
    final Uri uri;
    if (lat != null && lon != null) {
      uri = Uri.parse(
        'https://weather.gc.ca/en/location/index.html?coords=${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}',
      );
    } else {
      uri = Uri.parse('https://weather.gc.ca');
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch ECCC URL: $uri');
    }
  }

  String _radarUrl() {
    final lat = liveData?.latitude ?? 44.18;
    final lon = liveData?.longitude ?? -80.38;
    final minLat = lat - 3.5;
    final maxLat = lat + 3.5;
    final minLon = lon - 6.0;
    final maxLon = lon + 6.0;
    return 'https://geo.weather.gc.ca/geomet?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap'
        '&BBOX=$minLat,$minLon,$maxLat,$maxLon'
        '&WIDTH=400&HEIGHT=200&LAYERS=RADAR_1KM_RSNO'
        '&FORMAT=image/png&CRS=EPSG:4326';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: _launchECCC,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ENVIRONMENT CANADA — LIVE RADAR',
                      style: AppTypography.monoCaption.copyWith(
                        color: const Color(0xFFD4FF00).withValues(alpha: 0.7),
                        fontSize: 9,
                        letterSpacing: 2,
                      ),
                    ),
                    const Icon(Icons.open_in_new,
                        color: AppColors.concreteGrey, size: 14),
                  ],
                ),
              ),
              // Radar image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                child: Image.network(
                  _radarUrl(),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: AppColors.glassDark,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.radar_rounded,
                                color: AppColors.concreteGrey, size: 32),
                            SizedBox(height: 8),
                            Text(
                              'LOADING RADAR...',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 10,
                                color: AppColors.concreteGrey,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: AppColors.glassDark,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.radar_rounded,
                              color: AppColors.concreteGrey, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'TAP FOR LIVE RADAR →',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              color: AppColors.concreteGrey,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMOB BANNER WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

class AdmobBannerWrapper extends StatefulWidget {
  const AdmobBannerWrapper({super.key});

  @override
  State<AdmobBannerWrapper> createState() => _AdmobBannerWrapperState();
}

class _AdmobBannerWrapperState extends State<AdmobBannerWrapper> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Ad failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return Container(
        height: 52,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: AppColors.glassDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Center(
          child: Text(
            'SPONSORED CONTENT',
            style: AppTypography.monoCaption.copyWith(
              color: AppColors.concreteGrey,
              letterSpacing: 2,
              fontSize: 9,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
