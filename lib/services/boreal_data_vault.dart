import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BorealDataVault {
  static const String _borealMatrixUrl = 'https://miteshport.github.io/boreal-wx-scribe/boreal_matrix.json';
  static const String _cacheKey = 'boreal_matrix_cache';
  static const String _cacheTimeKey = 'boreal_matrix_cache_time';
  
  static String getRegionKey(double latitude, double longitude) {
    if (latitude >= 60.0) return 'the_north';
    if (longitude <= -115.0) return 'bc_coast';
    if (longitude > -115.0 && longitude <= -95.0) return 'prairies';
    if (longitude > -95.0 && longitude <= -70.0) return 'great_lakes';
    return 'east_coast';
  }

  static Future<Map<String, dynamic>?> fetchIntelligence() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Check Cache (2-hour TTL)
    final cachedTime = prefs.getInt(_cacheTimeKey);
    final cachedData = prefs.getString(_cacheKey);
    
    if (cachedTime != null && cachedData != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      // 2 hours = 7,200,000 ms
      if (now - cachedTime < 7200000) {
        try {
          return json.decode(cachedData);
        } catch (e) {
          // If JSON is corrupted, fallback to network
        }
      }
    }

    // 2. Fetch from Cloud
    try {
      final response = await http.get(Uri.parse(_borealMatrixUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        // Safe cache writing
        await prefs.setString(_cacheKey, response.body);
        await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
        return json.decode(response.body);
      }
    } catch (e) {
      // 3. Robust Fallback: Return stale cache if network fails
      if (cachedData != null) {
        try {
          return json.decode(cachedData);
        } catch (_) {}
      }
    }
    return null;
  }
}
