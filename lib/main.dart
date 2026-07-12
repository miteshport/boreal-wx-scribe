// main.dart
//
// Application Bootstrap Entry Point
// ─────────────────────────────────────────────────────────────────────────
// This file handles the complete app startup sequence in a strictly
// ordered, error-guarded pipeline:
//
//   1. [WidgetsFlutterBinding.ensureInitialized()]
//      — Must be called before any platform channel use (Firebase, etc.)
//
//   2. Error boundary installation
//      — [FlutterError.onError]: catches Flutter framework errors
//        (widget build failures, rendering errors) and routes them to
//        the zone error handler rather than crashing silently.
//      — [PlatformDispatcher.instance.onError]: catches all uncaught
//        Dart errors from async contexts (isolate root zone errors).
//
//   3. Firebase initialisation (graceful degradation)
//      — If [google-services.json] is missing or misconfigured, the app
//        continues running on local mock data. Firebase features
//        (FCM, Firestore articles) are silently disabled with a debug log.
//
//   4. Dependency injection setup
//      — [initDependencies()] registers all singletons and factories
//        into the [GetIt] service locator.
//
//   5. [runApp(WeatherSyncApp())]
//      — Hands control to the widget tree.
//
// ERROR HANDLING PHILOSOPHY:
//   Production crash reporting (Crashlytics / Sentry) hooks into step 2.
//   In this scaffold, errors are routed to [FlutterError.presentError()]
//   (debug banner) and [debugPrint] (release console). Replace with
//   [FirebaseCrashlytics.instance.recordFlutterFatalError] when Phase 3
//   integrates Firebase.


import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Conditional import: Firebase is optional. If google-services.json is absent,
// the app bootstraps without it. Phase 3 removes this conditional.
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';

import 'package:weather_sync_ca/core/di/injection_container.dart';
import 'package:weather_sync_ca/services/system_push_service.dart';
import 'package:weather_sync_ca/services/notification_engine.dart';
import 'package:weather_sync_ca/services/boreal_sentinel_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'app.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

/// Application entry point.
///
/// Wrapped in [runZonedGuarded] to catch uncaught async errors that escape
/// the Flutter framework's own error handling (e.g., timer callbacks, raw
/// [Future] chains in platform channels).
void main() async {
  // Step 1: Ensure binding is initialized IMMEDIATELY to prevent native splash deadlocks
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2: Fast synchronous initializations
  tz.initializeTimeZones();
  await NotificationEngine.init();
  
  // Step 3: Dependency injection setup (synchronous mostly)
  await initDependencies();

  // Step 4: Install error boundary handlers
  _installErrorHandlers();

  // Step 5: Fire-and-forget heavy network initializations so they don't block the UI
  _initFirebase();
  SystemPushService.instance.init();
  BorealSentinelService.initialize();

  runZonedGuarded(
    () => runApp(const WeatherSyncApp()),
    _handleZoneError,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOTSTRAP PIPELINE
// ─────────────────────────────────────────────────────────────────────────────

// _bootstrap removed as all init logic moved to main()

// ─────────────────────────────────────────────────────────────────────────────
// ERROR HANDLERS
// ─────────────────────────────────────────────────────────────────────────────

/// Installs platform-level and framework-level error interceptors.
///
/// In debug builds: errors are presented visually (red screen / console).
/// In release builds: errors should be forwarded to a crash-reporting
/// service. The [TODO] below marks the Crashlytics integration point.
void _installErrorHandlers() {
  // Flutter framework errors: widget build failures, rendering exceptions.
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // In debug mode, present the full error with stack trace.
      FlutterError.presentError(details);
    } else {
      // TODO(phase3): FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      debugPrint('[FATAL FLUTTER ERROR] ${details.exceptionAsString()}');
    }
  };

  // Platform dispatcher catches async errors not caught by Flutter's zone.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('[PLATFORM DISPATCHER ERROR]\n$error\n$stack');
    } else {
      // TODO(phase3): FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      debugPrint('[FATAL PLATFORM ERROR] $error');
    }
    // Return false to allow the default platform error handler to also run.
    // Return true to suppress the default handler (not recommended in release).
    return false;
  };
}

/// [runZonedGuarded] error sink.
///
/// Called for any uncaught error that escapes the zone boundary
/// (e.g., an unhandled [Future] rejection in a background timer callback).
void _handleZoneError(Object error, StackTrace stack) {
  if (kDebugMode) {
    debugPrint('[ZONE ERROR]\n$error\n$stack');
  } else {
    // TODO(phase3): FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    debugPrint('[FATAL ZONE ERROR] $error');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIREBASE INITIALISATION (GRACEFUL DEGRADATION)
// ─────────────────────────────────────────────────────────────────────────────

/// Attempts to initialise Firebase.
///
/// If [google-services.json] is missing or the project ID is invalid,
/// the [FirebaseException] is caught and logged. The app continues running
/// with all Firebase-dependent features disabled (FCM push notifications,
/// Firestore article fetching, remote config).
///
/// This design allows the scaffold to be built, run, and demoed on a
/// fresh device without any Firebase project configuration.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    debugPrint('[WeatherSyncCA] Firebase initialised successfully.');
  } on FirebaseException catch (e) {
    // Missing or malformed google-services.json — app continues without Firebase.
    debugPrint(
      '[WeatherSyncCA] Firebase init failed: ${e.message}. '
      'Running in local-data-only mode. '
      'Add google-services.json to android/app/ to enable cloud features.',
    );
  } catch (e) {
    // Unexpected error — log and continue.
    debugPrint(
      '[WeatherSyncCA] Firebase init unexpected error: $e. '
      'Continuing without Firebase.',
    );
  }
}
