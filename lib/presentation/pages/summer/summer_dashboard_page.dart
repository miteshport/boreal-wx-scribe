/// summer_dashboard_page.dart
///
/// Editorial Deck — Summer Mode (v5)
/// ─────────────────────────────────────────────────────────────────────────
/// v5 additions (7-Stage Canvas wiring fix):
///   - _SimPreset extended with: aqhi, windGustKmh, isFreezethaw
///   - canvasMode now maps ALL 7 WeatherAnimationMode values:
///       snow, rain, wildfire, severeWind, slush, summerDay, clearNight
///   - 3 new Sim Bar presets: SMOKE (wildfire), WIND (severeWind), SLUSH
///   - Canvas Opacity driven by NeoBrutalistWeatherCanvas.suggestedOpacity()
///   - CanadianAdviceParams passes aqhi, windGustKmh, isFreezethaw to engine
///   - HeroTempBlock labels + accent colors updated for all 7 states
library summer_dashboard_page;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/domain/usecases/activity_scoring_engine.dart';
import 'package:weather_sync_ca/domain/usecases/canadian_advice_engine.dart';
import 'package:weather_sync_ca/presentation/pages/summer/escape_dashboard_view.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/actionable_chore_card.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/admob_banner_widget.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/canadian_notification_overlay.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/floating_capsule_nav.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/neo_brutalist_weather_canvas.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/plan_your_day_widget.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/hourly_timeline_widget.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/settings_drawer.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/exact_alarm_onboarding_card.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/sunset_thermal_snap_card.dart';
import 'package:weather_sync_ca/services/air_quality_service.dart';
import 'package:weather_sync_ca/services/canadian_notification_engine.dart';
import 'package:weather_sync_ca/services/live_weather_service.dart';
import 'package:weather_sync_ca/services/notification_service.dart';
import 'package:weather_sync_ca/services/widget_sync_service.dart';
import 'package:weather_sync_ca/domain/usecases/notification_scheduler.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/aqhi_smoke_drift_card.dart';
import 'package:weather_sync_ca/domain/matrix/weather_state_matrix.dart';
import 'package:weather_sync_ca/domain/usecases/weekly_forecasting_engine.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/weekly_canadian_planner_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SIMULATION PRESETS
// ─────────────────────────────────────────────────────────────────────────────

class _SimPreset {
  const _SimPreset({
    required this.id,
    required this.label,
    required this.tempC,
    required this.snowCm,
    required this.isSnowing,
    required this.hour,
    required this.windKmh,
    required this.precipChance,
    required this.humidity,
    required this.recentRainMm,
    // ── Phase 7 extreme-weather fields ─────────────────────────────────
    this.aqhi = 0.0,
    this.windGustKmh = 0.0,
    this.isFreezethaw = false,
  });

  final String id;
  final String label;
  final double tempC;
  final double snowCm;
  final bool isSnowing;
  final int hour;
  final double windKmh;
  final double precipChance;
  final double humidity;
  final double recentRainMm;

  /// Air Quality Health Index (0 = excellent, 7+ = hazardous).
  final double aqhi;

  /// Maximum wind gust speed in km/h.
  final double windGustKmh;

  /// True during spring/fall freeze-thaw / pothole / slush conditions.
  final bool isFreezethaw;

  // ── Derived helpers ───────────────────────────────────────────────────────

  /// Active rainfall: >70% precip chance and not snowing.
  bool get isRaining => precipChance > 70 && !isSnowing;

  /// Fog: very high humidity + significant precip chance.
  bool get isFoggy => humidity > 86 && precipChance > 50;

  /// Escape tab: pivot to indoor mode when actively raining.
  bool get isRainingWeekend => isRaining;

  /// ── THE KEY FIX: canvasMode now covers all 7 atmospheric states ─────────
  ///
  /// Priority order:
  ///   1. Snow (precipitation type takes priority)
  ///   2. Rain (active liquid precipitation)
  ///   3. Wildfire smoke (AQHI > 6)
  ///   4. Severe wind (gusts > 70 km/h)
  ///   5. Freeze-thaw / slush (shoulder season)
  ///   6. Summer day peak (hot daytime hours)
  ///   7. Clear night (late evening / night hours)
  ///   null → no canvas (mild, clear, daytime)
  WeatherAnimationMode? get canvasMode {
    if (isSnowing)            return WeatherAnimationMode.snow;
    if (isRaining)            return WeatherAnimationMode.rain;
    if (aqhi > 6.0)           { return WeatherAnimationMode.wildfire; }
    if (windGustKmh > 70.0)   { return WeatherAnimationMode.severeWind; }
    if (isFreezethaw)         { return WeatherAnimationMode.slush; }
    if (tempC > 24.0 && hour >= 10 && hour < 18) {
      return WeatherAnimationMode.summerDay;
    }
    if (hour >= 21 || hour < 5) {
      return WeatherAnimationMode.clearNight;
    }
    return null;
  }
}

// All 7 presets map 1-to-1 with the 7 WeatherAnimationMode values.
// canvasMode is computed automatically from each preset's field values.
const _simPresets = [
  // ── Mode: summerDay — Thermic Convection Shimmer ──────────────────────
  _SimPreset(
    id: 'PEAK',
    label: '☀️  28° PEAK',
    tempC: 28.0,
    snowCm: 0.0,
    isSnowing: false,
    hour: 14,           // 10–18 + tempC > 24 → summerDay
    windKmh: 10.0,
    precipChance: 5.0,
    humidity: 52.0,
    recentRainMm: 0.0,
  ),
  // ── Mode: clearNight — Crosshair Constellation ───────────────────────
  _SimPreset(
    id: 'FLUSH',
    label: '🌙  18° NIGHT FLUSH',
    tempC: 18.0,
    snowCm: 0.0,
    isSnowing: false,
    hour: 21,           // hour >= 21 → clearNight
    windKmh: 7.0,
    precipChance: 8.0,
    humidity: 68.0,
    recentRainMm: 4.5,
  ),
  // ── Mode: rain — Vector Slash Blades ─────────────────────────────────
  _SimPreset(
    id: 'RAIN',
    label: '🌧️  12° HEAVY RAIN',
    tempC: 12.0,
    snowCm: 0.0,
    isSnowing: false,
    hour: 15,
    windKmh: 22.0,
    precipChance: 92.0, // > 70 → isRaining → rain canvas
    humidity: 91.0,
    recentRainMm: 18.0,
  ),
  // ── Mode: snow — Geometric Drifting Matrix ────────────────────────────
  _SimPreset(
    id: 'STORM',
    label: '❄️  -15° SNOWSTORM',
    tempC: -15.0,
    snowCm: 12.0,
    isSnowing: true,    // isSnowing → snow canvas
    hour: 8,
    windKmh: 38.0,
    precipChance: 88.0,
    humidity: 82.0,
    recentRainMm: 0.0,
  ),
  // ── Mode: wildfire — Particulate Smog Shader ─────────────────────────
  _SimPreset(
    id: 'SMOKE',
    label: '🔥  29° SMOKE ALERT',
    tempC: 29.0,
    snowCm: 0.0,
    isSnowing: false,
    hour: 13,
    windKmh: 12.0,
    precipChance: 0.0,
    humidity: 33.0,
    recentRainMm: 0.0,
    aqhi: 8.5,          // > 6 → wildfire canvas
  ),
  // ── Mode: severeWind — Kinetic Streamline Warp ───────────────────────
  _SimPreset(
    id: 'WIND',
    label: '⚡  WINDSTORM 95 KM/H',
    tempC: 16.0,
    snowCm: 0.0,
    isSnowing: false,
    hour: 17,
    windKmh: 65.0,
    precipChance: 18.0,
    humidity: 60.0,
    recentRainMm: 0.0,
    windGustKmh: 95.0,  // > 70 → severeWind canvas
  ),
  // ── Mode: slush — Dithered Overcast Halftone Grid ────────────────────
  _SimPreset(
    id: 'SLUSH',
    label: '🚙  2° FREEZE-THAW',
    tempC: 2.0,
    snowCm: 3.0,
    isSnowing: false,
    hour: 10,
    windKmh: 18.0,
    precipChance: 35.0,
    humidity: 78.0,
    recentRainMm: 5.0,
    isFreezethaw: true, // → slush canvas
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class SummerDashboardPage extends StatefulWidget {
  const SummerDashboardPage({super.key});

  @override
  State<SummerDashboardPage> createState() => _SummerDashboardPageState();
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCENT COLOR HELPER
// Returns the editorial accent color for each atmospheric mode.
// Used by: canvas accent divider, HeroTempBlock label, status dot.
// ─────────────────────────────────────────────────────────────────────────────

Color _accentColorForMode(WeatherAnimationMode? mode) {
  return switch (mode) {
    WeatherAnimationMode.snow        => const Color(0xFF00F0FF), // Ice cyan
    WeatherAnimationMode.rain        => const Color(0xFF00F0FF), // Rain cyan
    WeatherAnimationMode.clearNight  => const Color(0xFF00F0FF), // Night cyan
    WeatherAnimationMode.wildfire    => const Color(0xFFFF6B35), // Smoke orange
    WeatherAnimationMode.severeWind  => const Color(0xFFFFFFFF), // Wind white
    WeatherAnimationMode.slush       => const Color(0xFF8899AA), // Overcast grey
    WeatherAnimationMode.summerDay   => const Color(0xFFE6FF00), // Solar yellow
    null                             => const Color(0xFFE6FF00), // Default yellow
  };
}

class _SummerDashboardPageState extends State<SummerDashboardPage> {
  // ── Advice engine ─────────────────────────────────────────────────────────
  CanadianAdviceEngine? _engine;
  List<AdviceResult> _cachedAdvice = [];
  List<ActivityScore> _activityScores = [];
  WeatherProfile _activeProfile = WeatherStateMatrix.primeSummerClear;
  bool _engineReady = false;

  // ── Sim preset (drives UI in devSimulation mode) ──────────────────────────
  _SimPreset _preset = _simPresets[0];
  DashboardTab _activeTab = DashboardTab.dailySurvival;

  // ── HYBRID STATE ENGINE ───────────────────────────────────────────────────
  // Default: app starts in liveAir mode and immediately fetches real weather.
  AppWeatherMode _weatherMode = AppWeatherMode.liveAir;
  LiveWeatherData? _liveData;
  AirQualityData? _airQuality;
  DataFreshness _dataFreshness = DataFreshness.unavailable;
  bool _liveLoading = false;

  // ── UNIT PREFERENCE ───────────────────────────────────────────────────────
  /// Persisted via SharedPreferences; defaults to Celsius.
  bool _isCelsius = true;

  /// 15-minute background refresh — only fires when in liveAir mode.
  Timer? _refreshTimer;
  StreamSubscription<String>? _notificationSub;

  // ── LIFECYCLE ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initEngine(); // This will automatically trigger _activateLiveAir once ready
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) {
        if (_weatherMode == AppWeatherMode.liveAir) { _activateLiveAir(); }
      },
    );
    _notificationSub = NotificationService.instance.onNotificationTap.listen((payload) {
      if (!mounted) return;
      if (payload.contains('friday_escape') || payload.contains('flash_flood')) {
        setState(() => _activeTab = DashboardTab.weekendEscape);
      } else {
        setState(() => _activeTab = DashboardTab.dailySurvival);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationSub?.cancel();
    super.dispose();
  }

  Future<void> _initEngine() async {
    final prefs = await SharedPreferences.getInstance();
    _engine = CanadianAdviceEngine(prefs: prefs, random: Random());
    // Load persisted unit preference (defaults to Celsius if not set)
    final savedUnit = prefs.getBool('unit_is_celsius') ?? true;
    setState(() {
      _engineReady = true;
      _isCelsius = savedUnit;
    });
    
    // Engine is fully loaded, safe to trigger live air pipeline
    await _activateLiveAir();
  }

  // ── LIVE AIR ACTIVATION ───────────────────────────────────────────────────
  /// Fetches real-time Open-Meteo data, maps it to a _SimPreset, and
  /// recalculates advice. On failure, stays on last known preset.
  Future<void> _activateLiveAir() async {
    if (!mounted) return;
    setState(() {
      _weatherMode = AppWeatherMode.liveAir;
      _liveLoading = true;
    });

    try {
      // ── Parallel fetch: weather + air quality ──────────────────────────
      final weatherFuture = LiveWeatherService().fetchLiveWeather();

      // We need coordinates before we can fetch AQ — resolve weather first,
      // then fire AQ with the known coordinates.
      final data = await weatherFuture;
      if (!mounted) return;
      _liveData = data;
      _dataFreshness = data.freshness;
      _preset = _presetFromLive(data);

      // Fetch AQHI in parallel with notification setup
      final aqFuture = AirQualityService().fetchAirQuality(
        lat: data.latitude,
        lon: data.longitude,
      );

      // PHASE 1: Polite runtime permission request flow triggered after GPS location lock
      await NotificationService.instance.requestPermissions();
      // TIER 1/2/3: Evaluate and schedule dynamic notifications based on LiveWeatherData
      await NotificationScheduler.evaluateLiveTelemetry(data);

      // Await AQHI result (already running in parallel)
      final aqData = await aqFuture;
      if (mounted) setState(() => _airQuality = aqData);
    } catch (_) {
      _dataFreshness = DataFreshness.unavailable;
    } finally {
      if (mounted) setState(() => _liveLoading = false);
    }

    await _recomputeAdvice();
  }

  // ── DEV SIM OVERRIDE ──────────────────────────────────────────────────────
  /// Switches to devSimulation mode, pauses live polling, applies sim preset.
  void _selectPreset(_SimPreset preset) {
    setState(() {
      _weatherMode = AppWeatherMode.devSimulation;
      _preset = preset;
    });
    _recomputeAdvice();
  }

  // ── LIVE → _SimPreset CONVERTER ───────────────────────────────────────────
  /// Maps LiveWeatherData into a _SimPreset so ALL existing UI code
  /// (canvasMode, EscapeParams, HeroTempBlock, etc.) works without changes.
  _SimPreset _presetFromLive(LiveWeatherData d) => _SimPreset(
        id: 'LIVE',
        label: '🛰️  LIVE',
        tempC: d.temperatureC,
        snowCm: d.snowfallCm,
        isSnowing: d.isSnowing,
        hour: d.fetchTime.hour,
        windKmh: d.windSpeedKmh,
        precipChance: d.precipitationProbabilityPct,
        humidity: d.humidity,
        recentRainMm: d.precipitationMm,
        aqhi: 0.0, // AQHI requires a separate AQHI API endpoint
        windGustKmh: d.windGustKmh,
        isFreezethaw: d.isFreezethaw,
      );

  // ── RECOMPUTE ADVICE ──────────────────────────────────────────────────────
  Future<void> _recomputeAdvice() async {
    if (_engine == null) return;
    final results = await _engine!.generateAdvice(
      CanadianAdviceParams(
        temperatureC: _preset.tempC,
        snowfallCm: _preset.snowCm,
        isSnowing: _preset.isSnowing,
        currentHour: _preset.hour,
        humidity: _preset.humidity,
        isRaining: _preset.isRaining,
        precipitationMm: _preset.recentRainMm,
        isFoggy: _preset.isFoggy,
        aqhi: _preset.aqhi,
        windGustKmh: _preset.windGustKmh,
        isFreezethaw: _preset.isFreezethaw,
      ),
    );
    
    List<ActivityScore> activityScores = ActivityScoringEngine.generateScores(
      tempC: _preset.tempC,
      windKmh: _preset.windKmh,
      precipChance: _preset.precipChance,
      snowCm: _preset.snowCm,
      isRaining: _preset.isRaining,
      month: DateTime.now().month,
      windGustKmh: _preset.windGustKmh,
    );

    final aq = _airQuality;
    final aqhiValue = aq?.aqhi ?? 0.0;

    _activeProfile = WeatherStateMatrix.resolveCurrentProfile(
      _preset.id,
      windGustKmh: _preset.windGustKmh,
      windKmh: _preset.windKmh,
      aqhi: aqhiValue,
      tempC: _preset.tempC,
      apparentTempC: _preset.tempC,
      precip: _preset.isRaining || _preset.precipChance > 30,
      snowCm: _preset.snowCm,
    );

    // ── Apply WeatherStateMatrix severity cap to Cycling & Hiking ──
    if (_activeProfile.isExtremeHazard) {
      activityScores = activityScores.map((s) {
        if (s.id == 'cycling' || s.id == 'hiking') {
          String fallbackMsg = 'Hazardous conditions due to extreme weather state.';
          if (_activeProfile.id == WeatherProfileId.wildfireSmokeHigh) {
            fallbackMsg = 'Hazardous air quality due to fine particulate matter. Avoid outdoor cardio.';
          } else if (_activeProfile.id == WeatherProfileId.galeWindstorm) {
            fallbackMsg = 'Gale force winds active. Outdoor activities suspended.';
          } else if (_activeProfile.id == WeatherProfileId.shoulderFreezeThaw) {
            fallbackMsg = 'Freeze-thaw cycle active. Slush and black ice hazards.';
          } else if (_activeProfile.id == WeatherProfileId.deepWinterBlizzard) {
            fallbackMsg = 'Deep winter freeze. Outdoor season suspended.';
          }

          return ActivityScore(
            id: s.id,
            title: s.title,
            score: ScoreLevel.poor,
            message: fallbackMsg,
            icon: s.icon,
            type: s.type,
            score10: 1,
            status: ActivityStatus.hazardous,
            headline: _activeProfile.headline,
            immediateAction: _activeProfile.immediateAction,
            canadianContext: _activeProfile.canadianContext,
          );
        }
        return s;
      }).toList();
    }

    // ── Apply WeatherStateMatrix dict to Running & Patio ──
    activityScores = activityScores.map((s) {
      if (s.id == 'running') {
        return ActivityScore(
          id: 'running',
          title: 'Running',
          score: _activeProfile.dailyRunningScoreLevel,
          message: _activeProfile.dailyRunningScoreMessage,
          icon: Icons.directions_run,
          type: ActivityType.running,
          score10: _activeProfile.dailyRunningScoreLevel == ScoreLevel.good ? 8 : 1,
          status: _activeProfile.dailyRunningScoreLevel == ScoreLevel.good ? ActivityStatus.good : ActivityStatus.hazardous,
          headline: _activeProfile.headline,
          immediateAction: _activeProfile.immediateAction,
          canadianContext: _activeProfile.canadianContext,
        );
      } else if (s.id == 'patio') {
        return ActivityScore(
          id: 'patio',
          title: 'Patio',
          score: _activeProfile.dailyPatioScoreLevel,
          message: _activeProfile.dailyPatioScoreMessage,
          icon: Icons.deck,
          type: ActivityType.patio,
          score10: _activeProfile.dailyPatioScoreLevel == ScoreLevel.good ? 8 : 1,
          status: _activeProfile.dailyPatioScoreLevel == ScoreLevel.good ? ActivityStatus.good : ActivityStatus.hazardous,
          headline: _activeProfile.headline,
          immediateAction: _activeProfile.immediateAction,
          canadianContext: _activeProfile.canadianContext,
        );
      }
      return s;
    }).toList();

    // ── Phase 4: AQHI Advice Guardrails ──────────────────────────────────────
    if (aq != null && aq.aqhi >= 7) {
      // ─ Override 2: Inject SEAL WINDOWS + air quality emergency advice ─────
      // Remove any existing windowManagement or airQuality cards that may have
      // been generated with softer copy, then prepend high-urgency overrides.
      final filtered = results
          .where((r) =>
              r.category != AdviceCategory.windowManagement &&
              r.category != AdviceCategory.airQuality)
          .toList();

      final smokeAdvice = [
        AdviceResult(
          category: AdviceCategory.windowManagement,
          urgencyLevel: UrgencyLevel.actionRequired,
          title: 'SEAL WINDOWS',
          instruction: 'SEAL WINDOWS — Wildfire smoke detected outside.',
          explanation:
              'PM2.5 at ${aq.pm2_5.toStringAsFixed(1)} µg/m³ (AQHI '
              '${aq.isVeryHigh ? '10+' : aq.aqhiDisplay}). Close all windows '
              'and doors immediately. Run HEPA air purifiers on maximum. '
              'Wildfire smoke infiltration can peak within 15 minutes of '
              'leaving windows open under current conditions.',
          icon: Icons.sensor_window,
        ),
        AdviceResult(
          category: AdviceCategory.airQuality,
          urgencyLevel: aq.aqhi >= 10
              ? UrgencyLevel.actionRequired
              : UrgencyLevel.warning,
          title: aq.aqhi >= 10
              ? '🛑 HAZARDOUS AIR QUALITY'
              : '⚠️ WILDFIRE SMOKE PLUME',
          instruction: aq.aqhi >= 10
              ? 'Stay sealed indoors. N95 required outdoors.'
              : 'Limit all outdoor exertion immediately.',
          explanation: aq.aqhi >= 10
              ? 'AQHI ${aq.aqhiDisplay}+ — Very High Risk. This is a public '
                  'health emergency level event. Follow Environment Canada '
                  'Air Quality Alerts at weather.gc.ca. N95 respirator '
                  'mandatory for any outdoor transit.'
              : 'AQHI ${aq.aqhiDisplay} — High Risk. Wildfire smoke plume '
                  'detected. Move outdoor cardio inside. Sensitive individuals '
                  '(asthma, heart conditions, children, seniors) must stay '
                  'indoors.',
          icon: aq.aqhi >= 10 ? Icons.dangerous : Icons.warning_amber,
        ),
      ];

      // Prepend smoke alerts at the top of the advice list
      results
        ..clear()
        ..addAll([...smokeAdvice, ...filtered]);
    }

    if (mounted) {
      setState(() {
        _cachedAdvice = results;
        _activityScores = activityScores;
      });
    }


    // ── NATIVE WIDGET SYNC ───────────────────────────────────────────────────
    if (_weatherMode == AppWeatherMode.liveAir && _liveData != null) {
      final patioObj = activityScores.firstWhere(
        (s) => s.type == ActivityType.patio,
        orElse: () => const ActivityScore(
          id: 'patio',
          title: 'Patio',
          score: ScoreLevel.poor,
          message: 'Patio conditions are unclear.',
          icon: Icons.deck,
          type: ActivityType.patio,
          score10: 0,
          status: ActivityStatus.poor,
        ),
      );

      bool hasAlert = activityScores.any((s) => s.status == ActivityStatus.hazardous);
      if (_preset.windGustKmh > 50) hasAlert = true;
      if (_liveData!.precipitationProbabilityPct > 80 && _liveData!.precipitationMm > 10) hasAlert = true;

      await WidgetSyncService.syncData(payload: {
        "temp": "${_liveData!.temperatureC.round()}°",
        "condition": patioObj.status.name.toUpperCase(),
        "location": _liveData!.cityName ?? 'Unknown',
        "high_low": '${_liveData!.temperatureC.round() + 4}° / ${_liveData!.temperatureC.round() - 2}°',
        "aqhi_badge": hasAlert ? '⚠️ HAZARD RISK' : '🟢 ALL CLEAR',
        "hourly_6hr": [],
        "weekly_7day": [],
      });
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // ── 1. WEATHER CANVAS (bottom layer, behind everything) ─────────
          // Only rendered when weather conditions are active (rain or snow).
          // IgnorePointer: touch events pass through to content above.
          // Opacity 0.20: canvas is atmospheric, not distracting.
          // RepaintBoundary inside canvas prevents tree rebuilds.
          if (_preset.canvasMode != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  child: AnimatedOpacity(
                    // Key goes on the direct child of AnimatedSwitcher so it knows when to cross-fade
                    key: ValueKey(_preset.canvasMode),
                    opacity: NeoBrutalistWeatherCanvas
                        .suggestedOpacity(_preset.canvasMode!),
                    duration: const Duration(milliseconds: 700),
                    child: NeoBrutalistWeatherCanvas(
                      mode: _preset.canvasMode!,
                    ),
                  ),
                ),
              ),
            ),

          // ── 2. MAIN SCROLLABLE DECK (middle layer) ──────────────────────
          _buildMainDeck(),

          // ── 3. ESCAPE TAB CROSS-FADE OVERLAY ────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _activeTab == DashboardTab.weekendEscape
                ? _buildEscapeOverlay()
                : const SizedBox.shrink(key: ValueKey('none')),
          ),

          // ── 4. FLOATING CAPSULE NAV (top layer, always visible) ─────────
          Positioned(
            bottom: 24,
            left: 32,
            right: 32,
            child: FloatingCapsuleNav(
              activeTab: _activeTab,
              onTabChanged: (tab) => setState(() => _activeTab = tab),
            ),
          ),

          // ── 5. SETTINGS GEAR (top-right, above canvas, below notifications) ─
          Positioned(
            top: 52,
            right: 20,
            child: GestureDetector(
              onTap: () => showSettingsDrawer(
                context,
                isCelsius: _isCelsius,
                onToggle: (val) => setState(() => _isCelsius = val),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  border: Border.all(color: const Color(0xFF2C2C2C)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune, color: Color(0xFF7F7F7F), size: 18),
              ),
            ),
          ),

          // ── 6. NOTIFICATION OVERLAY (absolute top — above everything) ─────
          // IgnorePointer is FALSE here — toast tiles ARE tappable for dismiss.
          // The overlay is transparent when no toasts are active.
          const Positioned.fill(
            child: CanadianNotificationOverlay(),
          ),
        ],
      ),
    );
  }

  // ── DAILY SURVIVAL DECK ───────────────────────────────────────────────────
  Widget _buildMainDeck() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _SimulationBar(
            presets: _simPresets,
            active: _preset,
            onSelect: _selectPreset,
            // ── Hybrid State Engine params ──────────────────────────────
            weatherMode: _weatherMode,
            liveLoading: _liveLoading,
            dataFreshness: _dataFreshness,
            isUsingDefaultLocation:
                _liveData?.isUsingDefaultLocation ?? false,
            onLiveAirTap: _activateLiveAir,
          ),
        ),
        SliverToBoxAdapter(
          child: _HeroTempBlock(
            preset: _preset,
            isCelsius: _isCelsius,
            humidex: _liveData?.humidex,
          ),
        ),

        // ── EXACT ALARM ONBOARDING CARD (Android 14+ SCHEDULE_EXACT_ALARM) ──
        const SliverToBoxAdapter(
          child: ExactAlarmOnboardingCard(),
        ),

        if (_liveData != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: HourlyTimelineSection(data: _liveData!, isCelsius: _isCelsius),
            ),
          ),

        // ── SUNSET THERMAL SNAP ────────────────────────────────────────────
        if (_liveData != null)
          SliverToBoxAdapter(
            child: SunsetThermalSnapCard(data: _liveData!),
          ),

        // ── AQHI & WILDFIRE SMOKE DRIFT ────────────────────────────────────
        if (_liveData != null && _airQuality != null)
          SliverToBoxAdapter(
            child: AqhiSmokeDriftCard(
              aq: _airQuality!,
              weather: _liveData!,
            ),
          ),

        // Golden hour block only shows on clear summer days (not in any
        // extreme weather state that would have its own canvas)
        if (_preset.canvasMode == null)
          const SliverToBoxAdapter(child: _GoldenHourBlock()),

        // Accent divider — color matches the active canvas mode
        if (_preset.canvasMode != null)
          SliverToBoxAdapter(
            child: Container(
              height: 2,
              color: _accentColorForMode(_preset.canvasMode!).withOpacity(0.20),
            ),
          ),

        if (_engineReady && _activityScores.isNotEmpty)
          SliverToBoxAdapter(
            child: PlanYourDayWidget(scores: _activityScores),
          ),

        // ── 7-DAY CANADIAN WEEKLY PLANNER ─────────────────────────────
        if (_engineReady && (_liveData?.dailyForecasts.isNotEmpty ?? false))
          SliverToBoxAdapter(
            child: Builder(builder: (ctx) {
              final dailyForecasts = _liveData!.dailyForecasts;
              final taggedWeek = WeeklyForecastingEngine.tagWeek(dailyForecasts);
              final weekendDays = taggedWeek.where((t) => t.isWeekend).toList();
              final weekendSummary = WeeklyForecastingEngine.generateWeekendSummary(weekendDays);
              return WeeklyCanadianPlannerCard(
                taggedWeek: taggedWeek,
                weekendSummary: weekendSummary,
              );
            }),
          ),

        if (_engineReady && _cachedAdvice.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
              child: Text(
                '— CANADIAN SURVIVAL GUIDE',
                style: AppTypography.monoCaption.copyWith(
                  color: AppColors.concreteGrey,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: ActionableChoreCard(
                      key: ValueKey(_cachedAdvice[i].title),
                      advice: _cachedAdvice[i],
                    ),
                  ),
                  Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.06)),
                ],
              ),
              childCount: _cachedAdvice.length,
            ),
          ),
        ],

        // Engine loading skeleton
        if (!_engineReady)
          SliverToBoxAdapter(
            child: Container(
              height: 120,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Center(
                child: Text(
                  'LOADING ENGINE...',
                  style: AppTypography.monoCaption.copyWith(
                    color: AppColors.concreteGrey,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ),

        // Weekend score only shown on clear/nice days
        if (_preset.canvasMode == null)
          const SliverToBoxAdapter(child: _WeekendScoreBlock()),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
            child: const AdMobBannerWidget(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ── ESCAPE OVERLAY ────────────────────────────────────────────────────────
  Widget _buildEscapeOverlay() {
    final escapeParams = EscapeParams(
      tempC: _preset.tempC,
      windKmh: _preset.windKmh,
      precipChance: _preset.precipChance,
      humidity: _preset.humidity,
      recentRainMm: _preset.recentRainMm,
      // For WIND preset, pass actual gust speed so escape highway radar
      // correctly computes SQUALL WARNING (gust > 70 km/h).
      windGustKmh: _preset.windGustKmh > 0
          ? _preset.windGustKmh
          : _preset.windKmh * 1.5,
      isRainingWeekend: _preset.isRainingWeekend,
    );

    return Container(
      key: const ValueKey('escape'),
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  EscapeDashboardView(params: escapeParams, profile: _activeProfile),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      '— SCORES DRIVEN BY SIM: ${_preset.label}',
                      style: AppTypography.monoCaption.copyWith(
                        color: AppColors.concreteGrey.withOpacity(0.4),
                        fontSize: 9,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIMULATION BAR
// ─────────────────────────────────────────────────────────────────────────────

class _SimulationBar extends StatelessWidget {
  final List<_SimPreset> presets;
  final _SimPreset active;
  final ValueChanged<_SimPreset> onSelect;
  // ── Hybrid State Engine ────────────────────────────────────────────────
  final AppWeatherMode weatherMode;
  final bool liveLoading;
  final DataFreshness dataFreshness;
  final bool isUsingDefaultLocation;
  final VoidCallback onLiveAirTap;

  const _SimulationBar({
    required this.presets,
    required this.active,
    required this.onSelect,
    required this.weatherMode,
    required this.liveLoading,
    required this.dataFreshness,
    required this.isUsingDefaultLocation,
    required this.onLiveAirTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = weatherMode == AppWeatherMode.liveAir;
    return Container(
      width: double.infinity,
      color: const Color(0xFF0A0A0A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 52),

          // ── DEV SIMULATION header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isLive
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFE6FF00),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isLive ? 'LIVE WEATHER SYNC' : 'DEV SIMULATION',
                  style: AppTypography.monoCaption.copyWith(
                    color: isLive
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFE6FF00),
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),

          // ── 🛰️  LIVE AIR button ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: _LiveAirButton(
              isLive: isLive,
              loading: liveLoading,
              freshness: dataFreshness,
              isUsingDefaultLocation: isUsingDefaultLocation,
              onTap: onLiveAirTap,
            ),
          ),

          // ── Sim preset chips ─────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: presets.map((p) {
                final isActive = !isLive && active.id == p.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onSelect(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.pureWhite
                            : Colors.transparent,
                        border: Border.all(
                          color: isActive
                              ? AppColors.pureWhite
                              : Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Text(
                        p.label,
                        style: AppTypography.monoCaption.copyWith(
                          color: isActive
                              ? AppColors.voidBlack
                              : AppColors.concreteGrey,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // ── TEST ALERTS DRAWER ── inserted before the bottom rule ─────────
          const TestAlertsDrawer(),
          Container(height: 1, color: Colors.white.withOpacity(0.06)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO TEMP BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class _HeroTempBlock extends StatelessWidget {
  final _SimPreset preset;
  final String? cityName;
  /// Whether to display in Celsius (true) or Fahrenheit (false).
  final bool isCelsius;
  /// Environment Canada Humidex value (°C). Shown when tempC > 20 and non-null.
  final double? humidex;
  const _HeroTempBlock({
    super.key,
    required this.preset,
    this.cityName,
    this.isCelsius = true,
    this.humidex,
  });

  Color get _accentColor => _accentColorForMode(preset.canvasMode);

  String get _modeLabel {
    return switch (preset.id) {
      'SMOKE' => 'SMOKE ALERT',
      'WIND'  => 'WINDSTORM',
      'SLUSH' => 'FREEZE-THAW',
      _       => switch (preset.canvasMode) {
        WeatherAnimationMode.snow        => 'WINTER MODE',
        WeatherAnimationMode.rain        => 'RAIN MODE',
        WeatherAnimationMode.clearNight  => 'CLEAR NIGHT',
        WeatherAnimationMode.summerDay   => 'SUMMER SYNC',
        _                                => 'CURRENT',
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _modeLabel,
            style: AppTypography.monoCaption.copyWith(
              color: _accentColor,
              letterSpacing: 4,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              TemperatureUnit.format(preset.tempC, isCelsius: isCelsius),
              key: ValueKey('${preset.tempC}_$isCelsius'),
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 128,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFFFFF),
                height: 0.9,
                letterSpacing: -6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ── HUMIDEX BADGE ────────────────────────────────────────────────
          // Visible only when live dew-point data is available AND temp > 20°C.
          // Uses the Environment Canada formula with dart:math exp().
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: (preset.tempC > 20.0 && humidex != null)
                ? Padding(
                    key: const ValueKey('humidex-visible'),
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B2B).withValues(alpha: 0.12),
                            border: Border.all(
                              color: const Color(0xFFFF6B2B).withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.thermostat,
                                color: Color(0xFFFF6B2B),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'HUMIDEX  ${humidex!.round()}°C',
                                style: AppTypography.monoCaption.copyWith(
                                  color: const Color(0xFFFF6B2B),
                                  fontSize: 12,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Feels like ${humidex!.round()}°C — Environment Canada',
                            style: AppTypography.monoCaption.copyWith(
                              color: AppColors.concreteGrey,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('humidex-hidden')),
          ),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                cityName != null
                    ? cityName!.toUpperCase()
                    : 'TORONTO  ·  SIMULATED',
                style: AppTypography.monoCaption.copyWith(
                  color: AppColors.concreteGrey,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOLDEN HOUR BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class _GoldenHourBlock extends StatelessWidget {
  const _GoldenHourBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      color: const Color(0xFF111111),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOLDEN HOUR',
                  style: AppTypography.monoCaption.copyWith(
                    color: AppColors.warmthAmber,
                    letterSpacing: 3,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '8:15 PM',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFFFFF),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SUNSET OUTDOOR WINDOW OPEN',
                  style: AppTypography.monoCaption.copyWith(
                    color: AppColors.concreteGrey,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 0.85,
                  strokeWidth: 3,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.warmthAmber),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '85',
                        style: AppTypography.monoCaption.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      Text(
                        'CI',
                        style: AppTypography.monoCaption.copyWith(
                          fontSize: 9,
                          color: AppColors.concreteGrey,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
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
// WEEKEND SCORE BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class _WeekendScoreBlock extends StatelessWidget {
  const _WeekendScoreBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      color: const Color(0xFF0A0A0A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKEND MAXIMIZER',
            style: AppTypography.monoCaption.copyWith(
              color: AppColors.concreteGrey,
              letterSpacing: 3,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '8',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFFFFF),
                  height: 0.9,
                  letterSpacing: -4,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  '/10',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF555555),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: const Color(0xFFE6FF00),
                child: Text(
                  'EXCELLENT',
                  style: AppTypography.monoCaption.copyWith(
                    color: AppColors.voidBlack,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Get outside — conditions near ideal for any activity.',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 15,
              color: Colors.white.withOpacity(0.45),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🛰️  LIVE AIR BUTTON
// StatefulWidget owns its own AnimationController so the pulsing neon-green
// dot runs at 60 FPS without touching any parent setState() call.
// ─────────────────────────────────────────────────────────────────────────────

class _LiveAirButton extends StatefulWidget {
  final bool isLive;
  final bool loading;
  final DataFreshness freshness;
  final bool isUsingDefaultLocation;
  final VoidCallback onTap;

  const _LiveAirButton({
    required this.isLive,
    required this.loading,
    required this.freshness,
    required this.isUsingDefaultLocation,
    required this.onTap,
  });

  @override
  State<_LiveAirButton> createState() => _LiveAirButtonState();
}

class _LiveAirButtonState extends State<_LiveAirButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String get _statusLabel {
    if (widget.loading)                                 return 'SYNCING...';
    if (widget.freshness == DataFreshness.cached)       return '⚠️ CACHED · OFFLINE';
    if (widget.freshness == DataFreshness.unavailable)  return 'UNAVAILABLE';
    if (widget.isLive)                                  return 'REAL-TIME';
    return 'PAUSED';
  }

  Color get _statusColor {
    if (widget.freshness == DataFreshness.cached)       return const Color(0xFFFF8C00);
    if (widget.freshness == DataFreshness.unavailable)  return Colors.white.withOpacity(0.30);
    if (widget.isLive)                                  return const Color(0xFF00FF88);
    return Colors.white.withOpacity(0.25);
  }

  @override
  Widget build(BuildContext context) {
    final isLive = widget.isLive;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isLive
              ? const Color(0xFF00FF88).withOpacity(0.06)
              : Colors.transparent,
          border: Border.all(
            color: isLive
                ? const Color(0xFF00FF88).withOpacity(0.65)
                : Colors.white.withOpacity(0.14),
            width: isLive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // ── Pulsing satellite indicator ───────────────────────────────────
            if (widget.loading)
              const SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Color(0xFF00FF88),
                ),
              )
            else if (isLive)
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00FF88)
                        .withOpacity(0.45 + _pulse.value * 0.55),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF88)
                            .withOpacity(0.35 * _pulse.value),
                        blurRadius: 7,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
            const SizedBox(width: 10),
            // ── Label ─────────────────────────────────────────────────────────
            Text(
              '🛰️  LIVE AIR',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                fontWeight: isLive ? FontWeight.w700 : FontWeight.w400,
                color: isLive
                    ? const Color(0xFF00FF88)
                    : Colors.white.withOpacity(0.38),
                letterSpacing: 2.5,
              ),
            ),
            const Spacer(),
            // ── Status badge ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              color: _statusColor.withOpacity(0.12),
              child: Text(
                _statusLabel,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: _statusColor,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

