import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Default [FirebaseOptions] for the current platform.
///
/// To generate real values, run: `flutterfire configure`
/// This will overwrite this file with your project's actual config.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  // ── REPLACE THESE with values from `flutterfire configure` ──

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'farmora-app-xxxxx',
    storageBucket: 'farmora-app-xxxxx.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'farmora-app-xxxxx',
    storageBucket: 'farmora-app-xxxxx.appspot.com',
    iosBundleId: 'com.farmora.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: '1:000000000000:macos:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'farmora-app-xxxxx',
    storageBucket: 'farmora-app-xxxxx.appspot.com',
    iosBundleId: 'com.farmora.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WINDOWS_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'farmora-app-xxxxx',
    storageBucket: 'farmora-app-xxxxx.appspot.com',
    authDomain: 'farmora-app-xxxxx.firebaseapp.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'farmora-app-xxxxx',
    storageBucket: 'farmora-app-xxxxx.appspot.com',
    authDomain: 'farmora-app-xxxxx.firebaseapp.com',
  );
}
