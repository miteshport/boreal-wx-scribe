# Weather Sync CA

A neo-brutalist weather application tailored for Canadian extremes.

## Features
- Kinetic typography and edge-to-edge UI
- Synthetic Activity Index Dashboard (Patio, Cabin, etc.)
- Canadian Survival Guide & Actionable Chore Cards
- Live weather updates with fallback simulated modes
- Firebase Crashlytics & Remote Config integration

## Firebase Configuration (Production)

To generate valid Firebase credentials for the production APK, follow these steps using `flutterfire-cli`:

1. **Install Firebase CLI and FlutterFire CLI:**
   Ensure you have the [Firebase CLI](https://firebase.google.com/docs/cli) installed and are logged in.
   ```bash
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```

2. **Run FlutterFire Configure:**
   From the root of this Flutter project (`weather_sync_ca`), run:
   ```bash
   flutterfire configure
   ```

3. **Select your Project:**
   Select the existing Firebase project you created for this app, or create a new one.

4. **Select Platforms:**
   Select the platforms you want to support (Android, iOS, Web). The CLI will automatically register your app bundle ID with Firebase.

5. **Generated Files:**
   The CLI will automatically:
   - Generate `android/app/google-services.json`
   - Generate `ios/Runner/GoogleService-Info.plist`
   - Update `lib/firebase_options.dart` with the correct API keys for all platforms.

6. **Verify Initialization:**
   Ensure your `main.dart` initializes Firebase correctly with the generated options:
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import 'firebase_options.dart';
   
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

Once completed, you can safely build the production APK without missing credentials or crashlytics initialization errors.
