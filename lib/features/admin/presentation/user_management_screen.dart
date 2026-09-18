import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final users = state.users;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Manage Users',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (users.isEmpty)
            const Center(child: Text('No users found.'))
          else
            ...users.map((user) {
              final uid = (user['uid'] ?? user['id'] ?? '').toString();
              final name = (user['name'] ?? 'Unknown User').toString();
              final role = (user['role'] ?? 'Unknown Role').toString();
              final verified = user['isVerified'] == true;
              final suspended = user['isSuspended'] == true;
              return _UserTile(
                uid: uid,
                name: name,
                role: role,
                verified: verified,
                suspended: suspended,
              );
            }),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String uid;
  final String name;
  final String role;
  final bool verified;
  final bool suspended;

  const _UserTile({
    required this.uid,
    required this.name,
    required this.role,
    required this.verified,
    required this.suspended,
  });

  @override
  Widget build(BuildContext context) {
    final status = suspended ? 'Suspended' : 'Active';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.onPrimaryContainer),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '$role · ${verified ? 'Verified' : 'Unverified'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(status, style: const TextStyle(fontSize: 12)),
              backgroundColor: suspended
                  ? Colors.orange.shade100
                  : Colors.green.shade100,
            ),
            if (uid.isNotEmpty)
              IconButton(
                tooltip: suspended ? 'Unsuspend' : 'Suspend',
                icon: Icon(
                  suspended ? Icons.lock_open : Icons.block,
                  color: suspended ? AppColors.primary : AppColors.error,
                ),
                onPressed: () async {
                  try {
                    await FirestoreService().setUserSuspended(
                      userId: uid,
                      suspended: !suspended,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            suspended ? 'User unsuspended' : 'User suspended',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
