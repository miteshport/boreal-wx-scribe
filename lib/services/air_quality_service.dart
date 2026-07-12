/// air_quality_service.dart
///
/// Canadian AQHI (Air Quality Health Index) Engine
/// ─────────────────────────────────────────────────────────────────────────
/// Fetches real-time PM2.5, PM10, and UV Index from Open-Meteo's dedicated
/// Air Quality API endpoint (no API key required).
///
/// Endpoint: https://air-quality-api.open-meteo.com/v1/air-quality
///   ?latitude={lat}&longitude={lon}&current=pm10,pm2_5,uv_index
///
/// AQHI Calculation follows Environment Canada's official 1–10+ scale,
/// derived from PM2.5 fine particulate matter concentration.
///
/// Risk Tiers:
///   1–3  Low Risk      → PM2.5 < 15 µg/m³
///   4–6  Moderate      → PM2.5 15–30 µg/m³
///   7–10 High Risk     → PM2.5 30–50 µg/m³
///   10+  Very High     → PM2.5 > 50 µg/m³
library air_quality_service;

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AQHI RISK TIER
// ─────────────────────────────────────────────────────────────────────────────

enum AqhiRisk {
  low,       // 1–3
  moderate,  // 4–6
  high,      // 7–10
  veryHigh,  // 10+
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class AirQualityData {
  const AirQualityData({
    required this.pm2_5,
    required this.pm10,
    required this.uvIndex,
    required this.fetchTime,
  });

  /// Fine particulate matter (µg/m³) — primary wildfire smoke indicator.
  final double pm2_5;

  /// Coarse particulate matter (µg/m³).
  final double pm10;

  /// UV index from the air quality API (cross-checks weather UV).
  final double uvIndex;

  final DateTime fetchTime;

  // ── Canadian AQHI Calculation ─────────────────────────────────────────────

  /// Calculates the Canadian AQHI score (1–10+) from PM2.5 concentration.
  ///
  /// Mapping follows Environment Canada's official AQHI health risk bands.
  /// Returns a double so callers can display decimals or round as needed.
  double get aqhi => AqhiCalculator.fromPm2_5(pm2_5);

  /// Returns a clamped 1–10 integer for display (10+ is shown as 10+).
  int get aqhiDisplay => aqhi.round().clamp(1, 10);

  /// Whether this score is in the 10+ Very High band.
  bool get isVeryHigh => aqhi > 10;

  /// The risk tier for this reading.
  AqhiRisk get risk => AqhiCalculator.riskFromScore(aqhi);

  /// Short human-readable risk label.
  String get riskLabel => switch (risk) {
        AqhiRisk.low => 'LOW RISK',
        AqhiRisk.moderate => 'MODERATE RISK',
        AqhiRisk.high => 'HIGH RISK',
        AqhiRisk.veryHigh => 'VERY HIGH RISK',
      };

  /// Full display string e.g. "AQHI 3 — LOW RISK" or "AQHI 10+ — VERY HIGH RISK"
  String get displayLabel =>
      'AQHI ${isVeryHigh ? '10+' : aqhiDisplay} — $riskLabel';

  Map<String, dynamic> toJson() => {
        'pm2_5': pm2_5,
        'pm10': pm10,
        'uvIndex': uvIndex,
        'fetchTimeIso': fetchTime.toIso8601String(),
      };

  factory AirQualityData.fromJson(Map<String, dynamic> j) => AirQualityData(
        pm2_5: (j['pm2_5'] as num).toDouble(),
        pm10: (j['pm10'] as num).toDouble(),
        uvIndex: (j['uvIndex'] as num).toDouble(),
        fetchTime: DateTime.parse(j['fetchTimeIso'] as String),
      );

  /// Placeholder returned when the air quality API is unavailable.
  static AirQualityData placeholder() => AirQualityData(
        pm2_5: 5.0,
        pm10: 10.0,
        uvIndex: 3.0,
        fetchTime: DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// AQHI CALCULATOR
// ─────────────────────────────────────────────────────────────────────────────

class AqhiCalculator {
  AqhiCalculator._();

  /// Maps PM2.5 µg/m³ concentration to Canadian AQHI score (1.0–10.5+).
  ///
  /// Uses linear interpolation within each Environment Canada risk band
  /// to produce a smooth score rather than hard jumps between tiers.
  static double fromPm2_5(double pm2_5) {
    if (pm2_5 < 0) pm2_5 = 0;

    if (pm2_5 < 15) {
      // Low Risk: 1–3 mapped linearly across 0–14 µg/m³
      return 1.0 + (pm2_5 / 14.0) * 2.0;
    } else if (pm2_5 < 30) {
      // Moderate Risk: 4–6 mapped linearly across 15–29 µg/m³
      return 4.0 + ((pm2_5 - 15.0) / 15.0) * 2.0;
    } else if (pm2_5 <= 50) {
      // High Risk: 7–10 mapped linearly across 30–50 µg/m³
      return 7.0 + ((pm2_5 - 30.0) / 20.0) * 3.0;
    } else {
      // Very High: 10+ (uncapped — 100 µg/m³ → AQHI ~17)
      return 10.0 + ((pm2_5 - 50.0) / 25.0);
    }
  }

  /// Returns the AqhiRisk tier for a computed AQHI score.
  static AqhiRisk riskFromScore(double aqhi) {
    if (aqhi < 4) return AqhiRisk.low;
    if (aqhi < 7) return AqhiRisk.moderate;
    if (aqhi <= 10) return AqhiRisk.high;
    return AqhiRisk.veryHigh;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class AirQualityService {
  AirQualityService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 6),
            ));

  final Dio _dio;

  static const _baseUrl =
      'https://air-quality-api.open-meteo.com/v1/air-quality';

  /// Fetches current air quality for [lat]/[lon].
  /// Returns [AirQualityData.placeholder] on any network or parse error.
  Future<AirQualityData> fetchAirQuality({
    required double lat,
    required double lon,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'current': 'pm10,pm2_5,uv_index',
      });

      final response = await _dio.getUri<Map<String, dynamic>>(uri);
      final body = response.data;
      if (body == null) return AirQualityData.placeholder();

      final current = body['current'] as Map<String, dynamic>?;
      if (current == null) return AirQualityData.placeholder();

      return AirQualityData(
        pm2_5: (current['pm2_5'] as num?)?.toDouble() ?? 0.0,
        pm10: (current['pm10'] as num?)?.toDouble() ?? 0.0,
        uvIndex: (current['uv_index'] as num?)?.toDouble() ?? 0.0,
        fetchTime: DateTime.now(),
      );
    } on SocketException {
      return AirQualityData.placeholder();
    } on DioException {
      return AirQualityData.placeholder();
    } catch (_) {
      return AirQualityData.placeholder();
    }
  }
}
