import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_sync_ca/services/live_weather_service.dart';
import 'package:weather_sync_ca/services/notification_service.dart';

class NotificationScheduler {
  static Future<void> evaluateLiveTelemetry(LiveWeatherData data) async {
    final now = DateTime.now();
    final service = NotificationService.instance;

    // Initialize notification service if not done already
    await service.init();

    // ECCC PRIORITY ROUTER & DEDUPLICATION
    bool suppressedByEccc = await _evaluateEcccAlertRouter(data, service, now);

    // If a major Red/Orange ECCC event is dominating the area, we suppress
    // lower-tier lifestyle notifications to prevent alert fatigue.
    if (!suppressedByEccc) {
      // TIER 1: The Expected (7:00 AM Daily Morning Briefing)
      await _scheduleMorningBriefing(data, service, now);

      // TIER 2: The Unexpected "Nice Update" (Real-Time Utility)
      await _evaluateAcFlush(data, service, now);
      await _evaluateFridayEscape(data, service, now);

      // TIER 3: The Critical Intercepts (Harsh Weather Safety)
      // (Flash Flood removed since Rainstorm is handled by ECCC router)
      await _evaluateWinterShovel(data, service, now);
      await _evaluateBlockHeater(data, service, now);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ECCC ALERT ROUTER (Priority & Deduplication)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<bool> _evaluateEcccAlertRouter(
      LiveWeatherData data, NotificationService service, DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Evaluate 6-hour snowfall accumulation
    double snow6hr = 0.0;
    for (var h in data.hourlyForecasts.take(6)) {
      snow6hr += (h.precipitationMm ?? 0);
    }

    // 1. Evaluate Red/Orange Hazards (Cryo & Convective)
    bool isCryoRed = snow6hr >= 5.0 || 
                     data.temperatureC <= -25.0 || // approximation for wind chill
                     data.conditionString.toUpperCase().contains('FREEZING');
                     
    bool isConvectiveRed = data.windSpeedKmh >= 40.0 || 
                           (data.windGustKmh ?? 0) >= 60.0 || 
                           (data.humidex ?? 0) >= 35.0;

    bool triggeredRedOrange = false;

    if (isCryoRed) {
      await service.showInstantNotification(
        id: 901,
        alertId: 'eccc_cryo_red',
        title: '🔴 ECCC WARNING: Severe Cryo-Hazard',
        body: 'Extreme winter dynamics active in your region. Limit outdoor exposure.',
        isEmergency: true,
      );
      triggeredRedOrange = true;
    } else if (isConvectiveRed) {
      await service.showInstantNotification(
        id: 902,
        alertId: 'eccc_convective_red',
        title: '🔴 ECCC WARNING: Severe Convective Storm',
        body: 'High winds or severe humidex active. Secure patio furniture and prepare for flickers.',
        isEmergency: true,
      );
      triggeredRedOrange = true;
    }

    if (triggeredRedOrange) {
      // Record global timestamp for device location
      await prefs.setString('eccc_last_red_orange', now.toIso8601String());
      return true; // Suppress lower-tier alerts
    }

    // 2. Deduplication Check
    final lastRedOrangeStr = prefs.getString('eccc_last_red_orange');
    if (lastRedOrangeStr != null) {
      final lastRedOrange = DateTime.parse(lastRedOrangeStr);
      if (now.difference(lastRedOrange).inMinutes < 120) {
        // A Red/Orange alert fired in the last 120 minutes. Suppress Yellow/Info.
        return true; 
      }
    }

    // 3. Evaluate Yellow / Informational Hazards (Atmospheric & Rainstorm)
    // We proxy AQHI via data.aqhiDisplay if available, otherwise assume 1.
    // For this simulation/engine, we check conditions.
    bool isAtmosphericYellow = data.conditionString.toUpperCase().contains('FOG'); // We don't have raw AQHI here, just condition.
    
    // Rainstorm: (precipitationProbability >= 75) && (expectedRainfall >= 3.0)
    bool isRainstormYellow = data.precipitationProbabilityPct >= 75 && data.precipitationMm >= 3.0;

    if (isAtmosphericYellow) {
      await service.showInstantNotification(
        id: 903,
        alertId: 'eccc_atmospheric_yellow',
        title: '🟡 ECCC ADVISORY: Atmospheric Hazard',
        body: 'Visibility dropping or poor air quality detected. Keep headlights low.',
        isEmergency: false,
      );
    } else if (isRainstormYellow) {
      await service.showInstantNotification(
        id: 904,
        alertId: 'eccc_rainstorm_yellow',
        title: '🟡 ECCC ADVISORY: Heavy Rainstorm',
        body: 'Heavy downpours expected shortly. Delay non-essential driving and watch for pooling.',
        isEmergency: false,
      );
    }

    return false; // Did not suppress TIER 1/2/3 lifestyle alerts
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LIFESTYLE TIER ROUTINES (Unchanged behavior)
  // ──────────────────────────────────────────────────────────────────────────

  static Future<void> _scheduleMorningBriefing(
      LiveWeatherData data, NotificationService service, DateTime now) async {
    final next7amIdx = data.hourlyForecasts.indexWhere(
        (h) => h.time.hour == 7 && h.time.isAfter(now));
    
    if (next7amIdx == -1) return;
    
    final next7am = data.hourlyForecasts[next7amIdx];

    String title = 'Morning Briefing';
    String body = '';

    bool hasHighWind = false;
    double maxGust = 0.0;
    for (var h in data.hourlyForecasts) {
      if (h.time.day == next7am.time.day && h.time.hour >= 7 && h.time.hour <= 19) {
        if ((h.windGustKmh ?? 0) > 50) {
          hasHighWind = true;
          if (h.windGustKmh! > maxGust) maxGust = h.windGustKmh!;
        }
      }
    }

    if (hasHighWind) {
      title = '⚠️ High Wind Alert';
      body = '⚠️ High Wind Alert today. Secure your patio furniture and garbage bins. Expect severe gusts up to ${maxGust.round()} km/h by afternoon.';
    } else if (next7am.temperatureC > 20) {
      final h = next7am.humidex;
      final humStr = h != null ? ' (Humidex ${h.round()})' : '';
      body = 'Good morning! High of ${next7am.temperatureC.round()}°C today$humStr. Wind is calm—perfect evening to fire up the backyard BBQ after work.';
    } else {
      body = 'Good morning! High of ${next7am.temperatureC.round()}°C today. Have a great day.';
    }

    await service.scheduleNotification(
      id: 1,
      alertId: 'morning_briefing_${next7am.time.day}',
      title: title,
      body: body,
      scheduledTime: next7am.time,
    );
  }

  static Future<void> _evaluateAcFlush(
      LiveWeatherData data, NotificationService service, DateTime now) async {
    double maxTempToday = data.temperatureC;
    for (var h in data.hourlyForecasts) {
      if (h.time.day == now.day && h.time.hour < 19) {
        if (h.temperatureC > maxTempToday) maxTempToday = h.temperatureC;
      }
    }

    if (maxTempToday > 25.0) {
      for (var h in data.hourlyForecasts) {
        if (h.time.day == now.day && h.time.hour >= 19 && h.time.hour <= 21) {
          if (h.temperatureC < 20.0 && h.time.isAfter(now)) {
            await service.scheduleNotification(
              id: 2,
              alertId: 'ac_flush_${now.day}',
              title: '🏡 Open the windows!',
              body: 'Outdoor air just dipped to ${h.temperatureC.round()}°C. Pop your front and back windows right now for a natural cross-ventilation house flush and save on your AC bill.',
              scheduledTime: h.time,
            );
            break;
          }
        }
      }
    }
  }

  static Future<void> _evaluateFridayEscape(
      LiveWeatherData data, NotificationService service, DateTime now) async {
    final nextFriday16 = data.hourlyForecasts.firstWhere(
      (h) => h.time.weekday == DateTime.friday && h.time.hour == 16 && h.time.isAfter(now),
      orElse: () => data.hourlyForecasts.first,
    );
    
    if (nextFriday16.time.weekday != DateTime.friday || nextFriday16.time.hour != 16) return;

    bool goodPatio = nextFriday16.temperatureC > 18 && 
                     nextFriday16.precipitationProbabilityPct < 20 &&
                     (nextFriday16.windGustKmh ?? 0) < 30;

    if (goodPatio) {
      await service.scheduleNotification(
        id: 3,
        alertId: 'friday_escape_${nextFriday16.time.day}',
        title: '☀️ 10/10 Weekend patio weather locked in',
        body: '☀️ 10/10 Weekend patio weather locked in. Wind is dead calm and clear. Two-four time, bud.',
        scheduledTime: nextFriday16.time,
      );
    }
  }

  static Future<void> _evaluateWinterShovel(
      LiveWeatherData data, NotificationService service, DateTime now) async {
    DateTime? stopTime;
    double freezeTemp = 0.0;
    bool wasSnowing = data.isSnowing;
    
    for (var h in data.hourlyForecasts) {
      bool hSnowing = h.weatherCode == 71 || h.weatherCode == 73 || h.weatherCode == 75 || h.weatherCode == 85 || h.weatherCode == 86;
      if (wasSnowing && !hSnowing && stopTime == null && h.time.isAfter(now)) {
        stopTime = h.time;
      }
      if (stopTime != null && h.time.isAfter(stopTime)) {
        if (h.temperatureC < -5.0) {
          freezeTemp = h.temperatureC;
          break;
        }
      }
      if (hSnowing) wasSnowing = true;
    }

    if (stopTime != null && freezeTemp < -5.0) {
      await service.scheduleNotification(
        id: 5,
        alertId: 'winter_shovel_${stopTime.day}',
        title: '❄️ Shovel Alert',
        body: '❄️ Shovel Alert: Heavy snow is stopping. Clear the drive by 8:00 PM tonight before the temperature plunges to ${freezeTemp.round()}°C and freezes this slush into solid concrete.',
        scheduledTime: stopTime,
      );
    }
  }

  static Future<void> _evaluateBlockHeater(
      LiveWeatherData data, NotificationService service, DateTime now) async {
    final targetTime = DateTime(now.year, now.month, now.day, 20, 30);
    if (now.isAfter(targetTime)) return;
    
    double minTemp = 0.0;
    for (var h in data.hourlyForecasts) {
      if (h.time.isAfter(targetTime) && h.time.isBefore(targetTime.add(const Duration(hours: 12)))) {
        if (h.temperatureC < minTemp) {
          minTemp = h.temperatureC;
        }
      }
    }

    if (minTemp < -20.0) {
      await service.scheduleNotification(
        id: 6,
        alertId: 'block_heater_${now.day}',
        title: '🥶 Deep Freeze Alert',
        body: '🥶 Deep Freeze Alert: Temperatures plunging to ${minTemp.round()}°C tonight. Plug in your vehicle\'s block heater before bed to guarantee a clean start tomorrow morning.',
        scheduledTime: targetTime,
      );
    }
  }
}
