import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../application/transporter_controller.dart';
import '../domain/collection_job.dart';
import '../domain/transporter_notification.dart';
import 'collection_job_details_screen.dart';
import 'widgets/transporter_states.dart';

class TransporterNotificationsScreen extends StatelessWidget {
  const TransporterNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransporterController>();
    final notifications = state.notifications;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          if (state.unreadNotificationCount > 0)
            TextButton(
              onPressed: () => _markAllRead(context, state),
              child: Text(l10n.transporterMarkAllRead),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? TransporterEmptyState(
              icon: Icons.notifications_none_rounded,
              title: l10n.transporterNoNotifications,
              message: l10n.transporterNotificationsHint,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => _open(context, state, notification),
                );
              },
            ),
    );
  }

  /// Job the notification refers to: by `jobId`, else by its order.
  static CollectionJob? _jobFor(
    TransporterController state,
    TransporterNotification notification,
  ) {
    final jobId = notification.jobId ?? '';
    if (jobId.isNotEmpty) {
      final job = state.jobById(jobId);
      if (job != null) return job;
    }
    final orderId = notification.orderId ?? '';
    if (orderId.isEmpty) return null;
    for (final job in state.allJobs) {
      if (job.orderId == orderId) return job;
    }
    return null;
  }

  Future<void> _open(
    BuildContext context,
    TransporterController state,
    TransporterNotification notification,
  ) async {
    final job = _jobFor(state, notification);
    final hasTarget = (notification.jobId ?? '').isNotEmpty ||
        (notification.orderId ?? '').isNotEmpty;
    if (job != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CollectionJobDetailsScreen(jobId: job.id),
        ),
      );
    } else if (hasTarget) {
      _snack(context, context.l10n.jobNoLongerAvailable);
    }
    if (notification.isRead) return;
    try {
      await state.markNotificationRead(notification.id);
    } catch (error) {
      if (context.mounted) {
        _snack(context, userMessage(error, action: 'update the notification'),
            error: true);
      }
    }
  }

  Future<void> _markAllRead(
    BuildContext context,
    TransporterController state,
  ) async {
    try {
      await state.markAllNotificationsRead();
    } catch (error) {
      if (context.mounted) {
        _snack(context, userMessage(error, action: 'update notifications'),
            error: true);
      }
    }
  }

  static void _snack(BuildContext context, String message,
      {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ));
  }
}

class _NotificationTile extends StatelessWidget {
  final TransporterNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (notification.type) {
      TransporterNotificationType.newJob => (
          Icons.add_road_rounded,
          AppColors.primary
        ),
      TransporterNotificationType.accepted => (
          Icons.assignment_turned_in_outlined,
          const Color(0xFF1565C0)
        ),
      TransporterNotificationType.reminder => (
          Icons.alarm_rounded,
          AppColors.statusPendingText
        ),
      TransporterNotificationType.cancelled => (
          Icons.cancel_outlined,
          AppColors.error
        ),
      TransporterNotificationType.completed => (
          Icons.task_alt_rounded,
          AppColors.primary
        ),
    };
    final title = notification.title;
    final message = notification.message;
    return Material(
      color: notification.isRead
          ? AppColors.surfaceContainerLowest
          : AppColors.primaryLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${AppFormat.dayMonth(notification.createdAt)} • '
                      '${AppFormat.time(notification.createdAt)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
