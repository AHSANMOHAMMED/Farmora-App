import 'package:logger/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
    // Disable console logging in release mode to save resources, rely on Crashlytics
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.log('INFO: $message');
    }
  }

  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.log('WARN: $message');
      if (error != null) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message, fatal: false);
      }
    }
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    FirebaseCrashlytics.instance.recordError(error ?? Exception(message), stackTrace, reason: message, fatal: true);
  }
}
