import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../localization/l10n.dart';
import '../services/error_reporter.dart';

/// A failure with a message that is safe and useful to show a user.
class AppException implements Exception {
  const AppException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Converts any error from Firebase, Storage, Functions, the image picker or
/// our own validation into a short user-facing sentence. The technical error
/// is logged (and reported where Crashlytics is supported) — never swallowed.
String userMessage(
  Object error, {
  String action = 'complete this action',
  StackTrace? stack,
}) {
  ErrorReporter.record(error, stack, reason: 'Failed to $action');
  return describeError(error, action: action);
}

/// Pure mapping (no logging); exposed for tests. Messages are in the current
/// app language ([L10n.current]). [action] is kept for logging call sites.
String describeError(Object error, {String action = 'complete this action'}) {
  final l = L10n.current;
  if (error is AppException) return error.message;
  if (error is StateError) return l.errorGeneric;
  if (error is ArgumentError) return l.errorInvalidDetails;

  if (error is FirebaseFunctionsException) {
    return switch (error.code) {
      // On web a missing (undeployed) callable fails CORS and surfaces as
      // `internal` with no details — the classic "internal [0]" error.
      'internal' || 'not-found' || 'unavailable' when
          (error.message == null ||
              error.message!.isEmpty ||
              error.message!.toLowerCase() == 'internal') =>
        l.errorServerUnreachable,
      'unauthenticated' => l.errorSignInAgain,
      'permission-denied' => l.errorNoPermission,
      'invalid-argument' ||
      'failed-precondition' ||
      'already-exists' =>
        l.errorInvalidDetails,
      'deadline-exceeded' => l.errorTimeout,
      _ => l.errorGeneric,
    };
  }

  if (error is FirebaseException) {
    final code = error.code;
    if (error.plugin == 'firebase_storage') {
      return switch (code) {
        'unauthorized' => l.errorUploadNoPermission,
        'unauthenticated' => l.errorSignInAgain,
        'canceled' => l.errorUploadCancelled,
        'quota-exceeded' => l.errorStorageFull,
        'object-not-found' => l.errorFileMissing,
        'bucket-not-found' || 'project-not-found' => l.errorStorageNotSetUp,
        _ => l.errorUploadFailed,
      };
    }
    return switch (code) {
      'permission-denied' => l.errorNoPermission,
      'unavailable' => l.errorOffline,
      'unauthenticated' => l.errorSignInAgain,
      'not-found' => l.errorNotFound,
      'deadline-exceeded' => l.errorTimeout,
      _ => l.errorGeneric,
    };
  }

  if (error is PlatformException) {
    final code = error.code.toLowerCase();
    if (code.contains('camera') &&
        (code.contains('denied') || code.contains('permission'))) {
      return l.errorCameraAccessDenied;
    }
    if (code.contains('denied') || code.contains('permission')) {
      return l.errorPhotoAccessDenied;
    }
    return l.errorGeneric;
  }

  return l.errorGeneric;
}
