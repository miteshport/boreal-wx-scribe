import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:weather_sync_ca/services/boreal_data_vault.dart';

class CanadianIntelPayload {
  final String slangHeadline;
  final String lifestyleActivity;
  final String newcomerWisdom;
  final String? escapeManifest;
  final String? roadTripSlang;

  const CanadianIntelPayload({
    required this.slangHeadline,
    required this.lifestyleActivity,
    required this.newcomerWisdom,
    this.escapeManifest,
    this.roadTripSlang,
  });
}

class BorealContentEngine {
  static const String _cacheKey = 'boreal_matrix_cache';

  static String _mapConditionToCategory(String activeProfileId, String condition, double tempC) {
    final condUpper = condition.toUpperCase();
    if (activeProfileId == 'wildfireSmokeHigh' || condUpper.contains('SMOKE') || condUpper.contains('HAZE')) {
      return 'smoke';
    }
    if (activeProfileId == 'deepWinterBlizzard' || activeProfileId == 'shoulderFreezeThaw' || tempC <= -15.0 || condUpper.contains('FREEZ') || condUpper.contains('SNOW') || condUpper.contains('BLIZZARD')) {
      return 'cryo';
    }
    if (activeProfileId == 'extremeHeatHumidex' || tempC >= 32.0 || condUpper.contains('HEAT')) {
      return 'heat';
    }
    if (activeProfileId == 'heavyRainDownpour' || activeProfileId == 'severeWindstorm' || condUpper.contains('RAIN') || condUpper.contains('WIND') || condUpper.contains('STORM')) {
      return 'storm';
    }
    return 'clear';
  }

  static Future<CanadianIntelPayload> getCanadianIntel({
    required double latitude,
    required double longitude,
    required double temperature,
    required String condition,
    required int aqhi,
    required int month,
    required bool isWeekend,
    required String timeOfDay,
    required double windSpeed,
    required double windGust,
    required double humidex,
    required double precipitationProbability,
    required double expectedRainfall,
    required double snowfallAccumulation,
    String? activeProfileId,
  }) async {
    final condUpper = condition.toUpperCase();
    Map<String, dynamic>? json;

    // 📡 1. THE HYBRID COLD-START FETCH ENGINE
    try {
      final response = await http
          .get(Uri.parse(
              'https://miteshport.github.io/boreal-wx-scribe/boreal_matrix.json'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        json = jsonDecode(response.body);
        // Cache the successful payload
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, response.body);
        } catch (_) {}
      }
    } catch (e) {
      print('[Boreal Engine]: Cloud asset fetch failed. Attempting local cache. ($e)');
    }

    // 💾 2. LOCAL CACHE FALLBACK
    if (json == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString(_cacheKey);
        if (cached != null) {
          json = jsonDecode(cached);
          print('[Boreal Engine]: Loaded matrix from local cache.');
        }
      } catch (_) {}
    }

    // 🧠 3. THE MULTI-REGIONAL MATRIX PARSER
    if (json != null) {
      try {
        // Resolve dynamic region and condition category
        final regionKey = BorealDataVault.getRegionKey(latitude, longitude);
        final categoryKey = _mapConditionToCategory(activeProfileId ?? '', condition, temperature);
        
        final regionNode = json[regionKey];
        if (regionNode != null) {
          final node = regionNode[categoryKey];
          
          if (node != null) {
            String wisdomStr = node['survival_guide'] ?? "Ensure telemetry checks.";
            if (json['cultural_pulse'] != null) {
               final histFact = json['cultural_pulse']['historical_fact'];
               if (histFact != null) {
                 wisdomStr = "$wisdomStr\n\n🇨🇦 Pulse: $histFact";
               }
            }
            
            return CanadianIntelPayload(
              slangHeadline: node['notification'] ?? "Cloud Matrix Extracted.",
              lifestyleActivity: node['condition'] ?? "Data synchronized.",
              newcomerWisdom: wisdomStr,
              escapeManifest: node['escape_manifest'],
              roadTripSlang: node['slang_hud'],
            );
          }
        }
      } catch (e) {
        print('[Boreal Engine]: Matrix parsing error: $e');
      }
    }

    // 🛠️ 4. LOCAL FALLBACK EVALUATION REFACTOR
    // Evaluate raw telemetry into strict guard clauses

    if (activeProfileId == 'clearNightStarry' ||
        (timeOfDay == 'Night' && condUpper.contains('CLEAR'))) {
      return const CanadianIntelPayload(
        slangHeadline:
            "Crisp, clear Canadian night. Keep an eye out for the Northern Lights.",
        lifestyleActivity: "Perfect stargazing or backyard firepit weather.",
        newcomerWisdom:
            "Northern Night Thermal Drops: Inland Canadian regions can experience massive 15°C temperature swings the moment the sun sets. Always pack a thermal mid-layer when heading out.",
        escapeManifest: "Visibility is maximum. Watch for moose on the dark highways.",
        roadTripSlang: "Klicks: Canadian slang for kilometres. e.g. 'The cottage is 40 klicks down the highway.'",
      );
    }

    // ❄️ BUCKET 1: CRYO-HAZARDS (Winter & Ice)
    bool isCryo = activeProfileId == 'deepWinterBlizzard' ||
        activeProfileId == 'shoulderFreezeThaw' ||
        snowfallAccumulation >= 5.0 ||
        temperature <= -25.0 ||
        condUpper.contains('FREEZING') ||
        condUpper.contains('BLIZZARD') ||
        condUpper.contains('SQUALL');

    if (isCryo) {
      return const CanadianIntelPayload(
        slangHeadline:
            "ECCC CRYO-HAZARD: Absolute toque and parka weather. Drive with extreme caution.",
        lifestyleActivity:
            "Plug in the block heater. Keep exposure under 10 minutes. Watch for invisible black ice on walkways.",
        newcomerWisdom:
            "Cryo-Hazard Physics: At -25°C and below, plug your vehicle block heater into a home outlet for at least 2 hours before starting. When driving on black ice, braking distances triple. Never use vehicle cruise control during a freezing rain event.",
        escapeManifest: "Black ice probability high. Quadruple braking distances. Consider postponing non-essential highway travel.",
        roadTripSlang: "Toque: A knit winter hat. Absolutely essential for outdoor survival.",
      );
    }

    if (activeProfileId == 'extremeHeatHumidex' ||
        temperature >= 32.0 ||
        humidex >= 35.0) {
      return const CanadianIntelPayload(
        slangHeadline:
            "Scorcher Alert: High heat and humidex conditions locked in.",
        lifestyleActivity:
            "Peak humidex. Deploy umbrellas, stay hydrated, and avoid peak sun hours.",
        newcomerWisdom:
            "Thermal Protection: Protect pets from hot asphalt. Keep your AC units or fans circulating, and watch for power grid flickers during extreme grid load.",
        escapeManifest: "Ensure vehicle coolant levels are topped up to prevent highway radiator blowouts.",
        roadTripSlang: "Two-Four: A case of 24 beers, standard issue for a long summer weekend.",
      );
    }

    // ⛈️ BUCKET 2: CONVECTIVE STORM HAZARDS (Isolated from heat)
    bool isConvective = activeProfileId == 'galeWindstorm' ||
        windSpeed >= 40.0 ||
        windGust >= 60.0 ||
        condUpper.contains('THUNDERSTORM') ||
        condUpper.contains('TORNADO') ||
        condUpper.contains('HAIL');

    if (isConvective) {
      return const CanadianIntelPayload(
        slangHeadline:
            "ECCC CONVECTIVE HAZARD: Severe summer storm dynamics locked in.",
        lifestyleActivity:
            "Check your basement sump pump. Tie down patio furniture and secure the BBQ cover immediately.",
        newcomerWisdom:
            "Convective Defense: High winds frequently snap heavy tree branches onto overhead power lines in suburban areas. Keep a charged power bank ready for grid flickers.",
        escapeManifest: "High lateral wind shear risk for large vehicles. Avoid heavily treed secondary routes.",
        roadTripSlang: "Washout: When heavy continuous rain ruins all outdoor plans for the day.",
      );
    }

    // 🌫️ BUCKET 3: ATMOSPHERIC & COASTAL HAZARDS
    bool isAtmospheric = activeProfileId == 'wildfireSmokeHigh' ||
        activeProfileId == 'heavyRainDownpour' ||
        aqhi >= 4 ||
        condUpper.contains('FOG') ||
        (precipitationProbability >= 75.0 && expectedRainfall >= 3.0);

    if (isAtmospheric) {
      return const CanadianIntelPayload(
        slangHeadline:
            "ECCC ATMOSPHERIC HAZARD: Visibility dropping. Absolute rubber boot weather.",
        lifestyleActivity:
            "Flash flooding possible in low-lying areas. Seal house windows if smoke drifts in.",
        newcomerWisdom:
            "Atmospheric Dynamics: Never use high-beam headlights in dense Canadian river-valley fog. If AQHI is high, standard surgical masks do not filter wildfire smoke—wear an N95. On wet highways, ease off the accelerator to combat hydroplaning.",
        escapeManifest: "Heavy rain causes hydroplaning. Reduce speed by 20 klicks and leave extra stopping distance.",
        roadTripSlang: "Hydroplaning: When your tires lose contact with the road on standing water.",
      );
    }

    // 📡 BUCKET 4: INFORMATIONAL & EARLY ADVISORIES (Shoulder Season)
    bool isInformational = (month >= 10 || month <= 4) &&
        (temperature > 0.0 && temperature <= 7.5);

    if (isInformational) {
      return const CanadianIntelPayload(
        slangHeadline: "ECCC ADVISORY: Shoulder season thermal swings inbound.",
        lifestyleActivity:
            "Welcome to the 5th Canadian Season. Watch for deep craters on township secondary roads.",
        newcomerWisdom:
            "Thermal Transitions: All-season rubber compounds begin to harden and lose mechanical braking traction the moment asphalt drops below +7°C.",
        escapeManifest: "Watch out for deep potholes formed by the aggressive freeze-thaw cycles on secondary highways.",
        roadTripSlang: "Pothole Season: The period in spring when roads break apart due to ice melting.",
      );
    }

    return const CanadianIntelPayload(
      slangHeadline:
          "Atmospheric conditions standard. Grab a Double-Double and enjoy the day.",
      lifestyleActivity:
          "Great day to run local errands or plan basic outdoor maintenance.",
      newcomerWisdom:
          "Canadian Thermal Transitions: Even on clear, stable days, inland northern regions experience sharp thermal drops immediately following sunset. Always pack an extra layer or a trusted flannel in your vehicle trunk.",
      escapeManifest: "Standard driving conditions. Ensure windshield washer fluid is topped up.",
      roadTripSlang: "Double-Double: A staple Canadian coffee order consisting of two creams and two sugars.",
    );
  }
}
