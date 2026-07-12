import 'package:flutter/material.dart';
import 'dart:async';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/domain/matrix/weather_state_matrix.dart';
import 'package:weather_sync_ca/domain/usecases/activity_scoring_engine.dart';
import 'package:weather_sync_ca/presentation/pages/redesign/getaway_tab_view.dart';
import 'package:weather_sync_ca/presentation/pages/redesign/today_tab_view.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/neo_brutalist_weather_canvas.dart';
import 'package:weather_sync_ca/services/air_quality_service.dart';
import 'package:weather_sync_ca/services/live_weather_service.dart';
import 'package:weather_sync_ca/services/widget_sync_service.dart';
import 'package:weather_sync_ca/services/boreal_data_vault.dart';
import 'package:weather_sync_ca/services/notification_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SIMULATION PRESETS
// ─────────────────────────────────────────────────────────────────────────────

class _SimPreset {
  final String id;
  final String label;
  final String emoji;

  const _SimPreset(
      {required this.id, required this.label, required this.emoji});
}

const List<_SimPreset> _kSimPresets = [
  _SimPreset(id: 'LIVE', label: 'LIVE AIR RESET', emoji: '🌿'),
  _SimPreset(id: 'WINDSTORM', label: 'WINDSTORM 95 KM/H', emoji: '🌬️'),
  _SimPreset(id: 'FREEZE-THAW', label: '2°C FREEZE-THAW', emoji: '🧊'),
  _SimPreset(id: 'SMOKE', label: 'WILDFIRE SMOKE ALERT', emoji: '🔥'),
  _SimPreset(id: 'WINTER', label: 'DEEP WINTER BLIZZARD', emoji: '❄️'),
  _SimPreset(id: 'EXTREME-HEAT', label: 'EXTREME HUMIDEX VAULT', emoji: '☀️'),
  _SimPreset(id: 'HEAVY-RAIN', label: 'HEAVY RAIN DOWNPOUR', emoji: '🌧️'),
  _SimPreset(
      id: 'NIGHT', label: 'CLEAR NIGHT (STARRY & SHOOTING STAR)', emoji: '✨'),
];

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class RedesignDashboardPage extends StatefulWidget {
  const RedesignDashboardPage({super.key});

  @override
  State<RedesignDashboardPage> createState() => _RedesignDashboardPageState();
}

class _RedesignDashboardPageState extends State<RedesignDashboardPage>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  String _simulationId = 'LIVE'; // 'LIVE' means no override

  LiveWeatherData? _liveData;
  AirQualityData? _airQuality;
  WeatherProfile _activeProfile = WeatherStateMatrix.primeSummerClear;
  List<ActivityScore> _activityScores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer so didChangeMetrics fires on hinge events.
    WidgetsBinding.instance.addObserver(this);
    _fetchData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Fires on every metrics change — screen size, orientation, and crucially
  /// the Samsung Galaxy Fold hinge snap. Forces a full layout pass to bust
  /// any cached aspect-ratio constraints held by the One UI windowing system.
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (mounted) setState(() {});
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    // Fetch Boreal Intelligence asynchronously in the background so it doesn't block UI
    BorealDataVault.fetchIntelligence();

    // Request Android 13+ notifications permissions after UI is drawn and Activity exists
    unawaited(NotificationEngine.initializeAndRequestPermissions().then((_) {
      NotificationEngine.scheduleDailyIntelAlarms();
    }));

    try {
      final data = await LiveWeatherService().fetchLiveWeather();

      AirQualityData? aq;
      if (data.latitude != 0 && data.longitude != 0) {
        try {
          aq = await AirQualityService().fetchAirQuality(
            lat: data.latitude,
            lon: data.longitude,
          );
        } catch (_) {}
      }

      if (mounted) {
        _liveData = data;
        _airQuality = aq;
        _resolveProfiles();
      }
    } catch (e) {
      debugPrint('RedesignDashboard error fetching data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Re-resolves the active profile from matrix using current simulationId.
  /// Called on fresh fetch and whenever Dev Sim changes the override.
  void _resolveProfiles() {
    final data = _liveData;
    if (data == null) return;

    final aq = _airQuality;
    final isRaining = data.precipitationProbabilityPct > 70;
    final month = DateTime.now().month;

    _activityScores = ActivityScoringEngine.generateScores(
      tempC: data.temperatureC,
      windKmh: data.windSpeedKmh,
      precipChance: data.precipitationProbabilityPct,
      snowCm: data.snowfallCm,
      isRaining: isRaining,
      month: month,
    );

    _activeProfile = WeatherStateMatrix.resolveCurrentProfile(
      _simulationId,
      tempC: data.temperatureC,
      apparentTempC: data.apparentTempC,
      windGustKmh: data.windGustKmh,
      windKmh: data.windSpeedKmh,
      aqhi: aq?.aqhi ?? 2.0,
      precip: isRaining,
      snowCm: data.snowfallCm,
    );

    // Sync bridge data
    final hazardousScore = _activityScores.firstWhere(
        (s) => s.status == ActivityStatus.hazardous,
        orElse: () => _activityScores.first);
    final badgeString = hazardousScore.status == ActivityStatus.hazardous
        ? '⚠️ HAZARD: BLACK ICE DETECTED'
        : '🟢 AIR MASS: CLEAN (AQHI LOW)';

    final conditionString = isRaining
        ? 'TACTICAL OUTLOOK: SQUALLS PREDICTED'
        : 'AIR MASS: CLEAN (AQHI LOW)';

    // Build hourly and weekly mocks for the widget bridge since live data is stubbed in the simulator
    final hourlyArray = List.generate(
        6,
        (i) => {
              "time": "${(DateTime.now().hour + i) % 24}:00",
              "temp": "${data.temperatureC.round()}°",
              "icon": isRaining ? "🌧️" : "☁️"
            });

    final weeklyArray = List.generate(
        7,
        (i) => {
              "day": [
                "Mon",
                "Tue",
                "Wed",
                "Thu",
                "Fri",
                "Sat",
                "Sun"
              ][(DateTime.now().weekday + i - 1) % 7],
              "icon": isRaining ? "🌧️" : (i % 2 == 0 ? "☀️" : "☁️"),
              "high": "${data.temperatureC.round() + 4}°",
              "low": "${data.temperatureC.round() - 2}°"
            });

    WidgetSyncService.syncData(payload: {
      "temp": "${data.temperatureC.round()}°",
      "condition": conditionString,
      "location": data.cityName ?? 'Unknown',
      "high_low":
          '${data.temperatureC.round() + 4}° / ${data.temperatureC.round() - 2}°',
      "aqhi_badge": badgeString,
      "hourly_6hr": hourlyArray,
      "weekly_7day": weeklyArray,
    });
  }

  void _applySimulation(String id) {
    setState(() {
      _simulationId = id;
      _resolveProfiles();
    });
  }

  /// Maps the current WeatherProfile to a WeatherAnimationMode.
  WeatherAnimationMode? get _canvasMode {
    final now = DateTime.now();
    final isNight = now.hour < 6 || now.hour > 20;

    return switch (_activeProfile.id) {
      WeatherProfileId.galeWindstorm => WeatherAnimationMode.severeWind,
      WeatherProfileId.shoulderFreezeThaw => WeatherAnimationMode.slush,
      WeatherProfileId.wildfireSmokeHigh => WeatherAnimationMode.wildfire,
      WeatherProfileId.deepWinterBlizzard => WeatherAnimationMode.snow,
      WeatherProfileId.extremeHeatHumidex => WeatherAnimationMode.summerDay,
      WeatherProfileId.heavyRainDownpour => WeatherAnimationMode.rain,
      WeatherProfileId.clearNightStarry => WeatherAnimationMode.clearNight,
      WeatherProfileId.primeSummerClear =>
        isNight ? WeatherAnimationMode.clearNight : null,
    };
  }

  // ── Dev Sim Panel ──────────────────────────────────────────────────────────

  void _showDevSimDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _DevSimDialog(
        currentId: _simulationId,
        onSelect: (id) {
          Navigator.of(ctx).pop();
          _applySimulation(id);
        },
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSimActive = _simulationId != 'LIVE';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: const Color(0xFF111111),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '[ 🍁 BOREAL WX | DUNDALK, ON ]',
                  style: AppTypography.monoCaption.copyWith(
                    color: AppColors.concreteGrey,
                    letterSpacing: 3,
                    fontSize: 10,
                  ),
                ),
                // ⚡ DEV SIM pill button
                GestureDetector(
                  onTap: _showDevSimDialog,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSimActive
                          ? const Color(0xFFD4FF00)
                          : const Color(0xFF1A1A1A),
                      border: Border.all(
                        color: isSimActive
                            ? const Color(0xFFD4FF00)
                            : const Color(0xFF333333),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '⚡',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isSimActive ? _simulationId : 'DEV SIM',
                          style: AppTypography.monoCaption.copyWith(
                            color: isSimActive
                                ? const Color(0xFF0A0A0A)
                                : const Color(0xFFD4FF00),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4FF00)))
          : Stack(
              children: [
                // ── 1. WEATHER CANVAS (bottom layer, behind everything) ──
                if (_canvasMode != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 800),
                        switchInCurve: Curves.easeInOutCubic,
                        switchOutCurve: Curves.easeInOutCubic,
                        child: AnimatedOpacity(
                          key: ValueKey(_canvasMode),
                          opacity: NeoBrutalistWeatherCanvas.suggestedOpacity(
                              _canvasMode!),
                          duration: const Duration(milliseconds: 700),
                          child: NeoBrutalistWeatherCanvas(
                            mode: _canvasMode!,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── 2. MAIN SCROLLABLE TAB CONTENT (top layer) ──
                IndexedStack(
                  index: _currentIndex,
                  children: [
                    TodayTabView(
                      liveData: _liveData,
                      airQuality: _airQuality,
                      activeProfile: _activeProfile,
                      activityScores: _activityScores,
                      onNavigateToGetaway: () =>
                          setState(() => _currentIndex = 1),
                    ),
                    GetawayTabView(
                      liveData: _liveData,
                      activeProfile: _activeProfile,
                      simulationId: _simulationId,
                    ),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── ADMOB BANNER — permanently docked above nav bar ──────────────
          const AdmobBannerWrapper(),
          // ── BOTTOM NAV BAR ────────────────────────────────────────────────
          Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              backgroundColor: const Color(0xFF111111),
              selectedItemColor: const Color(0xFFD4FF00),
              unselectedItemColor: AppColors.concreteGrey,
              selectedLabelStyle: AppTypography.monoCaption.copyWith(
                  fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
              unselectedLabelStyle: AppTypography.monoCaption
                  .copyWith(fontSize: 10, letterSpacing: 1),
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.wb_sunny_outlined)),
                  activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.wb_sunny)),
                  label: 'TODAY',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.directions_car_outlined)),
                  activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.directions_car)),
                  label: 'GETAWAY',
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
// DEV SIM DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _DevSimDialog extends StatelessWidget {
  final String currentId;
  final ValueChanged<String> onSelect;

  const _DevSimDialog({required this.currentId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD4FF00), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'DEV SIMULATOR',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFD4FF00),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'FORCE WEATHER STATE OVERRIDE',
              style: AppTypography.monoCaption.copyWith(
                color: AppColors.concreteGrey,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            ..._kSimPresets.map((preset) {
              final isActive = preset.id == currentId;
              return GestureDetector(
                onTap: () => onSelect(preset.id),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFD4FF00)
                        : const Color(0xFF1A1A1A),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFD4FF00)
                          : const Color(0xFF2A2A2A),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(preset.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      Text(
                        preset.label,
                        style: AppTypography.monoCaption.copyWith(
                          color: isActive
                              ? const Color(0xFF0A0A0A)
                              : AppColors.pureWhite,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (isActive) ...[
                        const Spacer(),
                        const Icon(Icons.check,
                            color: Color(0xFF0A0A0A), size: 16),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
