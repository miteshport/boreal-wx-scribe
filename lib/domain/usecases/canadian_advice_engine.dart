import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UrgencyLevel { normal, warning, actionRequired }

class AdviceResult {
  const AdviceResult({
    required this.category,
    required this.urgencyLevel,
    required this.title,
    required this.instruction,
    required this.explanation,
    required this.icon,
    this.isEasterEgg = false,
  });

  final AdviceCategory category;
  final UrgencyLevel urgencyLevel;
  final String title;
  final String instruction;
  final String explanation;
  final IconData icon;
  final bool isEasterEgg;
}

enum AdviceCategory {
  windowManagement('WINDOW MANAGEMENT'),
  snowShoveling('SNOW SHOVELING'),
  deIcing('DE-ICING'),
  vehiclePrep('VEHICLE PREP'),
  lifestyle('LIFESTYLE'),
  floodPrevention('FLOOD PREVENTION'),
  airQuality('AIR QUALITY'),
  easterEgg('CULTURAL ADVISORY'),
  summerSafety('SUMMER SAFETY');

  final String displayName;
  const AdviceCategory(this.displayName);
}

class CanadianAdviceParams {
  const CanadianAdviceParams({
    required this.temperatureC,
    required this.snowfallCm,
    required this.isSnowing,
    required this.currentHour,
    this.windChillC,
    this.uvIndex = 0.0,
    this.humidity = 50.0,
    this.isRaining = false,
    this.precipitationMm = 0.0,
    this.isFoggy = false,
    this.aqhi = 0.0,
    this.windGustKmh = 0.0,
    this.isFreezethaw = false,
  });

  final double temperatureC;
  final double snowfallCm;
  final bool isSnowing;
  final int currentHour;
  final double? windChillC;
  final double uvIndex;
  final double humidity;

  final bool isRaining;
  final double precipitationMm;
  final bool isFoggy;

  final double aqhi;
  final double windGustKmh;
  final bool isFreezethaw;
}

class CanadianAdviceEngine {
  final SharedPreferences prefs;
  final Random _random;

  CanadianAdviceEngine({required this.prefs, Random? random})
      : _random = random ?? Random();

  Future<List<AdviceResult>> generateAdvice(CanadianAdviceParams params) async {
    final List<AdviceResult> results = [];
    final currentMonth = DateTime.now().month;
    final isSummer = params.temperatureC > 15 || (currentMonth >= 6 && currentMonth <= 8);

    if (isSummer) {
      if (params.uvIndex >= 6) {
        results.add(AdviceResult(
          category: AdviceCategory.summerSafety,
          urgencyLevel: UrgencyLevel.warning,
          title: 'High UV Index',
          instruction: 'Apply sunscreen and wear a hat.',
          explanation: 'UV index is ${params.uvIndex.toStringAsFixed(1)}. Burn time is under 30 minutes.',
          icon: Icons.wb_sunny,
        ));
      }
      if (params.isRaining || params.precipitationMm > 5) {
        results.add(AdviceResult(
          category: AdviceCategory.vehiclePrep,
          urgencyLevel: UrgencyLevel.actionRequired,
          title: 'Hydroplaning Risk',
          instruction: 'Reduce speed on highways.',
          explanation: 'Heavy summer downpour increases hydroplaning risk on Hwy 400 and Hwy 11.',
          icon: Icons.water_drop,
        ));
      }
      if (params.temperatureC > 28) {
        results.add(AdviceResult(
          category: AdviceCategory.lifestyle,
          urgencyLevel: UrgencyLevel.warning,
          title: 'Extreme Heat',
          instruction: 'Stay hydrated and seek AC.',
          explanation: 'Temperatures are dangerously high. Perfect cottage weather, but avoid midday sun.',
          icon: Icons.thermostat,
        ));
      }
      if (results.isEmpty) {
        results.add(const AdviceResult(
          category: AdviceCategory.lifestyle,
          urgencyLevel: UrgencyLevel.normal,
          title: 'Clear Skies',
          instruction: 'Perfect patio weather.',
          explanation: 'Enjoy the great Canadian summer outdoors.',
          icon: Icons.deck,
        ));
      }
    } else {
      // Winter rules
      if (params.isSnowing || params.snowfallCm > 2) {
        results.add(const AdviceResult(
          category: AdviceCategory.snowShoveling,
          urgencyLevel: UrgencyLevel.actionRequired,
          title: 'Shovel Driveway',
          instruction: 'Clear snow promptly.',
          explanation: 'Heavy snowfall detected. Clear it before it freezes into ice.',
          icon: Icons.ac_unit,
        ));
      }
      if (params.temperatureC < -15) {
        results.add(const AdviceResult(
          category: AdviceCategory.vehiclePrep,
          urgencyLevel: UrgencyLevel.warning,
          title: 'Plug In Block Heater',
          instruction: 'Plug in your vehicle.',
          explanation: 'Temperatures below -15°C can freeze engine oil.',
          icon: Icons.directions_car,
        ));
      }
      if (params.isFreezethaw) {
        results.add(const AdviceResult(
          category: AdviceCategory.deIcing,
          urgencyLevel: UrgencyLevel.actionRequired,
          title: 'Black Ice Warning',
          instruction: 'Salt your walkways.',
          explanation: 'Freeze-thaw cycle creating dangerous black ice.',
          icon: Icons.severe_cold,
        ));
      }
      if (results.isEmpty) {
        results.add(const AdviceResult(
          category: AdviceCategory.lifestyle,
          urgencyLevel: UrgencyLevel.normal,
          title: 'Cold Day',
          instruction: 'Dress in layers.',
          explanation: 'Standard Canadian chill. Keep warm.',
          icon: Icons.ac_unit,
        ));
      }
    }

    if (params.windGustKmh > 70) {
      results.add(AdviceResult(
        category: AdviceCategory.windowManagement,
        urgencyLevel: UrgencyLevel.actionRequired,
        title: 'Secure Loose Items',
        instruction: 'Bring patio furniture inside.',
        explanation: 'Severe wind gusts up to ${params.windGustKmh.toStringAsFixed(0)} km/h.',
        icon: Icons.air,
      ));
    }

    return results;
  }
}
