import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:weather_sync_ca/services/fcm_bridge_service.dart';
import 'package:weather_sync_ca/services/firestore_data_source.dart';

class FirebaseService {
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      
      // Wire in remote architecture bridges
      await FcmBridgeService.init();
      await FirestoreDataSource.syncRules();
      
      if (!kIsWeb) {
        // Enable Crashlytics only on native mobile builds
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        
        // Pass all uncaught fatal Flutter errors to Crashlytics
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };
      } else {
        debugPrint('⚡ [FIREBASE CORE]: Initialized safely in Web Dev Mode (Crashlytics bypassed).');
      }
    } catch (e) {
      debugPrint('⚠️ [FIREBASE INIT ERROR]: App will continue running offline/cached. Error: $e');
    }
  }
}
