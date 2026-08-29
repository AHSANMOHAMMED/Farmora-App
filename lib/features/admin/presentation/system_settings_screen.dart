import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Platform Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Maintenance Mode'),
            subtitle: const Text('Disable access to the platform for all non-admin users.'),
            value: false,
            onChanged: (val) {},
          ),
          const Divider(),
          ListTile(
            title: const Text('Fee Configuration'),
            subtitle: const Text('Manage platform transaction fees.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: const Text('Security Policies'),
            subtitle: const Text('Manage password rules and session timeouts.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: const Text('Seed Database (Mock Data)'),
            subtitle: const Text('Inject Sri Lankan mock data for testing.'),
            trailing: const Icon(Icons.add_box),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seeding database...'))
              );
              try {
                final firestoreService = context.read<FarmoraState>().firestoreService;
                await firestoreService.seedDatabase();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database seeded successfully!'))
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error seeding: $e'))
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
