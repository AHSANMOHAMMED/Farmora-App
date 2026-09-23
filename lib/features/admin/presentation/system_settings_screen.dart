import 'package:flutter/material.dart';
import '../../../../services/firebase_service.dart';
import '../../../core/constants/app_colors.dart';
import 'market_price_management_screen.dart';
import 'broadcast_advisory_screen.dart';
import 'dispute_resolution_screen.dart';
import 'verification_review_screen.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final _service = FirestoreService();
  Map<String, dynamic> _settings = const {
    'maintenanceMode': false,
    'platformFeeBps': 0,
    'sessionTimeoutMinutes': 60,
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _service.getPlatformSettings();
      if (mounted) setState(() => _settings = {..._settings, ...settings});
    } catch (_) {
      // Defaults remain visible until the admin backend is configured.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _update(Map<String, dynamic> update) async {
    try {
      await _service.updatePlatformSettings(update);
      if (mounted) setState(() => _settings = {..._settings, ...update});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settings update failed: $error')),
        );
      }
    }
  }

  Future<void> _editNumber({
    required String title,
    required String key,
    required int value,
  }) async {
    final controller = TextEditingController(text: '$value');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) await _update({key: result});
  }

  @override
  Widget build(BuildContext context) {
    final feeBps = (_settings['platformFeeBps'] as num? ?? 0).toInt();
    final timeout = (_settings['sessionTimeoutMinutes'] as num? ?? 60).toInt();
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Platform Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Maintenance Mode'),
            subtitle: const Text(
                'Disable access to the platform for all non-admin users.'),
            value: _settings['maintenanceMode'] == true,
            onChanged: _loading
                ? null
                : (value) => _update({'maintenanceMode': value}),
          ),
          const Divider(),
          ListTile(
            title: const Text('Fee Configuration'),
            subtitle: Text('Current: ${feeBps / 100}%'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editNumber(
              title: 'Platform fee (basis points)',
              key: 'platformFeeBps',
              value: feeBps,
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Security Policies'),
            subtitle: Text('Session timeout: $timeout minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editNumber(
              title: 'Session timeout (minutes)',
              key: 'sessionTimeoutMinutes',
              value: timeout,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.trending_up_rounded, color: AppColors.primary),
            title: const Text('Market Price Intelligence'),
            subtitle: const Text('Configure Sri Lankan wholesale Pola benchmark rates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MarketPriceManagementScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.campaign_rounded, color: Color(0xFFE65100)),
            title: const Text('Broadcast Advisories & Weather Alerts'),
            subtitle: const Text('Push emergency and operational notices to users'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BroadcastAdvisoryScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.gavel_rounded, color: Color(0xFF6A1B9A)),
            title: const Text('Dispute & Escrow Arbitrator Desk'),
            subtitle: const Text('Inspect claims and trigger escrow payouts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DisputeResolutionScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.verified_user_rounded, color: Color(0xFF1B6BD8)),
            title: const Text('Farmer & Transporter KYC Verification'),
            subtitle: const Text('Review national identity, land permits, and driving licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VerificationReviewScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Seed Sri Lankan marketplace'),
            subtitle: const Text(
              'Requires registered farmer + buyer. Attaches real LKR produce, '
              'orders and jobs to those accounts.',
            ),
            trailing: const Icon(Icons.add_box),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seeding Sri Lankan marketplace…')),
              );
              try {
                await FirestoreService().seedDatabase();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Seeded. Sign in as farmer/buyer/transporter to see data.',
                      ),
                    ),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Seed failed: $error')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
