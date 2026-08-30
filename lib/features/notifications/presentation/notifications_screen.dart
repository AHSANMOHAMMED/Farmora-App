import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<FarmoraState>().currentUserId;
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.notificationsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load notifications.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return const Center(child: Text('You have no notifications yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final read = notification['read'] == true;
              return Card(
                color: read ? AppColors.surface : AppColors.primaryContainer,
                child: ListTile(
                  leading: Icon(
                    read ? Icons.notifications_none : Icons.notifications,
                    color: AppColors.primary,
                  ),
                  title: Text(
                      notification['title'] as String? ?? 'Farmora update'),
                  subtitle: Text(notification['body'] as String? ?? ''),
                  onTap: read
                      ? null
                      : () => service
                          .markNotificationRead(notification['id'] as String),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
