import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app languages and the device-local copy of the chosen language.
///
/// The language is saved on the device (so the app opens in it before
/// sign-in and after a restart) and, when signed in, on the user's profile
/// as `users/{uid}.languageCode` (en / ta / si).
class AppLanguage {
  const AppLanguage(this.code, this.nativeName, this.englishName);

  /// Stored value: 'en', 'ta' or 'si'.
  final String code;

  /// Name written in its own script — what FarmoraState.language holds.
  final String nativeName;

  /// English name, shown as a hint under the native name.
  final String englishName;

  static const english = AppLanguage('en', 'English', 'English');
  static const tamil = AppLanguage('ta', 'தமிழ்', 'Tamil');
  static const sinhala = AppLanguage('si', 'සිංහල', 'Sinhala');

  static const all = <AppLanguage>[english, tamil, sinhala];

  /// Accepts a code ('ta'), a native name ('தமிழ்') or an English name
  /// ('Tamil'); anything else is English.
  static AppLanguage from(String? value) {
    final v = (value ?? '').trim();
    for (final l in all) {
      if (v == l.code ||
          v == l.nativeName ||
          v.toLowerCase() == l.englishName.toLowerCase()) {
        return l;
      }
    }
    return english;
  }

  /// Whether [value] names one of the supported languages.
  static bool isKnown(String? value) {
    final v = (value ?? '').trim();
    return all.any((l) =>
        v == l.code ||
        v == l.nativeName ||
        v.toLowerCase() == l.englishName.toLowerCase());
  }
}

/// Device-local storage of the chosen language code.
class LanguagePrefs {
  LanguagePrefs._();

  static const key = 'farmora.languageCode';

  /// The saved language code, or null when none was chosen yet (first
  /// launch) or storage is unavailable.
  static Future<String?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(key);
      return AppLanguage.isKnown(code) ? AppLanguage.from(code).code : null;
    } catch (e) {
      debugPrint('LanguagePrefs.load failed: $e');
      return null;
    }
  }

  /// Saves [code] on the device. Never throws: losing the local copy only
  /// means the language picker is shown again.
  static Future<void> save(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, AppLanguage.from(code).code);
    } catch (e) {
      debugPrint('LanguagePrefs.save failed: $e');
    }
  }
}
