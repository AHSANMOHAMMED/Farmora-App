import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Shared loading / error / empty / content pattern for list screens.
class AsyncStateView extends StatelessWidget {
  final bool isLoading;
  final Object? error;
  final bool isEmpty;
  final String? emptyMessage;
  final VoidCallback? onRetry;
  final Widget child;

  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.child,
    this.error,
    this.isEmpty = false,
    this.emptyMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.loading),
          ],
        ),
      );
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.error}: $error', textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(l10n.tryAgain),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (isEmpty) {
      return Center(child: Text(emptyMessage ?? l10n.emptyState));
    }
    return child;
  }
}
