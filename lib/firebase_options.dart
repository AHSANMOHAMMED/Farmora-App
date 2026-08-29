import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
        'Android Firebase configuration is not installed yet.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDDv8Pz6esu0UyNfi_S_g68sAD0gWLl7CQ',
    appId: '1:83367323369:web:d4ec7cdeab448652a83278',
    messagingSenderId: '83367323369',
    projectId: 'farmora-1da5a',
    authDomain: 'farmora-1da5a.firebaseapp.com',
    storageBucket: 'farmora-1da5a.firebasestorage.app',
    measurementId: 'G-V42N6Z61LX',
  );
}
