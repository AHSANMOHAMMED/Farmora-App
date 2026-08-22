import 'package:flutter/material.dart';
import '../errors/app_exception.dart';

/// Standard loading indicator widget
class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}

/// Standard empty state widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard error state widget with retry
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  factory ErrorStateWidget.fromException(
    AppException exception, {
    VoidCallback? onRetry,
  }) {
    return ErrorStateWidget(
      title: 'Something went wrong',
      message: exception.message,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget that handles AsyncValue states (loading/error/data)
/// Works with Riverpod's AsyncValue
class AsyncStateHandler<T> extends StatelessWidget {
  final T? data;
  final bool isLoading;
  final Object? error;
  final VoidCallback? onRetry;
  final Widget Function(T data) builder;
  final Widget Function(Object error)? errorBuilder;
  final Widget? loadingWidget;

  const AsyncStateHandler({
    super.key,
    this.data,
    this.isLoading = false,
    this.error,
    this.onRetry,
    required this.builder,
    this.errorBuilder,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && data == null) {
      return loadingWidget ?? const LoadingWidget();
    }

    if (error != null) {
      if (errorBuilder != null) {
        return errorBuilder!(error!);
      }
      final msg = (error is AppException) ? (error as AppException).message : error.toString();
      return ErrorStateWidget(
        title: 'Something went wrong',
        message: msg,
        onRetry: onRetry,
      );
    }

    if (data == null) {
      return const LoadingWidget();
    }

    return builder(data as T);
  }
}
