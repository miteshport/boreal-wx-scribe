import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:weather_sync_ca/services/live_weather_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// The entry point for the headless background execution.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Native called background task: $task");
    
    // Initialize required dependencies for background context
    tz_data.initializeTimeZones();
    final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
    
    // Initialize Local Notifications inside the background isolate
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings: initSettings);

    try {
      // 1. Fetch live telemetry (bypassing state management since this is headless)
      final service = LiveWeatherService();
      final telemetry = await service.fetchLiveWeather();
      
      if (telemetry == null) {
        debugPrint("Background fetch failed to get telemetry.");
        return Future.value(true);
      }

      final now = DateTime.now();
      
      // 2. Evaluate strict AI thresholds
      
      // RULE 1: Black Ice Trap
      // If it rained yesterday (simplification: rainMm > 0.5) and current temp < 0°C, and it's early morning
      if (now.hour >= 5 && now.hour <= 8) {
        if (telemetry.rainMm > 0.5 && telemetry.temperatureC < 0) {
          await _fireAlert(_plugin, 'black_ice', '🚨', 'FRONT STEP ALERT: SOLID ICE', 
            'It rained recently and temps have dropped below zero. Your walkways are currently a skating rink. Salt before you walk out!');
        }
      }
      
      // RULE 2: Wildfire Smoke Plume
      // In a real app we'd fetch AQHI API here. For now, simulate with a high wind/low humidity proxy or stub.
      // E.g., if UV is very low but it's middle of the day and hot (smoke blocking sun).
      if (telemetry.temperatureC > 25 && telemetry.windGustKmh > 50 && telemetry.humidity < 40) {
          await _fireAlert(_plugin, 'wildfire_smoke', '🔥', 'HIGH WIND & DRY HEAT', 
            'Dangerous fire weather conditions. Keep windows closed and monitor for smoke.');
      }
      
      // RULE 3: Night Flush (AC Saver)
      // Summer, indoor temp > outdoor temp.
      if (now.month >= 6 && now.month <= 9 && now.hour >= 19 && now.hour <= 22) {
        if (telemetry.temperatureC < 20) {
          await _fireAlert(_plugin, 'windows_down', '💨', 'THE OUTDOOR AIR JUST BROKE', 
            'Kill the AC and pop your windows right now for a perfect natural cooldown.');
        }
      }

      // RULE 4: Extreme Cold / Flash Freeze
      if (telemetry.temperatureC < -20 || (telemetry.apparentTempC < -25)) {
          await _fireAlert(_plugin, 'eccc_cryo', '❄️', 'CRYO-HAZARD DETECTED', 
            'Severe winter dynamics. Current wind chill is ${telemetry.apparentTempC.toStringAsFixed(0)}°C. Plug in block heaters.');
      }

    } catch (e) {
      debugPrint("Background task error: $e");
    }

    return Future.value(true);
  });
}

Future<void> _fireAlert(
  FlutterLocalNotificationsPlugin plugin,
  String channelId, 
  String emoji, 
  String title, 
  String body) async {
  
  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'boreal_sentinel_$channelId',
    'Boreal Sentinel Alerts',
    channelDescription: 'High-priority context-aware weather intelligence',
    importance: Importance.max,
    priority: Priority.max,
    icon: '@mipmap/launcher_icon',
  );
  
  NotificationDetails details = NotificationDetails(android: androidDetails);
  
  await plugin.show(
    id: channelId.hashCode,
    title: '$emoji  $title',
    body: body,
    notificationDetails: details,
  );
}

class BorealSentinelService {
  static Future<void> initialize() async {
    if (kIsWeb) return; // Workmanager not supported on web
    
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );

      // Register the periodic "Good Citizen" task every 2 hours
      await Workmanager().registerPeriodicTask(
        "boreal_sentinel_task",
        "weather_check",
        frequency: const Duration(hours: 2),
        constraints: Constraints(
          networkType: NetworkType.connected, // Only run if online
          requiresBatteryNotLow: true, // Don't run if battery is dying
        ),
      );
    } catch (e) {
      debugPrint("Sentinel initialization failed: $e");
    }
  }
}
