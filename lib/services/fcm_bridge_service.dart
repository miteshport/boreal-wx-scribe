import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:weather_sync_ca/services/canadian_notification_engine.dart';
import 'package:weather_sync_ca/services/live_weather_service.dart';

class FcmBridgeService {
  static Future<void> init() async {
    try {
      if (kIsWeb) {
        debugPrint('⚡ [FCM BRIDGE]: Web push skipped (no VAPID key configured).');
        return;
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.data['action'] == 'silent_refresh') {
          // Trigger background weather refetch
          LiveWeatherService().fetchLiveWeather();
        } else if (message.data.containsKey('alert_title') &&
            message.data.containsKey('alert_body')) {
          // Parse string maps for Custom Toast
          final title = message.data['alert_title']!;
          final body = message.data['alert_body']!;
          final emoji = message.data['alert_emoji'] ?? '📡';
          final severityRaw = message.data['alert_severity'];

          NotificationSeverity severity = NotificationSeverity.info;
          if (severityRaw == 'warning') severity = NotificationSeverity.warning;
          if (severityRaw == 'critical') severity = NotificationSeverity.critical;

          CanadianNotificationEngine.instance.fire(
            CanadianToast(
              id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
              emoji: emoji,
              title: title,
              body: body,
              severity: severity,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('⚠️ [FCM BRIDGE ERROR]: $e');
    }
  }
}
