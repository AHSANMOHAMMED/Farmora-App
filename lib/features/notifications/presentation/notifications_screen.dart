import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = FirestoreService();
  bool _orderUpdates = true;
  bool _messages = true;
  bool _promos = false;
  bool _quietHours = false;

  Future<void> _savePrefs() async {
    try {
      await _service.updateNotificationPreferences({
        'orderUpdates': _orderUpdates,
        'messages': _messages,
        'promos': _promos,
        'quietHours': _quietHours,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification preferences saved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<FarmoraState>().currentUserId;
    final service = _service;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Column(
        children: [
          ExpansionTile(
            title: const Text('Preferences & quiet hours'),
            children: [
              SwitchListTile(title: const Text('Order status updates'), value: _orderUpdates, onChanged: (v) => setState(() => _orderUpdates = v)),
              SwitchListTile(title: const Text('New messages'), value: _messages, onChanged: (v) => setState(() => _messages = v)),
              SwitchListTile(title: const Text('Promotions'), value: _promos, onChanged: (v) => setState(() => _promos = v)),
              SwitchListTile(title: const Text('Quiet hours (10pm–7am)'), value: _quietHours, onChanged: (v) => setState(() => _quietHours = v)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FilledButton(onPressed: _savePrefs, child: const Text('Save preferences')),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
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
          ),
        ],
      ),
    );
  }
}
