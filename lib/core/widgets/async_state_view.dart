import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';

/// Shared loading / error / empty / content pattern for list screens.
class AsyncStateView extends StatelessWidget {
  final bool isLoading;
  final Object? error;
  final bool isEmpty;
  final String? emptyMessage;
  final VoidCallback? onRetry;
  final Widget child;
  final IconData? emptyIcon;

  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.child,
    this.error,
    this.isEmpty = false,
    this.emptyMessage,
    this.onRetry,
    this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildContent(context, l10n),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    if (isLoading) {
      return Center(
        key: const ValueKey('loading'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.loading, 
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    if (error != null) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                '${l10n.error}', 
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(), 
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.tryAgain),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    if (isEmpty) {
      return Center(
        key: const ValueKey('empty'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                emptyIcon ?? Icons.inbox_outlined, 
                size: 64, 
                color: AppColors.outline,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage ?? l10n.emptyState,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return KeyedSubtree(
      key: const ValueKey('content'),
      child: child,
    );
  }
}
