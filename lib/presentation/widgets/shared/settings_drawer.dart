/// settings_drawer.dart
///
/// Sleek sliding settings panel for unit configuration (°C / °F).
/// Persists user preference via SharedPreferences under key 'unit_is_celsius'.
/// Uses an AnimatedContainer slide + FadeTransition for buttery-smooth entry.
///
/// Agent Sync Note:
///   This widget is self-contained. The parent must pass [isCelsius] state
///   and an [onToggle] callback. SharedPreferences writes happen INSIDE this
///   widget, immediately after the toggle, so the preference is always saved.
library settings_drawer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC ENTRY POINT — show the panel as a bottom sheet overlay
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showSettingsDrawer(
  BuildContext context, {
  required bool isCelsius,
  required ValueChanged<bool> onToggle,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black87,
    builder: (_) => _SettingsDrawerSheet(
      isCelsius: isCelsius,
      onToggle: onToggle,
    ),
  );
}

class _SettingsDrawerSheet extends StatefulWidget {
  final bool isCelsius;
  final ValueChanged<bool> onToggle;
  const _SettingsDrawerSheet({required this.isCelsius, required this.onToggle});

  @override
  State<_SettingsDrawerSheet> createState() => _SettingsDrawerSheetState();
}

class _SettingsDrawerSheetState extends State<_SettingsDrawerSheet>
    with SingleTickerProviderStateMixin {
  late bool _isCelsius;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _isCelsius = widget.isCelsius;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleToggle(bool val) async {
    setState(() => _isCelsius = val);
    widget.onToggle(val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('unit_is_celsius', val);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF2C2C2C)),
              left: BorderSide(color: Color(0xFF2C2C2C)),
              right: BorderSide(color: Color(0xFF2C2C2C)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.borderActive,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'SETTINGS',
                style: AppTypography.monoCaption.copyWith(
                  color: AppColors.concreteGrey,
                  letterSpacing: 4,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 24),

              // ── UNIT TOGGLE ROW ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  border: Border.all(color: AppColors.borderStroke),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TEMPERATURE UNIT',
                            style: AppTypography.monoCaption.copyWith(
                              color: AppColors.pureWhite,
                              letterSpacing: 2,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isCelsius
                                ? 'Displaying in Celsius (°C)'
                                : 'Displaying in Fahrenheit (°F)',
                            style: AppTypography.monoCaption.copyWith(
                              color: AppColors.concreteGrey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Segmented C/F toggle
                    _UnitSegmentedControl(
                      isCelsius: _isCelsius,
                      onToggle: _handleToggle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Hint text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Preference is saved automatically and persists between app launches.',
                  style: AppTypography.monoCaption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    height: 1.6,
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
// SEGMENTED CONTROL — °C / °F pill toggle
// ─────────────────────────────────────────────────────────────────────────────

class _UnitSegmentedControl extends StatelessWidget {
  final bool isCelsius;
  final ValueChanged<bool> onToggle;

  const _UnitSegmentedControl({required this.isCelsius, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        border: Border.all(color: AppColors.borderStroke),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Pill(label: '°C', isActive: isCelsius, onTap: () => onToggle(true)),
          _Pill(label: '°F', isActive: !isCelsius, onTap: () => onToggle(false)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Pill({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE6FF00) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isActive ? AppColors.voidBlack : AppColors.concreteGrey,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNIT CONVERSION HELPER — pure utility, no Flutter imports needed
// ─────────────────────────────────────────────────────────────────────────────

abstract final class TemperatureUnit {
  /// Converts [celsius] to the display string: "23°C" or "73°F"
  static String format(double celsius, {required bool isCelsius}) {
    if (isCelsius) return '${celsius.round()}°';
    final f = celsius * 9 / 5 + 32;
    return '${f.round()}°';
  }

  /// Returns "°C" or "°F" label
  static String symbol({required bool isCelsius}) => isCelsius ? '°C' : '°F';

  /// Converts celsius value to fahrenheit double
  static double toFahrenheit(double celsius) => celsius * 9 / 5 + 32;
}
