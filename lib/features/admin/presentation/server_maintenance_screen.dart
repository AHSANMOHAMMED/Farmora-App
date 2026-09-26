import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';

class ServerMaintenanceScreen extends StatefulWidget {
  const ServerMaintenanceScreen({super.key});

  @override
  State<ServerMaintenanceScreen> createState() => _ServerMaintenanceScreenState();
}

class _ServerMaintenanceScreenState extends State<ServerMaintenanceScreen> {
  late TextEditingController _noticeCtrl;
  late TextEditingController _minVersionCtrl;
  double _commission = 5.0;
  int _escrowHours = 48;

  @override
  void initState() {
    super.initState();
    final state = context.read<FarmoraState>();
    _noticeCtrl = TextEditingController(text: state.maintenanceNotice);
    _minVersionCtrl = TextEditingController(text: state.minAppVersion);
    _commission = state.commissionRate;
    _escrowHours = state.escrowReleaseHours;
  }

  @override
  void dispose() {
    _noticeCtrl.dispose();
    _minVersionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.adminServerTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Platform Maintenance Switch Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: state.maintenanceMode ? Colors.red.shade400 : AppColors.outlineVariant,
                width: state.maintenanceMode ? 2 : 1,
              ),
            ),
            color: state.maintenanceMode ? Colors.red.shade50 : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              state.maintenanceMode ? Icons.warning_rounded : Icons.verified_user_rounded,
                              color: state.maintenanceMode ? Colors.red : AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l.adminServerMaintenanceMode,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: state.maintenanceMode,
                        activeThumbColor: Colors.red,
                        onChanged: (val) {
                          state.setMaintenanceMode(enabled: val, notice: _noticeCtrl.text.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                val ? l.adminServerMaintenanceOnSnack : l.adminServerMaintenanceOffSnack,
                              ),
                              backgroundColor: val ? Colors.red.shade800 : AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.maintenanceMode
                        ? l.adminServerMaintenanceActive
                        : l.adminServerMaintenanceInactive,
                    style: TextStyle(
                      fontSize: 12,
                      color: state.maintenanceMode ? Colors.red.shade900 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _noticeCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l.adminServerNoticeLabel,
                      hintText: l.adminServerNoticeHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: () {
                        state.setMaintenanceMode(
                          enabled: state.maintenanceMode,
                          notice: _noticeCtrl.text.trim(),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.adminServerNoticeUpdated)),
                        );
                      },
                      child: Text(l.adminServerUpdateNotice),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Firebase Infrastructure Health
          Text(
            l.adminServerHealthTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            l.adminServerHealthSubtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _FirebaseServiceRow(
                    name: l.adminServerFirestoreName,
                    details: l.adminServerFirestoreDetails,
                    icon: Icons.storage_rounded,
                    isHealthy: true,
                  ),
                  const Divider(height: 18),
                  _FirebaseServiceRow(
                    name: l.adminServerAuthName,
                    details: l.adminServerAuthDetails,
                    icon: Icons.lock_outline_rounded,
                    isHealthy: true,
                  ),
                  const Divider(height: 18),
                  _FirebaseServiceRow(
                    name: l.adminServerStorageName,
                    details: l.adminServerStorageDetails,
                    icon: Icons.cloud_done_rounded,
                    isHealthy: true,
                  ),
                  const Divider(height: 18),
                  _FirebaseServiceRow(
                    name: l.adminServerFcmName,
                    details: l.adminServerFcmDetails,
                    icon: Icons.notifications_active_rounded,
                    isHealthy: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Marketplace Economics & Parameter Tuning
          Text(
            l.adminServerRulesTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Commission Rate
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(l.adminServerCommission, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      const SizedBox(width: 8),
                      Text(l.adminServerPercent(AppFormat.number(_commission, decimals: 1)), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  Slider(
                    value: _commission,
                    min: 1.0,
                    max: 10.0,
                    divisions: 18,
                    label: l.adminServerPercent(AppFormat.number(_commission, decimals: 1)),
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _commission = v),
                    onChangeEnd: (v) => state.setCommissionRate(v),
                  ),
                  const SizedBox(height: 12),

                  // Escrow Release Hours
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(l.adminServerEscrowWindow, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      const SizedBox(width: 8),
                      Text(l.adminServerHours(_escrowHours), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                    ],
                  ),
                  Slider(
                    value: _escrowHours.toDouble(),
                    min: 12.0,
                    max: 96.0,
                    divisions: 14,
                    label: l.adminServerHoursShort(_escrowHours),
                    activeColor: const Color(0xFFE65100),
                    onChanged: (v) => setState(() => _escrowHours = v.toInt()),
                    onChangeEnd: (v) => state.setEscrowReleaseHours(v.toInt()),
                  ),
                  const SizedBox(height: 14),

                  // Minimum App Version
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minVersionCtrl,
                          decoration: InputDecoration(
                            labelText: l.adminServerMinVersionLabel,
                            hintText: '1.0.0',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () {
                          state.setMinAppVersion(_minVersionCtrl.text.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.adminServerMinVersionEnforced)),
                          );
                        },
                        child: Text(l.adminServerEnforce),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Operational Actions
          Text(
            l.adminServerActionsTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded, color: Colors.blue),
                  title: Text(l.adminServerPurgeTitle),
                  subtitle: Text(l.adminServerPurgeSubtitle),
                  trailing: const Icon(Icons.refresh_rounded),
                  onTap: () {
                    state.clearLocalCache();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.adminServerPurgeSnack)),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FirebaseServiceRow extends StatelessWidget {
  final String name;
  final String details;
  final IconData icon;
  final bool isHealthy;

  const _FirebaseServiceRow({
    required this.name,
    required this.details,
    required this.icon,
    required this.isHealthy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: (isHealthy ? Colors.green : Colors.red).withValues(alpha: 0.1),
          radius: 18,
          child: Icon(icon, color: isHealthy ? Colors.green.shade700 : Colors.red, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(details, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(context.l10n.adminServerHealthy, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
        ),
      ],
    );
  }
}
