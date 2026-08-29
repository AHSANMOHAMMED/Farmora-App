import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';

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
          const Text('Manage Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (users.isEmpty)
            const Center(child: Text('No users found.'))
          else
            ...users.map((user) {
              final name = user['name'] ?? 'Unknown User';
              final role = user['role'] ?? 'Unknown Role';
              return _buildUserTile(name, role, 'Active');
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserTile(String name, String role, String status) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Text(name[0], style: TextStyle(color: AppColors.onPrimaryContainer)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(role),
        trailing: Chip(
          label: Text(status, style: const TextStyle(fontSize: 12)),
          backgroundColor: status == 'Active' ? Colors.green.shade100 : Colors.orange.shade100,
        ),
      ),
    );
  }
}
