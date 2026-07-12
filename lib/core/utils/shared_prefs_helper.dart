import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static Future<String?> getString(String key, {String? fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? fallback;
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<int?> getInt(String key, {int? fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? fallback;
  }

  static Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }
}
