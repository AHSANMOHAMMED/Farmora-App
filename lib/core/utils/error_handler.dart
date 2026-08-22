import 'package:logger/logger.dart';
import '../errors/app_exception.dart';

/// Centralized error handler for logging and categorization
class ErrorHandler {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  /// Log an error and return a user-friendly AppException
  static AppException handleError(Object error, {String? context}) {
    final prefix = context != null ? '[$context]' : '';

    if (error is AppException) {
      _logger.e('$prefix ${error.runtimeType}: ${error.message}',
          error: error.originalError);
      return error;
    }

    // Categorize unknown errors
    final message = error.toString();

    if (message.contains('network') || message.contains('connection')) {
      _logger.e('$prefix Network error: $message', error: error);
      return NetworkException(
        'Please check your internet connection and try again.',
        originalError: error,
      );
    }

    if (message.contains('permission-denied') ||
        message.contains('unauthorized')) {
      _logger.e('$prefix Permission denied: $message', error: error);
      return PermissionDeniedException(
        'You don\'t have permission to perform this action.',
        originalError: error,
      );
    }

    if (message.contains('not-found') || message.contains('not_found')) {
      _logger.e('$prefix Not found: $message', error: error);
      return NotFoundException(
        'The requested resource was not found.',
        originalError: error,
      );
    }

    _logger.e('$prefix Unknown error: $message', error: error);
    return ServerException(
      'An unexpected error occurred. Please try again.',
      originalError: error,
    );
  }

  /// Log an error without converting (for analytics/crash reporting)
  static void logError(Object error, {String? context, StackTrace? stack}) {
    final prefix = context != null ? '[$context]' : '';
    _logger.e('$prefix Error: $error', error: error, stackTrace: stack);
  }
}
