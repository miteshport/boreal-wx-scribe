import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Checks if the SCHEDULE_EXACT_ALARM permission is granted using a native
/// platform channel. Returns true on Android versions below API 31 (where
/// exact alarms are automatically granted), and queries the system on API 31+.
class ExactAlarmPermission {
  static const MethodChannel _channel =
      MethodChannel('com.example.weather_sync_ca/exact_alarm');

  static Future<bool> isGranted() async {
    try {
      final bool? result = await _channel.invokeMethod('canScheduleExactAlarms');
      return result ?? true;
    } on MissingPluginException {
      // Channel not yet implemented on this platform (e.g. iOS, web)
      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openExactAlarmSettings');
    } catch (_) {
      // Fallback: open app settings
      await _channel.invokeMethod('openAppSettings');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONBOARDING CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

/// Neo-Brutalist onboarding card shown when SCHEDULE_EXACT_ALARM is denied.
/// Automatically hides itself when the user grants permission and resumes the app.
class ExactAlarmOnboardingCard extends StatefulWidget {
  const ExactAlarmOnboardingCard({super.key});

  @override
  State<ExactAlarmOnboardingCard> createState() =>
      _ExactAlarmOnboardingCardState();
}

class _ExactAlarmOnboardingCardState extends State<ExactAlarmOnboardingCard>
    with WidgetsBindingObserver {
  bool _isGranted = true;
  bool _isLoading = true;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called whenever the app lifecycle changes. When user returns from
  /// Android settings (resumed), re-check if they granted the permission.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final granted = await ExactAlarmPermission.isGranted();
    if (mounted) {
      setState(() {
        _isGranted = granted;
        _isLoading = false;
      });
    }
  }

  Future<void> _onEnableTap() async {
    await ExactAlarmPermission.openSettings();
    // Permission check on resume via didChangeAppLifecycleState
  }

  @override
  Widget build(BuildContext context) {
    // Hidden states: loading, granted, or user dismissed
    if (_isLoading || _isGranted || _dismissed) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border: Border.all(
            color: const Color(0xFFE6FF00).withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⏰',
              style: TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UNLOCK YOUR 7:00 AM CANADIAN BRIEFING',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE6FF00),
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To deliver exact morning weather intel without battery delays, Android requires you to enable Alarms & Reminders access.',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      color: const Color(0xFFFFFFFF).withValues(alpha: 0.65),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // CTA Button
                  GestureDetector(
                    onTap: _onEnableTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6FF00),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Text(
                        '[ ENABLE EXACT TIMING ]',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0A0A0A),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Dismiss X
            GestureDetector(
              onTap: () => setState(() => _dismissed = true),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
