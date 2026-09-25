import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart' show PlatformException;

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

/// Pure mapping (no logging); exposed for tests.
String describeError(Object error, {String action = 'complete this action'}) {
  if (error is AppException) return error.message;
  if (error is StateError) return error.message;
  if (error is ArgumentError) {
    final msg = error.message?.toString();
    return (msg == null || msg.isEmpty) ? 'Some details are invalid.' : msg;
  }

  if (error is FirebaseFunctionsException) {
    return switch (error.code) {
      // On web a missing (undeployed) callable fails CORS and surfaces as
      // `internal` with no details — the classic "internal [0]" error.
      'internal' || 'not-found' || 'unavailable' when
          (error.message == null ||
              error.message!.isEmpty ||
              error.message!.toLowerCase() == 'internal') =>
        'The Farmora server could not be reached. Please try again later.',
      'unauthenticated' => 'Please sign in again and retry.',
      'permission-denied' => "You don't have permission to $action.",
      'invalid-argument' ||
      'failed-precondition' ||
      'already-exists' =>
        error.message ?? 'Some details are invalid.',
      'deadline-exceeded' => 'The request timed out. Check your connection.',
      _ => error.message ?? 'Could not $action. Please try again.',
    };
  }

  if (error is FirebaseException) {
    final code = error.code;
    if (error.plugin == 'firebase_storage') {
      return switch (code) {
        'unauthorized' => "You don't have permission to upload this file.",
        'unauthenticated' => 'Please sign in again and retry the upload.',
        'canceled' => 'Upload cancelled.',
        'quota-exceeded' => 'Storage is full. Please try again later.',
        'retry-limit-exceeded' ||
        'unknown' =>
          'Upload failed. Check your connection and try again.',
        'object-not-found' => 'The file no longer exists.',
        'bucket-not-found' ||
        'project-not-found' =>
          'Photo storage is not set up for this app yet. Please contact support.',
        _ => 'Upload failed. Please try again.',
      };
    }
    return switch (code) {
      'permission-denied' => "You don't have permission to $action.",
      'unavailable' => 'You appear to be offline. Check your connection.',
      'unauthenticated' => 'Please sign in again and retry.',
      'not-found' => 'That item no longer exists.',
      'deadline-exceeded' => 'The request timed out. Check your connection.',
      _ => 'Could not $action. Please try again.',
    };
  }

  if (error is PlatformException) {
    final code = error.code.toLowerCase();
    if (code.contains('denied') || code.contains('permission')) {
      return 'Photo access was denied. Allow access in your device settings.';
    }
    return error.message ?? 'Could not $action. Please try again.';
  }

  return 'Could not $action. Please try again.';
}
