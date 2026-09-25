import '../core/utils/app_errors.dart';

/// A rule violation whose (localized) message is meant for the user.
///
/// Still a [StateError] so callers and tests that expect one keep working,
/// but also an [AppException] so `describeError` shows [message] instead of
/// a generic text.
class UserStateError extends StateError implements AppException {
  UserStateError(super.message);

  @override
  Object? get cause => null;

  @override
  String toString() => message;
}

/// Invalid input whose (localized) message is meant for the user. See
/// [UserStateError].
class UserArgumentError extends ArgumentError implements AppException {
  UserArgumentError(String super.message);

  @override
  String get message => super.message as String;

  @override
  Object? get cause => null;

  @override
  String toString() => message;
}
