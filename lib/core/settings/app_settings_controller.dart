// app_settings_controller.dart
//
// Global Application Settings — Bento Control Center State
// ─────────────────────────────────────────────────────────────────────────
// A lightweight ChangeNotifier that owns the two user-configurable settings:
//   1. [useFahrenheit] — toggles temperature display between °C and °F.
//   2. [hiddenActivities] — set of ActivityTypes the user has filtered out.
//
// All UI components subscribe via ListenableBuilder for instant,
// app-restart-free reactive updates when the user changes a setting.

import 'package:flutter/foundation.dart';
import 'package:weather_sync_ca/domain/usecases/activity_scoring_engine.dart';

class AppSettingsController extends ChangeNotifier {
  // ── Singleton ────────────────────────────────────────────────────────────
  static final AppSettingsController instance = AppSettingsController._();
  AppSettingsController._();

  // ── Setting 1: Temperature Unit ─────────────────────────────────────────
  bool _useFahrenheit = false;
  bool get useFahrenheit => _useFahrenheit;

  void toggleTemperatureUnit() {
    _useFahrenheit = !_useFahrenheit;
    notifyListeners();
  }

  /// Converts a raw Celsius value to the currently selected display unit.
  double convertTemp(double tempC) =>
      _useFahrenheit ? (tempC * 9 / 5) + 32 : tempC;

  /// Formats a Celsius value as a display string with the correct unit symbol.
  /// Pass [decimals] for fractional precision (default rounds to int).
  String formatTemp(double tempC, {bool showUnit = true}) {
    final converted = convertTemp(tempC);
    final symbol = showUnit ? (_useFahrenheit ? '°F' : '°C') : '°';
    return '${converted.round()}$symbol';
  }

  // ── Setting 2: Activity Filter ───────────────────────────────────────────
  final Set<ActivityType> _hiddenActivities = {};

  bool isActivityVisible(ActivityType type) =>
      !_hiddenActivities.contains(type);

  void toggleActivity(ActivityType type) {
    if (_hiddenActivities.contains(type)) {
      _hiddenActivities.remove(type);
    } else {
      _hiddenActivities.add(type);
    }
    notifyListeners();
  }

  /// Returns a filtered list of scores based on the current filter set.
  List<ActivityScore> filterScores(List<ActivityScore> scores) =>
      scores.where((s) => isActivityVisible(s.type)).toList();
}
