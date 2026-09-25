import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../application/transporter_controller.dart';
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
              onPressed: state.markAllNotificationsRead,
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
                  produceName: notification.jobId == null
                      ? null
                      : state.jobById(notification.jobId!)?.produceName,
                  onTap: () {
                    state.markNotificationRead(notification.id);
                    if (notification.jobId != null &&
                        state.jobById(notification.jobId!) != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CollectionJobDetailsScreen(
                            jobId: notification.jobId!,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final TransporterNotification notification;
  final String? produceName;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    this.produceName,
  });

  /// Notifications created on this device are re-worded in the current
  /// language; server notifications are shown as stored.
  (String, String) _text(AppLocalizations l10n) {
    final produce = produceName;
    if (!notification.id.startsWith('local-') || produce == null) {
      return (notification.title, notification.message);
    }
    return switch (notification.type) {
      TransporterNotificationType.accepted => (
          l10n.jobAcceptedNotifTitle,
          l10n.jobAcceptedNotifBody(produce),
        ),
      TransporterNotificationType.completed => (
          l10n.jobDeliveryCompletedNotifTitle,
          l10n.jobDeliveryCompletedNotifBody(produce),
        ),
      _ => (notification.title, notification.message),
    };
  }

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
    final (title, message) = _text(context.l10n);
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
