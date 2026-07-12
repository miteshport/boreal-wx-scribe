import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationEngine {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      // Leaving iOS init empty as this is currently focused on Android
    );
    await _plugin.initialize(settings: initSettings);
  }

  static Future<void> requestPermissions() async {
    try {
      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      // 1. Request standard notification permissions (Android 13+)
      await androidImplementation?.requestNotificationsPermission();
      // 2. Request exact alarm permissions (Android 12/13+ for scheduled alarms)
      await androidImplementation?.requestExactAlarmsPermission();
    } catch (e, st) {
      debugPrint('[NotificationEngine] permission request failed: $e');
      debugPrint('$st');
    }
  }

  static Future<void> initializeAndRequestPermissions({
    Future<void> Function()? initFunc,
    Future<void> Function()? requestPermissionsFunc,
  }) async {
    try {
      await (initFunc ?? init)();
      await (requestPermissionsFunc ?? requestPermissions)();
    } catch (e, st) {
      debugPrint('[NotificationEngine] initialization failed: $e');
      debugPrint('$st');
    }
  }

  /// Schedules the 3x Daily Guaranteed Intel local alarms to drive DAU.
  static Future<void> scheduleDailyIntelAlarms() async {
    // Clear previous scheduled alerts to prevent duplicates
    await _plugin.cancelAll();

    const androidDetails = AndroidNotificationDetails(
      'boreal_daily_intel',
      'Boreal Daily Intel',
      channelDescription: 'Guaranteed 3x Daily Weather Intelligence Briefings',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    const details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);

    // 1. 0700 HRS (Morning Intel)
    final morningIntel = [
      ("Morning Intel: Conditions Locked", "Review your commute intercept zones and grab a double-double before departure."),
      ("Frost Warning", "Where's your toque, eh? Check thermal layers before hitting the 401."),
      ("Morning Briefing", "Check the morning radar and your tactical timeline before stepping out.")
    ];

    // 2. 1600 HRS (Terminal Shift)
    final afternoonIntel = [
      ("Afternoon Transition Underway", "Check regional travel corridors and verify if it's a patio-beers kind of evening."),
      ("Quitting Time Weather", "Review the drive-home radar before you hit the highway."),
      ("Terminal Shift", "Evening transition initiated. Review the campfire clearance index.")
    ];

    // 3. 2000 HRS (Night Flush)
    final nightIntel = [
      ("Tomorrow's Matrix Stabilized", "Your tactical briefing for tomorrow is ready. Time to prep the block heater?"),
      ("Night Flush Complete", "The 24-hour intel is locked in. Let's see if tomorrow is a prime two-four day."),
      ("Next-Day Horizon", "Conditions established for tomorrow. Review the tactical summary.")
    ];

    // Helper function to schedule a specific time with a random copy based on day of year to cycle them naturally
    Future<void> scheduleForTime(int id, int hour, List<(String, String)> pool) async {
      tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      // Use Day of the month to cycle through the messages so they rotate every day but remain consistent across reboots
      final copyIndex = scheduledDate.day % pool.length;
      final copy = pool[copyIndex];

      await _plugin.zonedSchedule(
        id: id,
        title: copy.$1,
        body: copy.$2,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Re-trigger daily
      );
    }

    try {
      await scheduleForTime(100, 7, morningIntel);
      await scheduleForTime(101, 16, afternoonIntel);
      await scheduleForTime(102, 20, nightIntel);
      debugPrint('[NotificationEngine] 3x Daily Intel successfully scheduled.');
    } catch (e) {
      debugPrint('[NotificationEngine] Failed to schedule exact alarms: $e');
    }
  }
}
