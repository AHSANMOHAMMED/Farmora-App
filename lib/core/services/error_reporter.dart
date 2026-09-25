import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Single entry point for crash/error reporting.
///
/// Crashlytics has no Flutter Web implementation: calling it there trips the
/// `isCrashlyticsCollectionEnabled` platform-interface assertion, and because
/// it was wired into [FlutterError.onError] every ordinary framework error
/// produced a second, unrelated failure. Reporting is therefore:
///  * only attempted on platforms Crashlytics supports, and
///  * never allowed to throw — a reporting failure is logged and dropped so
///    it can't break product saves, chat, payments or uploads.
class ErrorReporter {
  ErrorReporter._();

  static bool _enabled = false;

  /// True when Crashlytics is supported here and Firebase is initialised.
  static bool get crashlyticsEnabled => _enabled;

  static bool get _platformSupported {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS =>
        true,
      _ => false,
    };
  }

  /// Installs global error handlers. Call once, after Firebase.initializeApp
  /// (or after it failed — handlers still log locally).
  static Future<void> init() async {
    _enabled = _platformSupported && Firebase.apps.isNotEmpty;
    if (_enabled) {
      try {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(!kDebugMode);
      } catch (e) {
        _enabled = false;
        debugPrint('Crashlytics unavailable, reporting locally only: $e');
      }
    }

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      // Keep Flutter's own console/red-screen behaviour.
      (previousOnError ?? FlutterError.presentError)(details);
      _send(details.exception, details.stack,
          reason: details.context?.toDescription(), fatal: false);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Uncaught async error: $error\n$stack');
      _send(error, stack, reason: 'Uncaught async error', fatal: true);
      return true;
    };
  }

  /// Records a handled error. Safe to call from anywhere, on any platform.
  static void record(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    debugPrint('[error] ${reason ?? 'Error'}: $error');
    _send(error, stack, reason: reason, fatal: fatal);
  }

  /// Adds a breadcrumb to the next crash report (no-op where unsupported).
  static void log(String message) {
    if (!_enabled) return;
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }

  static void _send(
    Object error,
    StackTrace? stack, {
    String? reason,
    required bool fatal,
  }) {
    if (!_enabled) return;
    // recordError is async; catch both sync throws and future errors so a
    // reporting problem is never surfaced as an application error.
    try {
      FirebaseCrashlytics.instance
          .recordError(error, stack, reason: reason, fatal: fatal)
          .catchError((Object e) {
        debugPrint('Crashlytics recordError failed: $e');
      });
    } catch (e) {
      debugPrint('Crashlytics recordError failed: $e');
    }
  }
}
