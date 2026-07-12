import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreDataSource {
  static Future<void> syncRules() async {
    try {
      if (kIsWeb) {
        debugPrint('⚡ [FIRESTORE OTA]: Skipping remote fetch on Web test environment.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final snapshot = await FirebaseFirestore.instance
          .collection('canadian_survival_rules')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('active_variations')) {
          final variations = List<String>.from(data['active_variations'] as List);
          await prefs.setStringList('ota_rules_${doc.id}', variations);
        }
      }
      
      debugPrint('⚡ [FIRESTORE OTA]: Synced ${snapshot.docs.length} rules successfully.');
    } catch (e) {
      debugPrint('⚠️ [FIRESTORE OTA]: Could not reach cloud. Engine will use local/cached string arrays. Error: $e');
    }
  }

  /// Synchronously retrieves OTA variations for a given rule using a provided SharedPreferences instance.
  /// This integrates directly into `CanadianAdviceEngine`.
  static List<String> getOtaVariations(SharedPreferences prefs, String ruleId) {
    return prefs.getStringList('ota_rules_$ruleId') ?? [];
  }
}
