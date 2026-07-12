import 'package:flutter/material.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/domain/matrix/weather_state_matrix.dart';
import 'package:weather_sync_ca/domain/usecases/weekly_forecasting_engine.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:weather_sync_ca/services/boreal_content_engine.dart';
import 'package:weather_sync_ca/presentation/widgets/redesign/bento_animations.dart';
import 'package:weather_sync_ca/services/live_weather_service.dart';
import 'package:weather_sync_ca/presentation/widgets/redesign/interactive_bento_cards.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/glass_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CAMPFIRE FWI STATE MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum _FireState { washout, highWind, subZero, ideal }

class _FireWeatherState {
  final _FireState state;
  final String header;
  final String advice;
  final List<_StatusBadge> badges;
  final Color headerColor;

  const _FireWeatherState({
    required this.state,
    required this.header,
    required this.advice,
    required this.badges,
    required this.headerColor,
  });
}

class _StatusBadge {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusBadge({required this.label, required this.bg, required this.fg});
}

// ─────────────────────────────────────────────────────────────────────────────
// BUG PRESSURE STATE
// ─────────────────────────────────────────────────────────────────────────────

enum _BugPressure { dormant, moderate, severe }

class _BugState {
  final _BugPressure level;
  final String label;
  final String advice;
  final Color color;

  const _BugState({
    required this.level,
    required this.label,
    required this.advice,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// FWI RESOLVER — Pure UI logic, consumes WeatherProfile & LiveWeatherData
// ─────────────────────────────────────────────────────────────────────────────

class _FwiResolver {
  /// Resolves fire weather state from live data + resolved WeatherProfile.
  /// The WeatherProfile already carries the simulation override so Dev Sim
  /// changes propagate automatically.
  static _FireWeatherState resolve({
    required WeatherProfile profile,
    required double maxPrecipPct,
    required double maxWindKmh,
    required double avgTempC,
  }) {
    // 1. Simulation ID baked into profile — check profile to determine state
    //    Priority order: washout > high-wind > sub-zero > ideal

    // Washout: rain sim or high precip probability or active rain profile
    final bool isWashout = maxPrecipPct >= 40 ||
        profile.id == WeatherProfileId.shoulderFreezeThaw ||
        profile.id == WeatherProfileId.heavyRainDownpour;

    // High wind: gale profile or weekend winds > 30 km/h
    final bool isHighWind =
        profile.id == WeatherProfileId.galeWindstorm || maxWindKmh > 30;

    // Sub-zero: blizzard profile or avg temp at or below 0°C
    final bool isSubZero =
        profile.id == WeatherProfileId.deepWinterBlizzard || avgTempC <= 0;

    // Smoke: wildfire smoke overrides campfire to banned
    final bool isSmoke = profile.id == WeatherProfileId.wildfireSmokeHigh;

    if (isSmoke) {
      // Reuse highWind state but with smoke-specific messaging
      return const _FireWeatherState(
        state: _FireState.highWind,
        header: 'WILDFIRE SMOKE: AIR QUALITY BAN',
        advice:
            'Active wildfire smoke plumes are in the regional corridor. Do not add wood smoke to already hazardous PM2.5 levels. All open fires are strongly discouraged until the AQHI drops below 3.',
        badges: [
          _StatusBadge(
              label: 'AQI BAN', bg: Color(0xFF1A0000), fg: Color(0xFFFF3B30)),
          _StatusBadge(
              label: 'NO OPEN FIRES',
              bg: Color(0xFF1A0000),
              fg: Color(0xFFFF3B30)),
          _StatusBadge(
              label: 'PM2.5 HAZARD',
              bg: Color(0xFF1A0000),
              fg: Color(0xFFFF3B30)),
        ],
        headerColor: Color(0xFFFF3B30),
      );
    }

    if (isWashout) {
      return const _FireWeatherState(
        state: _FireState.washout,
        header: 'PRECIPITATION ALERT: CAMPFIRE WASHOUT',
        advice:
            'Wet forest fuels and high humidity prevent clean ignition. Attempting a fire today will only produce noxious smoke without generating heat. Keep kindling covered under a tarp.',
        badges: [
          _StatusBadge(
              label: 'TARP WOOD', bg: Color(0xFF001A1A), fg: Color(0xFF00CFCF)),
          _StatusBadge(
              label: 'HIGH HUMIDITY',
              bg: Color(0xFF001A1A),
              fg: Color(0xFF00CFCF)),
          _StatusBadge(
              label: 'FIRE RISK: ZERO',
              bg: Color(0xFF1A0000),
              fg: Color(0xFFFF3B30)),
        ],
        headerColor: Color(0xFF00CFCF),
      );
    }

    if (isHighWind) {
      return const _FireWeatherState(
        state: _FireState.highWind,
        header: 'HIGH WIND WARNING: SPARK SPREAD HAZARD',
        advice:
            'Never build an open campfire during high winds. Flying embers can travel massive distances and ignite dry vegetation. Check municipal fire bans before lighting.',
        badges: [
          _StatusBadge(
              label: 'WIND EXTREME',
              bg: Color(0xFF1A0800),
              fg: Color(0xFFFF9F0A)),
          _StatusBadge(
              label: 'FIRE BAN CHECK',
              bg: Color(0xFF1A0800),
              fg: Color(0xFFFF9F0A)),
          _StatusBadge(
              label: 'EMBERS HAZARD',
              bg: Color(0xFF1A0000),
              fg: Color(0xFFFF3B30)),
        ],
        headerColor: Color(0xFFFF9F0A),
      );
    }

    if (isSubZero) {
      return const _FireWeatherState(
        state: _FireState.subZero,
        header: 'WINTER FIRE OPS: THERMAL SURVIVAL',
        advice:
            'Snow cover eliminates wildfire spread, but winter fires require clearing a 3-metre perimeter down to frozen dirt or rock. Elevate kindling off the damp snowpack to establish a coal bed.',
        badges: [
          _StatusBadge(
              label: 'CLEAR SNOW',
              bg: Color(0xFF001429),
              fg: Color(0xFF7EB8FF)),
          _StatusBadge(
              label: 'ELEVATE WOOD',
              bg: Color(0xFF001429),
              fg: Color(0xFF7EB8FF)),
          _StatusBadge(
              label: 'THERMAL COALS',
              bg: Color(0xFF001429),
              fg: Color(0xFF7EB8FF)),
        ],
        headerColor: Color(0xFF7EB8FF),
      );
    }

    // Ideal
    return const _FireWeatherState(
      state: _FireState.ideal,
      header: 'CLEAR OUTDOOR CONDITIONS: IDEAL CAMPFIRE',
      advice:
          'Low bug activity and manageable wind shear. Perfect evening conditions for a backyard fire pit or trail campsite. Ensure hardwoods are fully extinguished before sleeping.',
      badges: [
        _StatusBadge(
            label: 'DRY FUELS', bg: Color(0xFF001A08), fg: Color(0xFF00FF87)),
        _StatusBadge(
            label: 'LOW WIND', bg: Color(0xFF001A08), fg: Color(0xFF00FF87)),
        _StatusBadge(
            label: 'IDEAL BURN', bg: Color(0xFF001A08), fg: Color(0xFF00FF87)),
      ],
      headerColor: Color(0xFF00FF87),
    );
  }

  /// Bug pressure: driven by temperature and humidity from live data.
  static _BugState resolveBugs({
    required double avgTempC,
    required double humidity,
    required WeatherProfile profile,
  }) {
    // Blizzard/deep winter = dormant regardless
    if (profile.id == WeatherProfileId.deepWinterBlizzard || avgTempC < 10.0) {
      return const _BugState(
        level: _BugPressure.dormant,
        label: 'BUGS: DORMANT',
        advice:
            'Mosquitoes cannot fly in cold Canadian air. Enjoy the bug-free outdoors.',
        color: Color(0xFF00FF87),
      );
    }

    // High humidity + warm = severe
    if (avgTempC >= 15.0 && humidity >= 70.0) {
      return const _BugState(
        level: _BugPressure.severe,
        label: 'BUGS: SEVERE',
        advice:
            'Warm temps and high humidity create peak swarming conditions. Apply 30% DEET and use citronella perimeter torches.',
        color: Color(0xFFFF3B30),
      );
    }

    // Moderate
    return const _BugState(
      level: _BugPressure.moderate,
      label: 'BUGS: MODERATE',
      advice:
          'Bug activity present. Long sleeves and a light repellent recommended.',
      color: Color(0xFFFF9F0A),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GETAWAY TAB VIEW
// ─────────────────────────────────────────────────────────────────────────────

class GetawayTabView extends StatelessWidget {
  final LiveWeatherData? liveData;
  final WeatherProfile activeProfile;
  final String simulationId;

  const GetawayTabView({
    super.key,
    required this.liveData,
    required this.activeProfile,
    required this.simulationId,
  });

  @override
  Widget build(BuildContext context) {
    final dailyForecasts = liveData?.dailyForecasts ?? const [];
    final taggedWeek = WeeklyForecastingEngine.tagWeek(dailyForecasts);
    final weekendDays = taggedWeek.where((t) => t.isWeekend).toList();

    return Builder(
      builder: (context) {
        final patioIndex = BentoEntrance(
          delay: const Duration(milliseconds: 0),
          child: BentoFlipCard(
            front: _WeekendPatioIndexCard(
              weekendDays: weekendDays,
              activeProfile: activeProfile,
            ),
            back: _buildPatioBack(activeProfile, weekendDays),
          ),
        );

        final campfireFwi = BentoEntrance(
          delay: const Duration(milliseconds: 100),
          child: BentoFlipCard(
            front: _CampfireFwiCard(
              weekendDays: weekendDays,
              liveData: liveData,
              activeProfile: activeProfile,
            ),
            back: _buildCampfireBack(activeProfile, weekendDays, liveData),
          ),
        );

        final bugPressure = BentoEntrance(
          delay: const Duration(milliseconds: 200),
          child: SpringPressWrapper(
            child: _BugPressureCard(
              weekendDays: weekendDays,
              liveData: liveData,
              activeProfile: activeProfile,
            ),
          ),
        );

        final escapeManifest = BentoEntrance(
          delay: const Duration(milliseconds: 300),
          child: SpringPressWrapper(
            child: _AiEscapeManifestCard(
              activeProfile: activeProfile,
              liveData: liveData,
            ),
          ),
        );

        final highwayRadar = BentoEntrance(
          delay: const Duration(milliseconds: 400),
          child: SpringPressWrapper(
            child: _HighwayRadarCard(liveData: liveData),
          ),
        );

        Widget bodyContent;

        if (weekendDays.isEmpty && liveData == null) {
          bodyContent = const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Weekend forecast unavailable.',
              style: TextStyle(color: AppColors.concreteGrey),
            ),
          );
        } else {
          bodyContent = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              patioIndex,
              campfireFwi,
              bugPressure,
              escapeManifest,
              highwayRadar,
            ],
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  children: [
                    Text(
                      'THE GETAWAY ENGINE',
                      style: AppTypography.monoCaption.copyWith(
                        color: AppColors.concreteGrey,
                        letterSpacing: 2,
                      ),
                    ),
                    // Sim override badge
                    if (simulationId != 'LIVE') ...[
                      const SizedBox(width: 10),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        color: const Color(0xFFD4FF00),
                        child: Text(
                          '⚡ $simulationId',
                          style: const TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0A0A0A),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              bodyContent,
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatioBack(WeatherProfile activeProfile, List<TaggedDailyForecast> weekendDays) {
    return _BentoBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PATIO INDEX MATRIX',
                style: AppTypography.monoCaption
                    .copyWith(color: AppColors.concreteGrey, letterSpacing: 2),
              ),
              const Icon(Icons.analytics, color: Color(0xFFD4FF00), size: 18),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatRow('ALGORITHM', 'LIFESTYLE INDEX'),
          _buildStatRow('SCORE', '${activeProfile.escapePatioIndex} / 10'),
          _buildStatRow('WIND SHEAR PENALTY', weekendDays.any((d) => d.forecast.windMaxKmh > 30) ? 'ACTIVE' : 'NONE'),
          _buildStatRow('PRECIP DEBUFF', weekendDays.any((d) => d.forecast.precipProbMax > 40) ? 'ACTIVE' : 'NONE'),
        ],
      ),
    );
  }

  Widget _buildCampfireBack(WeatherProfile activeProfile, List<TaggedDailyForecast> weekendDays, LiveWeatherData? liveData) {
    final double maxPrecipPct = weekendDays.isEmpty
        ? (liveData?.precipitationProbabilityPct ?? 0)
        : weekendDays.fold<int>(0, (m, t) => t.forecast.precipProbMax > m ? t.forecast.precipProbMax : m).toDouble();

    final double maxWindKmh = weekendDays.isEmpty
        ? (liveData?.windGustKmh ?? 0)
        : weekendDays.fold<double>(0, (m, t) => t.forecast.windMaxKmh > m ? t.forecast.windMaxKmh : m);

    return _BentoBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FWI TELEMETRY',
                style: AppTypography.monoCaption
                    .copyWith(color: AppColors.concreteGrey, letterSpacing: 2),
              ),
              const Icon(Icons.science, color: Color(0xFF00F0FF), size: 18),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatRow('FWI ENGINE', 'BOREAL CORE'),
          _buildStatRow('PEAK WIND GUST', '${maxWindKmh.round()} KM/H'),
          _buildStatRow('SATURATION PROB', '${maxPrecipPct.round()}%'),
          _buildStatRow('MUNICIPAL OVERRIDE', activeProfile.id == WeatherProfileId.wildfireSmokeHigh ? 'SMOKE BAN' : 'BY-LAW DEPENDENT'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.concreteGrey),
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.pureWhite),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEEKEND PATIO & BBQ INDEX CARD
// ─────────────────────────────────────────────────────────────────────────────

class _WeekendPatioIndexCard extends StatelessWidget {
  final List<TaggedDailyForecast> weekendDays;
  final WeatherProfile activeProfile;

  const _WeekendPatioIndexCard({
    required this.weekendDays,
    required this.activeProfile,
  });

  @override
  Widget build(BuildContext context) {
    final double avgTemp = weekendDays.isEmpty
        ? 20.0
        : weekendDays.fold<double>(0, (s, t) => s + t.forecast.tempMax) /
            weekendDays.length;
    final int maxPrecip = weekendDays.isEmpty
        ? 0
        : weekendDays.fold<int>(
            0,
            (max, t) =>
                t.forecast.precipProbMax > max ? t.forecast.precipProbMax : max,
          );

    // Override status from resolved profile
    String status;
    Color color;
    String message;

    switch (activeProfile.id) {
      case WeatherProfileId.galeWindstorm:
        status = 'CANCELLED';
        color = const Color(0xFFFF3B30);
        message =
            'Gale force winds. Secure patio furniture and cancel any outdoor plans.';
        break;
      case WeatherProfileId.clearNightStarry:
        status = 'STARLIGHT';
        color = const Color(0xFF7EB8FF);
        message =
            'Clear night sky and crisp air. Great for a cozy firepit or stargazing.';
        break;
      case WeatherProfileId.wildfireSmokeHigh:
        status = 'SMOKE HAZARD';
        color = const Color(0xFFFF9F0A);
        message =
            'Wildfire smoke in the regional corridor. Outdoor dining strongly discouraged.';
        break;
      case WeatherProfileId.deepWinterBlizzard:
        status = 'SUSPENDED';
        color = const Color(0xFF7EB8FF);
        message = 'Deep winter conditions. Outdoor patio season suspended.';
        break;
      case WeatherProfileId.extremeHeatHumidex:
        status = 'SCORCHER';
        color = const Color(0xFFFF9F0A);
        message =
            'Peak humidex. Deploy umbrellas, hydrate, and avoid peak-sun hours.';
        break;
      case WeatherProfileId.heavyRainDownpour:
        status = 'WASHOUT';
        color = const Color(0xFFFF3B30);
        message =
            'It\'s a frog-strangler out there. Move the BBQ under the awning or stay indoors.';
        break;
      case WeatherProfileId.shoulderFreezeThaw:
        status = 'ICY / SLUSH';
        color = const Color(0xFF7EB8FF);
        message = 'Freeze-thaw cycle active. Outdoor surfaces treacherous.';
        break;
      case WeatherProfileId.primeSummerClear:
        if (maxPrecip > 60) {
          status = 'WASHOUT RISK';
          color = const Color(0xFFFF3B30);
          message = 'High rain probability. Have a solid indoor backup plan.';
        } else if (avgTemp < 15) {
          status = 'CHILLY';
          color = const Color(0xFFFF9F0A);
          message =
              'Bring layers. Evening patio sessions will require a heater.';
        } else if (avgTemp > 28) {
          status = 'SCORCHER';
          color = const Color(0xFFFF9F0A);
          message =
              'Peak heat. Hydrate and ensure patio umbrellas are deployed.';
        } else {
          status = 'GOOD';
          color = const Color(0xFF00FF87);
          message = 'Ideal conditions for extended patio and BBQ sessions.';
        }
        break;
      default:
        status = 'GOOD';
        color = const Color(0xFF00FF87);
        message = 'Ideal conditions for extended patio and BBQ sessions.';
        break;
    }

    return _BentoBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side: Icon + Big Status
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🥩', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right Side: Title + Message
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PATIO & BBQ INDEX',
                  style: AppTypography.monoCaption
                      .copyWith(color: AppColors.concreteGrey, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.pureWhite,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
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
// CAMPFIRE FWI GAUGE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _CampfireFwiCard extends StatelessWidget {
  final List<TaggedDailyForecast> weekendDays;
  final LiveWeatherData? liveData;
  final WeatherProfile activeProfile;

  const _CampfireFwiCard({
    required this.weekendDays,
    required this.liveData,
    required this.activeProfile,
  });

  @override
  Widget build(BuildContext context) {
    // Aggregate weekend metrics (fall back to live hourly if weekend empty)
    final double maxPrecipPct = weekendDays.isEmpty
        ? (liveData?.precipitationProbabilityPct ?? 0)
        : weekendDays
            .fold<int>(
                0,
                (m, t) =>
                    t.forecast.precipProbMax > m ? t.forecast.precipProbMax : m)
            .toDouble();

    final double maxWindKmh = weekendDays.isEmpty
        ? (liveData?.windGustKmh ?? 0)
        : weekendDays.fold<double>(
            0,
            (m, t) => t.forecast.windMaxKmh > m ? t.forecast.windMaxKmh : m,
          );

    final double avgTempC = weekendDays.isEmpty
        ? (liveData?.temperatureC ?? 10)
        : weekendDays.fold<double>(0, (s, t) => s + t.forecast.tempMax) /
            weekendDays.length;

    final fwi = _FwiResolver.resolve(
      profile: activeProfile,
      maxPrecipPct: maxPrecipPct,
      maxWindKmh: maxWindKmh,
      avgTempC: avgTempC,
    );

    return _BentoBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Icon + Badges
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: fwi.badges
                      .map((b) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            color: b.bg,
                            child: Text(
                              b.label,
                              style: AppTypography.monoCaption.copyWith(
                                color: b.fg,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right Side: Title + Header + Advice
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CAMPFIRE GAUGE',
                  style: AppTypography.monoCaption
                      .copyWith(color: AppColors.concreteGrey, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  fwi.header,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: fwi.headerColor,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  fwi.advice,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.pureWhite,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
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
// BUG PRESSURE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BugPressureCard extends StatelessWidget {
  final List<TaggedDailyForecast> weekendDays;
  final LiveWeatherData? liveData;
  final WeatherProfile activeProfile;

  const _BugPressureCard({
    required this.weekendDays,
    required this.liveData,
    required this.activeProfile,
  });

  @override
  Widget build(BuildContext context) {
    final double avgTempC = weekendDays.isEmpty
        ? (liveData?.temperatureC ?? 10)
        : weekendDays.fold<double>(0, (s, t) => s + t.forecast.tempMax) /
            weekendDays.length;
    final double humidity = liveData?.humidity ?? 50;

    final bug = _FwiResolver.resolveBugs(
      avgTempC: avgTempC,
      humidity: humidity,
      profile: activeProfile,
    );

    final Color cardAccent = bug.color;

    return _BentoBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Icon + Label + Level Pill
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🦟', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 16),
                Text(
                  bug.label,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: cardAccent,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: cardAccent.withValues(alpha: 0.12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: cardAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${avgTempC.round()}°C / ${humidity.round()}%',
                        style: AppTypography.monoCaption.copyWith(
                          color: cardAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right Side: Title + Advice
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MOSQUITO PRESSURE',
                  style: AppTypography.monoCaption
                      .copyWith(color: AppColors.concreteGrey, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  bug.advice,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.pureWhite,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
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
// HIGHWAY RADAR CARD
// ─────────────────────────────────────────────────────────────────────────────

class _HighwayRadarCard extends StatelessWidget {
  final LiveWeatherData? liveData;
  const _HighwayRadarCard({this.liveData});

  @override
  Widget build(BuildContext context) {
    return _BentoBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REGIONAL TRAVEL CORRIDORS',
                style: AppTypography.monoCaption
                    .copyWith(color: AppColors.concreteGrey, letterSpacing: 2),
              ),
              const Icon(Icons.commute, color: AppColors.pureWhite, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Hwy 400 & Cottage Routes',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.pureWhite,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check for active road closures, construction, and severe weather intercept zones before departing on your weekend getaway.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.concreteGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _Chameleon511Button(
            latitude: liveData?.latitude,
            longitude: liveData?.longitude,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BENTO BOX WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

class _BentoBox extends StatelessWidget {
  final Widget child;
  const _BentoBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      tint: AppColors.glassCyan,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAMELEON 511 ROUTING BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _Chameleon511Button extends StatelessWidget {
  final double? latitude;
  final double? longitude;

  const _Chameleon511Button({this.latitude, this.longitude});

  Future<void> _launch511() async {
    final lon = longitude ?? -79.3; // Default to Ontario
    Uri url;

    if (lon <= -115.0) {
      url = Uri.parse('https://www.drivebc.ca/');
    } else if (lon > -115.0 && lon <= -110.0) {
      url = Uri.parse('https://511.alberta.ca/');
    } else {
      url = Uri.parse('https://511on.ca/');
    }

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch \$url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lon = longitude ?? -79.3;
    String btnText;

    if (lon <= -115.0) {
      btnText = 'OPEN DriveBC';
    } else if (lon > -115.0 && lon <= -110.0) {
      btnText = 'OPEN ALBERTA 511';
    } else {
      btnText = 'OPEN ONTARIO 511';
    }

    return GestureDetector(
      onTap: _launch511,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Deep Slate
          border: Border.all(color: const Color(0xFF00F0FF), width: 2), // Cyber-Cyan
          borderRadius: BorderRadius.zero, // Sharp 90° corners
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF0A0A0A),
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.traffic_outlined, color: Color(0xFF00F0FF), size: 18),
            const SizedBox(width: 10),
            Text(
              btnText,
              style: AppTypography.monoCaption.copyWith(
                color: const Color(0xFF00F0FF),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.open_in_new, color: Color(0xFF00F0FF), size: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI ESCAPE MANIFEST CARD
// ─────────────────────────────────────────────────────────────────────────────

class _AiEscapeManifestCard extends StatefulWidget {
  final WeatherProfile activeProfile;
  final LiveWeatherData? liveData;

  const _AiEscapeManifestCard({required this.activeProfile, required this.liveData});

  @override
  State<_AiEscapeManifestCard> createState() => _AiEscapeManifestCardState();
}

class _AiEscapeManifestCardState extends State<_AiEscapeManifestCard> with SingleTickerProviderStateMixin {
  late AnimationController _borderController;
  late Animation<double> _borderOpacity;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _borderOpacity = Tween<double>(begin: 0.3, end: 1.0).animate(_borderController);
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mimic the telemetry mapping logic from today_tab_view
    double simTemp = widget.liveData?.temperatureC ?? 20.0;
    String simCond = widget.liveData?.conditionString ?? 'CLEAR';
    int simAqhi = widget.liveData?.uvIndex?.toInt() ?? 2; // rough approximation
    String simTimeOfDay = widget.liveData?.isDay == false ? 'Night' : 'Day';
    double simWindSpeed = widget.liveData?.windSpeedKmh ?? 10.0;
    double simWindGust = widget.liveData?.windGustKmh ?? 15.0;
    double simHumidex = widget.liveData?.apparentTempC ?? 20.0;
    double simPrecipProb = widget.liveData?.precipitationProbabilityPct?.toDouble() ?? 0.0;
    double simExpectedRain = widget.liveData?.rainMm ?? 0.0;
    double simSnowfall = widget.liveData?.snowfallCm ?? 0.0;

    if (widget.activeProfile.id == WeatherProfileId.extremeHeatHumidex) {
      simTemp = 35.0;
      simHumidex = 42.0;
    } else if (widget.activeProfile.id == WeatherProfileId.deepWinterBlizzard) {
      simTemp = -28.0;
      simCond = 'BLIZZARD';
    } else if (widget.activeProfile.id == WeatherProfileId.heavyRainDownpour) {
      simCond = 'RAIN';
      simExpectedRain = 25.0;
      simPrecipProb = 100.0;
    } else if (widget.activeProfile.id == WeatherProfileId.wildfireSmokeHigh) {
      simAqhi = 10;
    } else if (widget.activeProfile.id == WeatherProfileId.galeWindstorm) {
      simWindSpeed = 60.0;
      simWindGust = 90.0;
    } else if (widget.activeProfile.id == WeatherProfileId.clearNightStarry) {
      simCond = 'CLEAR';
      simTimeOfDay = 'Night';
    }

    final canadianIntelFuture = BorealContentEngine.getCanadianIntel(
      latitude: widget.liveData?.latitude ?? 43.6532,
      longitude: widget.liveData?.longitude ?? -79.3832,
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
      activeProfileId: widget.activeProfile.id.name,
    );

    return FutureBuilder<CanadianIntelPayload>(
      future: canadianIntelFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        
        if (!isLoading && snapshot.hasData) {
          _borderController.forward(from: 0.0);
        } else if (isLoading) {
          _borderController.reset();
        }

        return AnimatedBuilder(
          animation: _borderController,
          builder: (context, child) {
            return GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(24),
              tint: AppColors.glassCyan,
              child: child!,
            );
          },
          child: isLoading 
              ? const Center(
                  child: Text(
                    '[ DECRYPTING PRE-FLIGHT MANIFEST... ]',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      color: Color(0xFFD4FF00),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRE-FLIGHT MANIFEST',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        color: const Color(0xFFD4FF00).withValues(alpha: 0.8),
                        letterSpacing: 2,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    _SwipeableManifestList(
                      manifestRaw: snapshot.data?.escapeManifest ?? '',
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: const Color(0xFFD4FF00).withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'ROAD TRIP TRANSLATOR',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.8),
                        letterSpacing: 2,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TeletypeText(
                      snapshot.data?.roadTripSlang ?? '',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: Color(0xFF00F0FF),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _SwipeableManifestList extends StatefulWidget {
  final String manifestRaw;
  const _SwipeableManifestList({required this.manifestRaw});

  @override
  State<_SwipeableManifestList> createState() => _SwipeableManifestListState();
}

class _SwipeableManifestListState extends State<_SwipeableManifestList> {
  late List<String> items;

  @override
  void initState() {
    super.initState();
    _parseItems();
  }

  @override
  void didUpdateWidget(covariant _SwipeableManifestList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.manifestRaw != widget.manifestRaw) {
      _parseItems();
    }
  }

  void _parseItems() {
    items = widget.manifestRaw
        .split('\n')
        .map((e) => e.replaceAll('•', '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items.map((line) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Dismissible(
            key: ValueKey(line),
            direction: DismissDirection.horizontal,
            onDismissed: (_) {
              setState(() {
                items.remove(line);
              });
            },
            background: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD4FF00),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.check, color: Color(0xFF0A0A0A)),
            ),
            secondaryBackground: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD4FF00),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.check, color: Color(0xFF0A0A0A)),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E), // Slightly lighter than bento bg
                border: Border.all(color: const Color(0xFFD4FF00).withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.drag_indicator, color: Color(0xFF555555), size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.pureWhite,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

