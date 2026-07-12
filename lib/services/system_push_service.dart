// system_push_service.dart
//
// Canadian Notification Engine — System Tray Push Layer
// ─────────────────────────────────────────────────────────────────────────
// Wraps flutter_local_notifications v22 to deliver real Android system-tray
// notifications (lock screen, notification shade) without Firebase/FCM.
//
// v22 API notes:
//   - FlutterLocalNotificationsPlugin.initialize() takes named `settings:` param.
//   - FlutterLocalNotificationsPlugin.show() takes all named params.
//   - Color is dart:ui — not flutter/material.dart.
//
// Architecture: Singleton initialised once in main(). 4 archetype methods
// can be called from any widget context without async ceremony.
//
// Android Channel: "weathersync_ca_alerts" — High importance, full sound.
// Permission: Deferred to first user interaction (Demo Panel). Never asked
// on cold start.

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const String _kChannelId = 'weathersync_ca_alerts';
const String _kChannelName = 'WeatherSync CA Alerts';
const String _kChannelDesc =
    'Privacy-first Canadian weather & lifestyle alerts — no cloud required.';

// Solar-Yellow accent: ARGB 0xFFD4FF00
const Color _kAccentColor = Color(0xFFD4FF00);

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class SystemPushService {
  SystemPushService._();
  static final SystemPushService instance = SystemPushService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;
  int _nextId = 1;

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Initialise the plugin and create the Android notification channel.
  /// Idempotent — subsequent calls are no-ops.
  Future<void> init() async {
    if (_initialised) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    // v22: initialize takes a named `settings:` parameter
    await _plugin.initialize(settings: initSettings);
    await _ensureChannel();

    _initialised = true;
    debugPrint('[SystemPushService] Initialised. Channel: $_kChannelId');
  }

  /// Request Android 13+ runtime POST_NOTIFICATIONS permission.
  /// Returns true if granted. Call at first user interaction, not cold start.
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;
    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  // ── Core show ─────────────────────────────────────────────────────────────

  /// Fires a notification immediately to the system tray.
  /// Same [id] replaces an existing notification (deduplication).
  Future<void> showNotification({
    int? id,
    required String title,
    required String body,
  }) async {
    if (!_initialised) await init();

    final notifId = id ?? _nextId++;

    // BigTextStyleInformation: allows expanded long-body view in the shade.
    final bigTextStyle = BigTextStyleInformation(body);

    final androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: _kAccentColor,
      styleInformation: bigTextStyle,
    );

    final details = NotificationDetails(android: androidDetails);

    // v22: show() takes all named parameters
    await _plugin.show(
      id: notifId,
      title: title,
      body: body,
      notificationDetails: details,
    );

    debugPrint('[SystemPushService] Fired id=$notifId "$title"');
  }

  // ── 4 Canadian Archetype Payloads ─────────────────────────────────────────

  /// Archetype 1: Morning Window & Wardrobe (7:15 AM Utility)
  Future<void> fireMorningWindow() => showNotification(
        id: 101,
        title: 'Prime Canadian Clear Skies ☀️',
        body: 'Wind is dead calm today! Open windows now for early morning '
            "cross-ventilation. It's two-four time later on the patio, bud.",
      );

  /// Archetype 2: Home Energy Defender (Humidex / Black Ice)
  Future<void> fireEnergyDefender() => showNotification(
        id: 102,
        title: 'Humidex Vault Active: Lock It In! 🚨',
        body: 'Great Lake humidity is making 28°C feel like 38°C across '
            'Southgate. Close south-facing blinds now to block solar heat '
            'gain and save AC costs!',
      );

  /// Archetype 3: Weekend Wilderness & Fire Guide
  Future<void> fireWildernessAlert() => showNotification(
        id: 103,
        title: 'High Wind Warning: Spark Hazard ⛺',
        body: 'Wind gusts exceeding 30 km/h detected. No open campfires! '
            'Check municipal fire bans and keep your stick on the ice.',
      );

  /// Archetype 4: Official ECCC Severe Weather Alert
  Future<void> fireEcccSevereAlert() => showNotification(
        id: 104,
        title: 'ECCC Orange Warning: Blizzard 🛑',
        body: 'Major winter disruption incoming. Zero visibility expected — '
            'secure outdoor property and avoid regional travel unless critical.',
      );

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _ensureChannel() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    const channel = AndroidNotificationChannel(
      _kChannelId,
      _kChannelName,
      description: _kChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(channel);
    debugPrint('[SystemPushService] Channel ensured: $_kChannelId');
  }
}
