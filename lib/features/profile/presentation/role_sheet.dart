import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/presentation/admin_screen.dart';

class RoleSheet extends ConsumerWidget {
  const RoleSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Switch preview role',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...Role.values.map(
            (r) => ListTile(
              leading: Icon(r.icon, color: const Color(0xff1f7a4d)),
              title: Text(r.label),
              onTap: () {
                ref.read(authProvider.notifier).setRole(r);
                Navigator.pop(context);
              },
            ),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings, color: Color(0xff1f7a4d)),
            title: const Text('Admin Panel'),
            subtitle: const Text('View platform analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
