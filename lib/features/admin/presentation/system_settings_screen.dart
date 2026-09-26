import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../providers/farmora_state.dart';
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
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final state = context.read<FarmoraState>();
    try {
      await state.refreshPlatformSettings();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(userMessage(error, action: 'load platform settings'))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Runs one awaited settings write; shows success only after it returns.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await action();
      messenger.showSnackBar(
          const SnackBar(content: Text('Platform settings updated.')));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.adminSettingsUpdateFailed(
              userMessage(error, action: 'update platform settings'))),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _editText({
    required String title,
    required String value,
    TextInputType keyboardType = TextInputType.number,
    String? helper,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(text: value);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          autofocus: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            helperText: helper,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _invalid(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Future<void> _editFee(FarmoraState state) async {
    final text = await _editText(
      title: context.l10n.adminSettingsFeeDialogTitle,
      value: _plain(state.commissionRate),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      helper: 'Percent of the order subtotal (0 - 50)',
    );
    if (text == null) return;
    final rate = double.tryParse(text);
    if (rate == null || rate < 0 || rate > 50) {
      return _invalid('Enter a percentage between 0 and 50.');
    }
    await _run(() => state.setCommissionRate(rate));
  }

  Future<void> _editTimeout(FarmoraState state) async {
    final text = await _editText(
      title: context.l10n.adminSettingsSessionDialogTitle,
      value: '${state.sessionTimeoutMinutes}',
      helper: 'Minutes of inactivity (0 disables, max 1440)',
    );
    if (text == null) return;
    final minutes = int.tryParse(text);
    if (minutes == null || minutes < 0 || minutes > 1440) {
      return _invalid('Enter a number of minutes between 0 and 1440.');
    }
    await _run(() => state.setSessionTimeoutMinutes(minutes));
  }

  Future<void> _editEscrow(FarmoraState state) async {
    final text = await _editText(
      title: 'Escrow release window (hours)',
      value: '${state.escrowReleaseHours}',
      helper: '1 - 720 hours',
    );
    if (text == null) return;
    final hours = int.tryParse(text);
    if (hours == null || hours < 1 || hours > 720) {
      return _invalid('Enter a number of hours between 1 and 720.');
    }
    await _run(() => state.setEscrowReleaseHours(hours));
  }

  Future<void> _editMinVersion(FarmoraState state) async {
    final text = await _editText(
      title: 'Minimum app version',
      value: state.minAppVersion,
      keyboardType: TextInputType.text,
      helper: 'e.g. 1.2.0',
    );
    if (text == null) return;
    if (text.length > 20 || !RegExp(r'^\d+(\.\d+){0,3}$').hasMatch(text)) {
      return _invalid('Enter a version like 1.2.0.');
    }
    await _run(() => state.setMinAppVersion(text));
  }

  Future<void> _editDeliveryFee(FarmoraState state) async {
    final text = await _editText(
      title: 'Default delivery fee (LKR)',
      value: _plain(state.defaultDeliveryFeeLkr),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    if (text == null) return;
    final fee = double.tryParse(text.replaceAll(',', ''));
    if (fee == null || fee < 0 || fee > 100000) {
      return _invalid('Enter a fee between 0 and 100,000 LKR.');
    }
    await _run(() => state.setDefaultDeliveryFee(fee));
  }

  Future<void> _editNotice(FarmoraState state) async {
    final text = await _editText(
      title: 'Maintenance notice',
      value: state.maintenanceNotice,
      keyboardType: TextInputType.multiline,
      maxLines: 3,
      helper: 'Shown to users while maintenance mode is on (max 300)',
    );
    if (text == null) return;
    if (text.length > 300) {
      return _invalid('The notice must be 300 characters or fewer.');
    }
    await _run(() => state.updatePlatformSettings({
          'maintenanceMode': state.maintenanceMode,
          'maintenanceNotice': text,
        }));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final l = context.l10n;
    final disabled = _loading || _busy;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.adminSettingsTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              if (disabled)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l.adminSettingsMaintenanceMode),
            subtitle: Text(l.adminSettingsMaintenanceSubtitle),
            value: state.maintenanceMode,
            onChanged: disabled
                ? null
                : (value) => _run(() => state.setMaintenanceMode(
                    enabled: value, notice: state.maintenanceNotice)),
          ),
          ListTile(
            title: const Text('Maintenance notice'),
            subtitle: Text(state.maintenanceNotice.isEmpty
                ? 'No notice set'
                : state.maintenanceNotice),
            trailing: const Icon(Icons.chevron_right),
            enabled: !disabled,
            onTap: () => _editNotice(state),
          ),
          const Divider(),
          ListTile(
            title: Text(l.adminSettingsFeeTitle),
            subtitle:
                Text(l.adminSettingsFeeCurrent(_plain(state.commissionRate))),
            trailing: const Icon(Icons.chevron_right),
            enabled: !disabled,
            onTap: () => _editFee(state),
          ),
          const Divider(),
          ListTile(
            title: Text(l.adminSettingsSecurityTitle),
            subtitle: Text(
                l.adminSettingsSessionTimeout(state.sessionTimeoutMinutes)),
            trailing: const Icon(Icons.chevron_right),
            enabled: !disabled,
            onTap: () => _editTimeout(state),
          ),
          const Divider(),
          ListTile(
            title: const Text('Escrow release window'),
            subtitle: Text('${state.escrowReleaseHours} hours'),
            trailing: const Icon(Icons.chevron_right),
            enabled: !disabled,
            onTap: () => _editEscrow(state),
          ),
          const Divider(),
          ListTile(
            title: const Text('Minimum app version'),
            subtitle: Text(state.minAppVersion),
            trailing: const Icon(Icons.chevron_right),
            enabled: !disabled,
            onTap: () => _editMinVersion(state),
          ),
          const Divider(),
          ListTile(
            title: const Text('Default delivery fee'),
            subtitle:
                Text(AppFormat.lkr(state.defaultDeliveryFeeLkr, decimals: 2)),
            trailing: const Icon(Icons.chevron_right),
            enabled: !disabled,
            onTap: () => _editDeliveryFee(state),
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
        ],
      ),
    );
  }
}
