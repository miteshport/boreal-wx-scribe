import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';

class NotificationService {
  NotificationService._internal();
  static final instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  final StreamController<String> _notificationTapStream = StreamController<String>.broadcast();
  Stream<String> get onNotificationTap => _notificationTapStream.stream;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // Assuming local timezone is what we want, or we could leave it as default local
    // tz.setLocalLocation(tz.getLocation('America/Toronto'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // We keep iOS/macOS empty for now or use default if we support them later.
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _notificationTapStream.add(response.payload!);
        }
      },
    );

    _initialized = true;
  }

  /// Polite runtime permission request flow. 
  /// Should be called after GPS lock is successful.
  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    // For exact alarms (if we need them for exact scheduling)
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// Persisted Anti-Hammering Engine:
  /// Checks SharedPreferences to enforce a strict 12-hour cooldown window per specific alert ID.
  Future<bool> _canFire(String alertId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFiredStr = prefs.getString('notif_cooldown_$alertId');
    if (lastFiredStr != null) {
      final lastFired = DateTime.parse(lastFiredStr);
      if (DateTime.now().difference(lastFired).inHours < 12) {
        return false; // In cooldown
      }
    }
    return true;
  }

  Future<void> _recordFire(String alertId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notif_cooldown_$alertId', DateTime.now().toIso8601String());
  }

  /// The Do-Not-Disturb Vault:
  /// No non-emergency notification is allowed to fire between 21:30 and 06:50 local time.
  bool _isWithinDndVault(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    // 21:30 to 23:59
    if (hour > 21 || (hour == 21 && minute >= 30)) return true;
    // 00:00 to 06:50
    if (hour < 6 || (hour == 6 && minute < 50)) return true;
    return false;
  }

  /// Schedules a notification for a specific future time.
  /// Enforces DND Vault and Anti-Hammering (cooldown).
  Future<void> scheduleNotification({
    required int id,
    required String alertId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool isEmergency = false,
  }) async {
    if (!isEmergency && _isWithinDndVault(scheduledTime)) {
      return; // Blocked by DND Vault
    }

    // Cooldown check applies to the scheduling moment or we could check at fire time,
    // but since we only schedule one ahead, if we've fired this recently, skip scheduling.
    if (!await _canFire(alertId)) {
      return;
    }

    final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return; // Cannot schedule in the past
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'weather_sync_ca_channel',
          'Weather & Lifestyle Alerts',
          channelDescription: 'Hyper-local weather and lifestyle recommendations',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: alertId,
    );

    // We record fire at schedule time to prevent scheduling multiple of the same type within 12h
    await _recordFire(alertId);
  }

  /// Fires a notification immediately (e.g. for severe real-time intercepts).
  Future<void> showInstantNotification({
    required int id,
    required String alertId,
    required String title,
    required String body,
    bool isEmergency = false,
  }) async {
    if (!isEmergency && _isWithinDndVault(DateTime.now())) {
      return;
    }

    if (!await _canFire(alertId)) {
      return;
    }

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'weather_sync_ca_channel_urgent',
          'Urgent Alerts',
          channelDescription: 'Critical weather intercepts',
          importance: Importance.max,
          priority: Priority.max,
          styleInformation: BigTextStyleInformation(''),
        ),
      ),
      payload: alertId,
    );

    await _recordFire(alertId);
  }
}
