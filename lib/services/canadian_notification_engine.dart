/// canadian_notification_engine.dart
///
/// Canadian Smart Notification Ecosystem
/// ─────────────────────────────────────────────────────────────────────────
/// Architecture: Pure in-app toast system — works on ALL platforms including
/// Flutter Web without native push dependencies.
///
/// For production mobile: flutter_local_notifications can be wired into
/// CanadianNotificationEngine.fire() behind a kIsWeb check.
///
/// 7 PREDEFINED CANADIAN TRIGGERS:
///  1. windowsDown    — 💨 Night Flush: outdoor air beats indoor temp
///  2. acSaver        — 🔒 Peak Summer: seal blinds before solar gain
///  3. patioGreenLight — 🍺 4:30 PM check: patio conditions elite
///  4. fridayEscape   — ⛺ Friday radar: clear highway commute
///  5. blackIce       — 🚨 6:30 AM: overnight rain froze on walkways
///  6. windrow        — 🚜 Heavy snow: plow windrow inbound
///  7. wildfire       — 🔥 AQHI > 7: smoke plume shifting into area
library canadian_notification_engine;

import 'dart:async';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum NotificationSeverity {
  /// Cyan accent — informational, no immediate danger.
  info,

  /// Yellow accent — action recommended within the hour.
  warning,

  /// Red accent — immediate safety action required.
  critical,
}

class CanadianToast {
  const CanadianToast({
    required this.id,
    required this.emoji,
    required this.title,
    required this.body,
    required this.severity,
  });

  /// Unique identifier — prevents duplicate toasts for the same condition.
  final String id;
  final String emoji;
  final String title;
  final String body;
  final NotificationSeverity severity;

  Color get accentColor => switch (severity) {
        NotificationSeverity.info => const Color(0xFF00F0FF),
        NotificationSeverity.warning => const Color(0xFFE6FF00),
        NotificationSeverity.critical => const Color(0xFFFF2D55),
      };

  String get severityLabel => switch (severity) {
        NotificationSeverity.info => 'INFO',
        NotificationSeverity.warning => 'WARNING',
        NotificationSeverity.critical => 'CRITICAL',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// ENGINE (Singleton ChangeNotifier)
// ─────────────────────────────────────────────────────────────────────────────

class CanadianNotificationEngine extends ChangeNotifier {
  CanadianNotificationEngine._internal();
  static final instance = CanadianNotificationEngine._internal();

  final List<CanadianToast> _active = [];

  /// Read-only snapshot of currently-displayed toasts (newest first).
  List<CanadianToast> get active => List.unmodifiable(_active);

  /// Fire a toast. Replaces any existing toast with the same [id] so the
  /// same condition never produces visual duplicates.
  void fire(CanadianToast toast) {
    _active.removeWhere((t) => t.id == toast.id);
    _active.insert(0, toast); // newest at top
    notifyListeners();
  }

  /// Called by [_ToastTile] after its exit animation completes, or on tap.
  void dismiss(String id) {
    final before = _active.length;
    _active.removeWhere((t) => t.id == id);
    if (_active.length < before)
      notifyListeners(); // only notify if something changed
  }

  // ── THE 7 PREDEFINED CANADIAN NOTIFICATION CONSTRUCTORS ──────────────────

  /// 💨 Night Flush: outdoor air just broke indoor AC dominance.
  void fireWindowsDown() => fire(const CanadianToast(
        id: 'windows_down',
        emoji: '💨',
        title: 'THE OUTDOOR AIR JUST BROKE',
        body:
            'Kill the AC and pop your windows right now for a perfect natural cooldown.',
        severity: NotificationSeverity.info,
      ));

  /// 🔒 Peak Summer: pre-seal blinds before solar gain hits.
  void fireAcSaver() => fire(const CanadianToast(
        id: 'ac_saver',
        emoji: '🔒',
        title: 'PEAK SOLAR HEAT INBOUND',
        body:
            'Solar gain hits in 60 minutes. Seal your south-facing blinds right now to keep the house cool today.',
        severity: NotificationSeverity.warning,
      ));

  /// 🍺 Daily 4:30 PM: patio conditions confirmed elite.
  void firePatioGreenLight() => fire(const CanadianToast(
        id: 'patio_green',
        emoji: '🍺',
        title: 'PATIO STATUS: ELITE',
        body:
            'Wind is dead calm and humidity is gone. Perfect evening for a backyard BBQ or deck hangout.',
        severity: NotificationSeverity.info,
      ));

  /// ⛺ Friday 3:30 PM: clear highway commute confirmed.
  void fireFridayEscape() => fire(const CanadianToast(
        id: 'friday_escape',
        emoji: '⛺',
        title: 'FRIDAY ESCAPE RADAR: 9/10',
        body:
            'Zero snow squalls or heavy downpours on major routes tonight. Hit the road early, bud!',
        severity: NotificationSeverity.info,
      ));

  /// 🚨 6:30 AM: overnight rain froze on walkways — black ice trap.
  void fireBlackIce() => fire(const CanadianToast(
        id: 'black_ice',
        emoji: '🚨',
        title: 'FRONT STEP ALERT: SOLID ICE',
        body:
            'It rained last night and froze at 4 AM. Your walkways are currently a skating rink. Salt before you walk out!',
        severity: NotificationSeverity.critical,
      ));

  /// 🚜 Heavy snow active: city plow windrow inbound.
  void fireWindrow() => fire(const CanadianToast(
        id: 'windrow',
        emoji: '🚜',
        title: 'PLOW WINDROW WARNING',
        body:
            'City plows are active. Clear your driveway apron right now so plow slush doesn\'t freeze into concrete!',
        severity: NotificationSeverity.warning,
      ));

  /// 🔥 AQHI > 7: wildfire smoke plume moving into area.
  void fireWildfire() => fire(const CanadianToast(
        id: 'wildfire_smoke',
        emoji: '🔥',
        title: 'SMOKE PLUME SHIFTING',
        body:
            'Wildfire smoke is moving into the area. Close your windows and set HVAC to recirculate now.',
        severity: NotificationSeverity.critical,
      ));

  // ── THE 4 TACTICAL THREAT BUCKETS (ECCC ROUTER) ──────────────────────────

  void fireEcccCryo() => fire(const CanadianToast(
        id: 'eccc_cryo',
        emoji: '❄️',
        title: 'ECCC: CRYO-HAZARD',
        body: 'Severe winter dynamics (Blizzard/Freezing Rain). Limit exposure and plug in block heaters.',
        severity: NotificationSeverity.critical,
      ));

  void fireEcccConvective() => fire(const CanadianToast(
        id: 'eccc_convective',
        emoji: '⛈️',
        title: 'ECCC: CONVECTIVE HAZARD',
        body: 'Severe thunderstorm/wind. Secure patio furniture and prepare for grid flickers.',
        severity: NotificationSeverity.critical,
      ));

  void fireEcccAtmospheric() => fire(const CanadianToast(
        id: 'eccc_atmospheric',
        emoji: '🌫️',
        title: 'ECCC: ATMOSPHERIC HAZARD',
        body: 'Visibility dropping or flash flooding. Keep headlights low and check sump pumps.',
        severity: NotificationSeverity.warning,
      ));

  void fireEcccInformational() => fire(const CanadianToast(
        id: 'eccc_informational',
        emoji: '📡',
        title: 'ECCC: WEATHER ADVISORY',
        body: 'Special weather statement. Prepare for shoulder-season flurries or rapid thermal swings.',
        severity: NotificationSeverity.info,
      ));
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERLAY WIDGET
// Place this as the top-most child in a Stack inside your Scaffold body.
// ─────────────────────────────────────────────────────────────────────────────

class CanadianNotificationOverlay extends StatelessWidget {
  const CanadianNotificationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CanadianNotificationEngine.instance,
      builder: (context, _) {
        final toasts = CanadianNotificationEngine.instance.active;
        if (toasts.isEmpty) return const SizedBox.shrink();

        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: toasts
                    .take(3) // max 3 visible stacked toasts
                    .map((t) => _ToastTile(key: ValueKey(t.id), toast: t))
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOAST TILE — animated slide-in from top, auto-dismiss after 7s
// ─────────────────────────────────────────────────────────────────────────────

class _ToastTile extends StatefulWidget {
  final CanadianToast toast;
  const _ToastTile({super.key, required this.toast});

  @override
  State<_ToastTile> createState() => _ToastTileState();
}

class _ToastTileState extends State<_ToastTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    _ctrl.forward();

    // Auto-dismiss after 7 seconds (reverse animation = 400ms, so start at 6.6s)
    _timer = Timer(const Duration(milliseconds: 6600), _startDismiss);
  }

  Future<void> _startDismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) {
      CanadianNotificationEngine.instance.dismiss(widget.toast.id);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.toast;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTap: _startDismiss,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D),
              border:
                  Border.all(color: t.accentColor.withOpacity(0.50), width: 1),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Severity accent bar ──────────────────────────────────
                  Container(width: 3, color: t.accentColor),

                  // ── Content ──────────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header row: severity pill + dismiss hint
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                color: t.accentColor.withOpacity(0.15),
                                child: Text(
                                  t.severityLabel,
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: t.accentColor,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '[ TAP TO DISMISS ]',
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 7,
                                  color: Colors.white.withOpacity(0.22),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Title
                          Text(
                            '${t.emoji}  ${t.title}',
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Body
                          Text(
                            t.body,
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.65),
                              height: 1.55,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEST ALERTS DRAWER — embedded in the Dev Simulation Bar
// ─────────────────────────────────────────────────────────────────────────────

/// A collapsible Neo-Brutalist test panel. Tap any button to instantly fire
/// the corresponding notification as a live in-app toast.
class TestAlertsDrawer extends StatefulWidget {
  const TestAlertsDrawer({super.key});

  @override
  State<TestAlertsDrawer> createState() => _TestAlertsDrawerState();
}

class _TestAlertsDrawerState extends State<TestAlertsDrawer> {
  bool _expanded = false;

  // Map each label to its engine fire method.
  static final _alerts = <({
    String emoji,
    String label,
    NotificationSeverity severity,
    void Function() fire,
  })>[
    (
      emoji: '💨',
      label: 'WINDOWS DOWN',
      severity: NotificationSeverity.info,
      fire: CanadianNotificationEngine.instance.fireWindowsDown,
    ),
    (
      emoji: '🔒',
      label: 'AC SAVER',
      severity: NotificationSeverity.warning,
      fire: CanadianNotificationEngine.instance.fireAcSaver,
    ),
    (
      emoji: '🍺',
      label: 'PATIO ELITE',
      severity: NotificationSeverity.info,
      fire: CanadianNotificationEngine.instance.firePatioGreenLight,
    ),
    (
      emoji: '⛺',
      label: 'FRI ESCAPE',
      severity: NotificationSeverity.info,
      fire: CanadianNotificationEngine.instance.fireFridayEscape,
    ),
    (
      emoji: '🚨',
      label: 'BLACK ICE',
      severity: NotificationSeverity.critical,
      fire: CanadianNotificationEngine.instance.fireBlackIce,
    ),
    (
      emoji: '🚜',
      label: 'WINDROW',
      severity: NotificationSeverity.warning,
      fire: CanadianNotificationEngine.instance.fireWindrow,
    ),
    (
      emoji: '🔥',
      label: 'SMOKE PLUME',
      severity: NotificationSeverity.critical,
      fire: CanadianNotificationEngine.instance.fireWildfire,
    ),
    (
      emoji: '❄️',
      label: 'ECCC CRYO',
      severity: NotificationSeverity.critical,
      fire: CanadianNotificationEngine.instance.fireEcccCryo,
    ),
    (
      emoji: '⛈️',
      label: 'ECCC CONVECTIVE',
      severity: NotificationSeverity.critical,
      fire: CanadianNotificationEngine.instance.fireEcccConvective,
    ),
    (
      emoji: '🌫️',
      label: 'ECCC ATMOSPHERIC',
      severity: NotificationSeverity.warning,
      fire: CanadianNotificationEngine.instance.fireEcccAtmospheric,
    ),
    (
      emoji: '📡',
      label: 'ECCC ADVISORY',
      severity: NotificationSeverity.info,
      fire: CanadianNotificationEngine.instance.fireEcccInformational,
    ),
  ];

  Color _severityColor(NotificationSeverity s) => switch (s) {
        NotificationSeverity.info => const Color(0xFF00F0FF),
        NotificationSeverity.warning => const Color(0xFFE6FF00),
        NotificationSeverity.critical => const Color(0xFFFF2D55),
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Toggle Row ──────────────────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            width: double.infinity,
            color: const Color(0xFF0D0D0D),
            padding: const EdgeInsets.fromLTRB(24, 9, 24, 9),
            child: Row(
              children: [
                // Blinking indicator when expanded
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _expanded
                        ? const Color(0xFFFF2D55)
                        : Colors.white.withOpacity(0.25),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  _expanded ? '🔔  TEST ALERTS  —  CLOSE' : '🔔  TEST ALERTS',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _expanded
                        ? const Color(0xFFFF2D55)
                        : Colors.white.withOpacity(0.45),
                    letterSpacing: 2.5,
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: _expanded
                      ? const Color(0xFFFF2D55)
                      : Colors.white.withOpacity(0.30),
                ),
              ],
            ),
          ),
        ),

        // ── Expandable Alert Buttons ─────────────────────────────────────────
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: _buildAlertGrid(),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 280),
          firstCurve: Curves.easeIn,
          secondCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }

  Widget _buildAlertGrid() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FIRE INSTANT TOAST — TAP TO TRIGGER',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 8,
              color: Colors.white.withOpacity(0.30),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _alerts.map((a) {
                final accent = _severityColor(a.severity);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: a.fire,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.07),
                        border: Border.all(color: accent.withOpacity(0.40)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            a.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a.label,
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: accent,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
