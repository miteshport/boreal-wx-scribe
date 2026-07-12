// bento_control_center.dart
//
// Neo-Brutalist Settings Bottom Sheet — "BENTO CONTROL CENTER"
// ─────────────────────────────────────────────────────────────────────────
// Exposes two settings to the user via a full-height draggable sheet:
//   1. Temperature unit toggle (°C ↔ °F) — instantly rewrites all temp displays.
//   2. Activity card filter grid — hides/shows specific activity badges.
//
// State is owned by [AppSettingsController] (singleton ChangeNotifier).
// This sheet is stateless itself — changes propagate via notifyListeners().

import 'package:flutter/material.dart';
import 'package:weather_sync_ca/core/settings/app_settings_controller.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/domain/usecases/activity_scoring_engine.dart';
import 'package:weather_sync_ca/services/system_push_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LAUNCHER HELPER
// ─────────────────────────────────────────────────────────────────────────────

void showBentoControlCenter(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (_) => const _BentoControlCenterSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHEET WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _BentoControlCenterSheet extends StatelessWidget {
  const _BentoControlCenterSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            border: Border(
              top: BorderSide(color: Color(0xFFD4FF00), width: 2),
              left: BorderSide(color: Color(0xFF0A0A0A), width: 2),
              right: BorderSide(color: Color(0xFF0A0A0A), width: 2),
            ),
          ),
          child: ListenableBuilder(
            listenable: AppSettingsController.instance,
            builder: (_, __) {
              final ctrl = AppSettingsController.instance;
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Pull Tab ─────────────────────────────────────────
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          color: const Color(0xFF333333),
                        ),
                      ),

                      // ── Title ────────────────────────────────────────────
                      Row(
                        children: [
                          const Text('⚙️', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(
                            'BENTO CONTROL CENTER',
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.pureWhite,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PERSONALISE YOUR BENTO GRID',
                        style: AppTypography.monoCaption.copyWith(
                          color: AppColors.concreteGrey,
                          letterSpacing: 2,
                          fontSize: 9,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ═══════════════════════════════════════════════════
                      // SETTING 1: TEMPERATURE UNIT
                      // ═══════════════════════════════════════════════════
                      _SectionLabel('01 — TEMPERATURE UNIT'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ctrl.useFahrenheit
                                      ? 'FAHRENHEIT (°F)'
                                      : 'CELSIUS (°C)',
                                  style: const TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.pureWhite,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ctrl.useFahrenheit
                                      ? 'Currently showing °F'
                                      : 'Environment Canada standard · °C',
                                  style: AppTypography.monoCaption.copyWith(
                                    color: AppColors.concreteGrey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: ctrl.toggleTemperatureUnit,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 56,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: ctrl.useFahrenheit
                                      ? const Color(0xFFD4FF00)
                                      : const Color(0xFF2A2A2A),
                                  border: Border.all(
                                    color: ctrl.useFahrenheit
                                        ? const Color(0xFFD4FF00)
                                        : const Color(0xFF444444),
                                    width: 1.5,
                                  ),
                                ),
                                child: Align(
                                  alignment: ctrl.useFahrenheit
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    color: ctrl.useFahrenheit
                                        ? const Color(0xFF0A0A0A)
                                        : const Color(0xFFD4FF00),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ═══════════════════════════════════════════════════
                      // SETTING 2: ACTIVITY CARD FILTER
                      // ═══════════════════════════════════════════════════
                      _SectionLabel('02 — ACTIVITY CARD FILTER'),
                      const SizedBox(height: 4),
                      Text(
                        'TAP TO TOGGLE VISIBILITY IN YOUR BENTO GRID',
                        style: AppTypography.monoCaption.copyWith(
                          color: AppColors.concreteGrey,
                          fontSize: 9,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.8,
                        children: [
                          _ActivityFilterTile(
                            type: ActivityType.running,
                            label: 'RUNNING',
                            icon: Icons.directions_run_rounded,
                            ctrl: ctrl,
                          ),
                          _ActivityFilterTile(
                            type: ActivityType.cycling,
                            label: 'CYCLING',
                            icon: Icons.directions_bike_rounded,
                            ctrl: ctrl,
                          ),
                          _ActivityFilterTile(
                            type: ActivityType.hiking,
                            label: 'HIKING',
                            icon: Icons.terrain_rounded,
                            ctrl: ctrl,
                          ),
                          _ActivityFilterTile(
                            type: ActivityType.patio,
                            label: 'PATIO',
                            icon: Icons.outdoor_grill_rounded,
                            ctrl: ctrl,
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ═══════════════════════════════════════════════
                      // SECTION 03: JUDGE'S DEMO TEST PANEL
                      // ═══════════════════════════════════════════════
                      _SectionLabel('03 — 🚨 JUDGE’S DEMO: PUSH NOTIFICATION TESTER'),
                      const SizedBox(height: 4),
                      Text(
                        'FIRES REAL SYSTEM-TRAY ALERTS WITHIN 1 SECOND',
                        style: AppTypography.monoCaption.copyWith(
                          color: AppColors.concreteGrey,
                          fontSize: 9,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DemoNotificationPanel(),

                      const SizedBox(height: 40),

                      // ── Close button ────────────────────────────────────
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A),
                            border: Border.all(color: const Color(0xFF333333), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              'CLOSE',
                              style: AppTypography.monoCaption.copyWith(
                                color: AppColors.concreteGrey,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY FILTER TILE
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityFilterTile extends StatelessWidget {
  final ActivityType type;
  final String label;
  final IconData icon;
  final AppSettingsController ctrl;

  const _ActivityFilterTile({
    required this.type,
    required this.label,
    required this.icon,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final isVisible = ctrl.isActivityVisible(type);
    return GestureDetector(
      onTap: () => ctrl.toggleActivity(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isVisible ? const Color(0xFF1E2200) : const Color(0xFF1A1A1A),
          border: Border.all(
            color: isVisible ? const Color(0xFFD4FF00) : const Color(0xFF2A2A2A),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isVisible ? const Color(0xFFD4FF00) : AppColors.concreteGrey,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.monoCaption.copyWith(
                  color: isVisible ? AppColors.pureWhite : AppColors.concreteGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              isVisible ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: isVisible ? const Color(0xFFD4FF00) : const Color(0xFF444444),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL HELPER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.monoCaption.copyWith(
        color: const Color(0xFFD4FF00),
        letterSpacing: 2,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO NOTIFICATION PANEL
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the 4 archetype fire buttons and async permission state.
/// StatefulWidget so we can track loading per-pill without polluting global
/// state — completely isolated from the °C/°F toggle and activity filter.
class _DemoNotificationPanel extends StatefulWidget {
  const _DemoNotificationPanel();

  @override
  State<_DemoNotificationPanel> createState() => _DemoNotificationPanelState();
}

class _DemoNotificationPanelState extends State<_DemoNotificationPanel> {
  // Tracks which archetype id is currently being fired (shows spinner in pill)
  String? _firingId;
  // True after the first successful permission request
  bool _permissionGranted = false;

  // ── Archetype definitions ─────────────────────────────────────────────────

  static const _archetypes = [
    _Archetype(
      id: 'morning_window',
      emoji: '☀️',
      label: 'MORNING WINDOW',
      sublabel: 'Archetype 1 · 7:15 AM Utility',
    ),
    _Archetype(
      id: 'energy_defender',
      emoji: '🚨',
      label: 'ENERGY DEFENDER',
      sublabel: 'Archetype 2 · Humidex / Black Ice',
    ),
    _Archetype(
      id: 'wilderness_alert',
      emoji: '⛺',
      label: 'WILDERNESS ALERT',
      sublabel: 'Archetype 3 · Weekend Fire Guide',
    ),
    _Archetype(
      id: 'eccc_severe',
      emoji: '🛑',
      label: 'ECCC SEVERE ALERT',
      sublabel: 'Archetype 4 · Blizzard Warning',
    ),
  ];

  // ── Fire handler ──────────────────────────────────────────────────────────

  Future<void> _fire(String id) async {
    if (_firingId != null) return; // debounce — one at a time
    setState(() => _firingId = id);

    final svc = SystemPushService.instance;

    // Request permission on first use — never on cold start.
    if (!_permissionGranted) {
      final granted = await svc.requestPermission();
      if (mounted) setState(() => _permissionGranted = granted);
      if (!granted) {
        if (mounted) {
          setState(() => _firingId = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notification permission denied. Enable in device settings.',
              ),
              backgroundColor: Color(0xFF1A1A1A),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    // Fire the correct archetype
    try {
      switch (id) {
        case 'morning_window':
          await svc.fireMorningWindow();
        case 'energy_defender':
          await svc.fireEnergyDefender();
        case 'wilderness_alert':
          await svc.fireWildernessAlert();
        case 'eccc_severe':
          await svc.fireEcccSevereAlert();
      }
    } catch (e) {
      debugPrint('[DemoPanel] Error firing $id: $e');
    } finally {
      if (mounted) setState(() => _firingId = null);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _archetypes
          .map((a) => _ArchetypePill(
                archetype: a,
                isLoading: _firingId == a.id,
                isDisabled: _firingId != null && _firingId != a.id,
                onTap: () => _fire(a.id),
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ARCHETYPE DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _Archetype {
  final String id;
  final String emoji;
  final String label;
  final String sublabel;

  const _Archetype({
    required this.id,
    required this.emoji,
    required this.label,
    required this.sublabel,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// NEO-BRUTALIST ARCHETYPE PILL
// ─────────────────────────────────────────────────────────────────────────────

class _ArchetypePill extends StatelessWidget {
  final _Archetype archetype;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ArchetypePill({
    required this.archetype,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = !isDisabled && !isLoading;

    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isLoading
              ? const Color(0xFF1E2200)  // Solar-Yellow tint while firing
              : isDisabled
                  ? const Color(0xFF111111)
                  : const Color(0xFF1A1A1A),
          border: Border.all(
            color: isLoading
                ? const Color(0xFFD4FF00)
                : isDisabled
                    ? const Color(0xFF1F1F1F)
                    : const Color(0xFF2A2A2A),
            width: isLoading ? 2 : 1.5,
          ),
          boxShadow: isLoading
              ? const [
                  BoxShadow(
                    color: Color(0x33D4FF00),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Emoji icon
            Text(archetype.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 14),

            // Label + sublabel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    archetype.label,
                    style: AppTypography.monoCaption.copyWith(
                      color: isDisabled
                          ? const Color(0xFF444444)
                          : AppColors.pureWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    archetype.sublabel,
                    style: AppTypography.monoCaption.copyWith(
                      color: isDisabled
                          ? const Color(0xFF333333)
                          : AppColors.concreteGrey,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Right indicator
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFD4FF00),
                ),
              )
            else
              Icon(
                Icons.send_rounded,
                size: 16,
                color: isDisabled
                    ? const Color(0xFF333333)
                    : const Color(0xFFD4FF00),
              ),
          ],
        ),
      ),
    );
  }
}
