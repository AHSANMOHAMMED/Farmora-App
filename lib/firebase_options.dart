// ============================================================
// Firebase Configuration Template
// ============================================================
// This file contains PLACEHOLDER values. To generate real values:
//
// 1. Install FlutterFire CLI:
//    dart pub global activate flutterfire_cli
//
// 2. Run flutterfire configure in your project root:
//    flutterfire configure
//
// 3. This file will be auto-generated with your real Firebase keys.
//
// Until then, the app will run in DEMO MODE with mock data.
// ============================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// To regenerate this file, run `flutterfire configure`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ============================================================
  // REPLACE the values below with your Firebase project config.
  // Run `flutterfire configure` to auto-fill these.
  // ============================================================

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR-ANDROID-API-KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-farmora-project',
    storageBucket: 'your-farmora-project.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-IOS-API-KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-farmora-project',
    storageBucket: 'your-farmora-project.appspot.com',
    iosBundleId: 'com.example.farmora',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR-MACOS-API-KEY',
    appId: '1:000000000000:macos:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-farmora-project',
    storageBucket: 'your-farmora-project.appspot.com',
    iosBundleId: 'com.example.farmora',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR-WEB-API-KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-farmora-project',
    storageBucket: 'your-farmora-project.appspot.com',
    authDomain: 'your-farmora-project.firebaseapp.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR-WINDOWS-API-KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-farmora-project',
    storageBucket: 'your-farmora-project.appspot.com',
    authDomain: 'your-farmora-project.firebaseapp.com',
  );
}
