import 'package:flutter/material.dart';
import '../../../../services/firebase_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import 'market_price_management_screen.dart';
import 'broadcast_advisory_screen.dart';
import 'dispute_resolution_screen.dart';
import 'verification_review_screen.dart';
import 'platform_analytics_screen.dart';
import 'review_management_screen.dart';
import 'server_maintenance_screen.dart';
import 'settlement_management_screen.dart';
import 'logistics_management_screen.dart';
import 'audit_log_screen.dart';

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
          SnackBar(
            content: Text(context.l10n.adminSettingsUpdateFailed(
                userMessage(error, action: 'update platform settings'))),
          ),
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
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: Text(context.l10n.commonSave),
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
    final l = context.l10n;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.adminSettingsTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l.adminSettingsMaintenanceMode),
            subtitle: Text(l.adminSettingsMaintenanceSubtitle),
            value: _settings['maintenanceMode'] == true,
            onChanged: _loading
                ? null
                : (value) => _update({'maintenanceMode': value}),
          ),
          const Divider(),
          ListTile(
            title: Text(l.adminSettingsFeeTitle),
            subtitle: Text(l.adminSettingsFeeCurrent('${feeBps / 100}')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editNumber(
              title: l.adminSettingsFeeDialogTitle,
              key: 'platformFeeBps',
              value: feeBps,
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(l.adminSettingsSecurityTitle),
            subtitle: Text(l.adminSettingsSessionTimeout(timeout)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editNumber(
              title: l.adminSettingsSessionDialogTitle,
              key: 'sessionTimeoutMinutes',
              value: timeout,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.trending_up_rounded, color: AppColors.primary),
            title: Text(l.adminSettingsMarketPriceTitle),
            subtitle: Text(l.adminSettingsMarketPriceSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MarketPriceManagementScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.campaign_rounded, color: Color(0xFFE65100)),
            title: Text(l.adminSettingsBroadcastTitle),
            subtitle: Text(l.adminSettingsBroadcastSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BroadcastAdvisoryScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.gavel_rounded, color: Color(0xFF6A1B9A)),
            title: Text(l.adminSettingsDisputeTitle),
            subtitle: Text(l.adminSettingsDisputeSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DisputeResolutionScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.verified_user_rounded, color: Color(0xFF1B6BD8)),
            title: Text(l.adminSettingsKycTitle),
            subtitle: Text(l.adminSettingsKycSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VerificationReviewScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.insights_rounded, color: Color(0xFF1B6BD8)),
            title: Text(l.adminSettingsAnalyticsTitle),
            subtitle: Text(l.adminSettingsAnalyticsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlatformAnalyticsScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.rate_review_rounded, color: Colors.amber),
            title: Text(l.adminReviewsTitle),
            subtitle: Text(l.adminSettingsReviewsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReviewManagementScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_sync_rounded, color: Colors.teal),
            title: Text(l.adminServerTitle),
            subtitle: Text(l.adminSettingsServerSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServerMaintenanceScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2E7D32)),
            title: Text(l.adminSettingsTreasuryTitle),
            subtitle: Text(l.adminSettingsTreasurySubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettlementManagementScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.local_shipping_rounded, color: Color(0xFF1B6BD8)),
            title: Text(l.adminSettingsFleetTitle),
            subtitle: Text(l.adminSettingsFleetSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LogisticsManagementScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shield_rounded, color: Color(0xFF5E35B1)),
            title: Text(l.adminSettingsAuditTitle),
            subtitle: Text(l.adminSettingsAuditSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuditLogScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(l.adminSettingsSeedTitle),
            subtitle: Text(l.adminSettingsSeedSubtitle),
            trailing: const Icon(Icons.add_box),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.adminServerSeeding)),
              );
              try {
                await FirestoreService().seedDatabase();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.adminSettingsSeeded)),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.adminSettingsSeedFailed(
                          userMessage(error, action: 'seed marketplace data'))),
                    ),
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
