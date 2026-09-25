import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import '../../../models/settlement_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/user_role.dart';

/// Display label for a raw recipient role ('farmer', 'transporter', ...).
String _roleLabel(String raw) {
  for (final r in Role.values) {
    if (r.name == raw.toLowerCase()) return r.label;
  }
  return raw;
}

class SettlementManagementScreen extends StatefulWidget {
  const SettlementManagementScreen({super.key});

  @override
  State<SettlementManagementScreen> createState() =>
      _SettlementManagementScreenState();
}

class _SettlementManagementScreenState
    extends State<SettlementManagementScreen> {
  String _selectedStatus = 'all';

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'settled':
        return const Color(0xFF2E7D32);
      case 'processing':
        return const Color(0xFF1B6BD8);
      case 'on_hold':
        return const Color(0xFFD32F2F);
      case 'pending':
      default:
        return const Color(0xFFF57C00);
    }
  }

  void _showApproveDialog(BuildContext context, SettlementPayout settlement) {
    final referenceController = TextEditingController();
    final l = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.adminSettlementRecordTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.adminSettlementDisburseFor(settlement.orderNumber)),
              const SizedBox(height: 8),
              Text(
                l.adminSettlementTransferHint,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: referenceController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: l.adminSettlementReferenceLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        l.adminSettlementRecipient(settlement.recipientName,
                            _roleLabel(settlement.recipientRole)),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(l.adminSettlementBank(settlement.bankName)),
                    Text(l.adminSettlementAccount(settlement.accountNumber)),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(l.adminSettlementGrossOrder)),
                        Text(
                            AppFormat.lkr(settlement.grossAmount, decimals: 2)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(l.adminSettlementPlatformFee,
                              style: const TextStyle(color: Colors.grey)),
                        ),
                        Text(
                            '- ${AppFormat.lkr(settlement.platformFee, decimals: 2)}',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(l.adminSettlementNetPayout,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Text(
                          AppFormat.lkr(settlement.netAmount, decimals: 2),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () async {
              final reference = referenceController.text.trim();
              if (reference.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.adminSettlementEnterReference)),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await context.read<FarmoraState>().approveSettlement(
                      settlement.id,
                      transactionReference: reference,
                    );
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l.adminSettlementRecordFailed(userMessage(
                            error,
                            action: 'record settlement transfer')))),
                  );
                }
                return;
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        l.adminSettlementRecorded(settlement.recipientName)),
                    backgroundColor: const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(l.adminSettlementRecordTransfer),
          ),
        ],
      ),
    ).whenComplete(referenceController.dispose);
  }

  void _showHoldDialog(BuildContext context, SettlementPayout settlement) {
    final l = context.l10n;
    final reasonCtrl =
        TextEditingController(text: l.adminSettlementHoldDefaultReason);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.adminSettlementHoldTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.adminSettlementHoldMessage(
                AppFormat.lkr(settlement.netAmount, decimals: 2),
                settlement.recipientName)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l.adminSettlementHoldReasonLabel,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () async {
              Navigator.pop(ctx);
              await context
                  .read<FarmoraState>()
                  .holdSettlement(settlement.id, reasonCtrl.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.adminSettlementHoldApplied(settlement.id)),
                    backgroundColor: const Color(0xFFD32F2F),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(l.adminSettlementApplyHold),
          ),
        ],
      ),
    );
  }

  void _exportBankBatchManifest(
      BuildContext context, List<SettlementPayout> settlements) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.adminSettlementExported(settlements.length)),
        backgroundColor: const Color(0xFF1B6BD8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final l = context.l10n;

    // Calculate Treasury Metrics
    double totalSettled = 0.0;
    double pendingAmount = 0.0;
    double feesRetained = 0.0;
    int onHoldCount = 0;

    for (final s in state.settlements) {
      if (s.status == 'settled') {
        totalSettled += s.netAmount;
        feesRetained += s.platformFee;
      } else if (s.status == 'pending' || s.status == 'processing') {
        pendingAmount += s.netAmount;
      } else if (s.status == 'on_hold') {
        onHoldCount++;
      }
    }

    final filtered = state.settlements.where((s) {
      if (_selectedStatus == 'all') return true;
      return s.status.toLowerCase() == _selectedStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: Column(
        children: [
          // Header Financial KPI Cards
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _TreasuryKpiCard(
                        title: l.adminSettlementKpiDisbursed,
                        amount: AppFormat.lkr(totalSettled),
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TreasuryKpiCard(
                        title: l.adminSettlementKpiPending,
                        amount: AppFormat.lkr(pendingAmount),
                        icon: Icons.hourglass_top_rounded,
                        color: const Color(0xFFF57C00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TreasuryKpiCard(
                        title: l.adminSettlementKpiFees,
                        amount: AppFormat.lkr(feesRetained),
                        icon: Icons.account_balance_rounded,
                        color: const Color(0xFF1B6BD8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TreasuryKpiCard(
                        title: l.adminSettlementKpiHeld,
                        amount: l.adminSettlementPayoutsCount(onHoldCount),
                        icon: Icons.flag_rounded,
                        color: const Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Status Tabs and Export Action
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                                'all',
                                l.adminSettlementFilterAll(
                                    state.settlements.length)),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                                'pending', statusLabel('pending', l)),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                                'processing', statusLabel('processing', l)),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                                'settled', statusLabel('settled', l)),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                                'on_hold', statusLabel('on_hold', l)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () =>
                          _exportBankBatchManifest(context, filtered),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: Text(l.adminSettlementExportCsv,
                          style: const TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Payout Ledger List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(l.adminSettlementEmptyTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                              l.adminSettlementEmptyMessage(
                                  _selectedStatus == 'all'
                                      ? l.commonAll
                                      : statusLabel(_selectedStatus, l)),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final s = filtered[i];
                      final color = _statusColor(s.status);

                      return Card(
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                color.withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            statusLabel(s.status, l)
                                                .toUpperCase(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          s.orderNumber,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppFormat.lkr(s.netAmount, decimals: 2),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.account_circle_outlined,
                                      size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      s.recipientName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _roleLabel(s.recipientRole).toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.account_balance_outlined,
                                      size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l.adminSettlementBankAccount(
                                          s.bankName, s.accountNumber),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.currency_exchange_rounded,
                                      size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l.adminSettlementBreakdown(
                                          AppFormat.lkr(s.grossAmount,
                                              decimals: 2),
                                          AppFormat.lkr(s.platformFee,
                                              decimals: 2),
                                          s.payoutMethod),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                              ),
                              if (s.transactionReference != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l.adminSettlementBankRef(
                                        s.transactionReference!),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade800,
                                        fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                              if (s.holdReason != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded,
                                          size: 16, color: Colors.red),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          l.adminSettlementHoldReason(
                                              s.holdReason!),
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              // Action Buttons
                              Row(
                                children: [
                                  if (s.status == 'pending' ||
                                      s.status == 'processing') ...[
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () =>
                                            _showApproveDialog(context, s),
                                        icon: const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 16),
                                        label: Text(
                                            l.adminSettlementApproveWire,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF2E7D32),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () =>
                                          _showHoldDialog(context, s),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFFD32F2F),
                                        side: const BorderSide(
                                            color: Color(0xFFD32F2F)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      child: Text(l.adminSettlementHoldPayout),
                                    ),
                                  ] else if (s.status == 'on_hold') ...[
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () async {
                                          await context
                                              .read<FarmoraState>()
                                              .retrySettlement(s.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(l
                                                      .adminSettlementResumed)),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.replay_rounded,
                                            size: 16),
                                        label: Text(
                                            l.adminSettlementResolveHold,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF1B6BD8),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatus == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatus = key),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }
}

class _TreasuryKpiCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const _TreasuryKpiCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
