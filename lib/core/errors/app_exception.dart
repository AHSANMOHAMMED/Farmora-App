/// Base exception for all app errors
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => '$runtimeType($code): $message';
}

/// Authentication-related errors
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

/// Network/connectivity errors
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

/// Resource not found
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code, super.originalError});
}

/// Permission denied
class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message,
      {super.code, super.originalError});
}

/// Validation errors
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  const ValidationException(super.message,
      {this.fieldErrors = const {}, super.code, super.originalError});
}

/// Storage/file upload errors
class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.originalError});
}

/// Order state machine errors
class OrderTransitionException extends AppException {
  const OrderTransitionException(super.message,
      {super.code, super.originalError});
}

/// Generic/server errors
class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.originalError});
}
