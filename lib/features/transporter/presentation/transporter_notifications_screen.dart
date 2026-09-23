import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadNotificationCount > 0)
            TextButton(
              onPressed: state.markAllNotificationsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const TransporterEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              message: 'Job updates and reminders will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
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
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

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
                            notification.title,
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
                      notification.message,
                      style: const TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('d MMM • h:mm a')
                          .format(notification.createdAt),
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
