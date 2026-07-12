import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:weather_sync_ca/services/boreal_content_engine.dart';

class WidgetSyncService {
  static Future<void> syncData({
    required Map<String, dynamic> payload,
  }) async {
    try {
      // 1. Generate Intelligence Payload with Safe Fallbacks
      final intel = await BorealContentEngine.getCanadianIntel(
        temperature: double.tryParse(
                payload['temp']?.toString().replaceAll('°', '') ?? '15.0') ??
            15.0,
        condition: payload['cond']?.toString() ?? 'CLEAR',
        aqhi: int.tryParse(payload['aqhi']?.toString() ?? '1') ?? 1,
        month: DateTime.now().month,
        isWeekend: DateTime.now().weekday >= 6,
        timeOfDay: payload['timeOfDay']?.toString() ?? 'Day',
        windSpeed:
            double.tryParse(payload['windSpeed']?.toString() ?? '10.0') ?? 10.0,
        windGust:
            double.tryParse(payload['windGust']?.toString() ?? '0.0') ?? 0.0,
        humidex:
            double.tryParse(payload['humidex']?.toString() ?? '0.0') ?? 0.0,
        precipitationProbability: double.tryParse(
                payload['precipitationProbability']?.toString() ?? '0.0') ??
            0.0,
        expectedRainfall:
            double.tryParse(payload['expectedRainfall']?.toString() ?? '0.0') ??
                0.0,
        snowfallAccumulation: double.tryParse(
                payload['snowfallAccumulation']?.toString() ?? '0.0') ??
            0.0,
      );

      // 2. Inject Native HUD Strings
      payload['widget_slang_headline'] = intel.slangHeadline;
      payload['widget_lifestyle_activity'] = intel.lifestyleActivity;
      payload['widget_newcomer_wisdom'] = intel.newcomerWisdom;

      final jsonString = jsonEncode(payload);
      await HomeWidget.saveWidgetData<String>(
          'widget_master_payload', jsonString);
      await HomeWidget.updateWidget(
        name: 'WeatherSyncWidgetProvider',
        iOSName: 'WeatherSyncWidget',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Widget Sync Error: $e');
      }
    }
  }
}
