import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/settlement_model.dart';
import '../../../providers/farmora_state.dart';
import '../application/transporter_controller.dart';

/// Transporter earnings (delivered jobs' `deliveryFeeMinor`) with payout
/// withdrawal requests (`requestWithdrawal` callable) and the transporter's
/// own settlements.
class TransporterPayoutsScreen extends StatelessWidget {
  const TransporterPayoutsScreen({super.key});

  /// Minor units already requested/paid out (rejected requests don't count),
  /// mirroring the server's balance check.
  static int withdrawnMinor(List<SettlementPayout> settlements) =>
      settlements
          .where((s) => s.status != 'rejected')
          .fold(0, (sum, s) => sum + (s.netAmount * 100).round());

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<TransporterController>();
    final app = context.watch<FarmoraState>();
    final uid = jobs.providerId;
    final settlements = app.settlements
        .where((s) => uid.isEmpty || s.recipientId == uid)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final earned = jobs.totalEarningsMinor;
    final available = (earned - withdrawnMinor(settlements)).clamp(0, earned);
    String money(int minor) => AppFormat.lkr(minor / 100, decimals: 2);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.earnings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: AppColors.primaryLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available to withdraw',
                      style: TextStyle(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(
                    money(available),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.transporterEarningsSummary(
                      money(jobs.todayEarningsMinor),
                      money(jobs.thisWeekEarningsMinor),
                      money(earned),
                    ),
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: available <= 0
                        ? null
                        : () => _requestWithdrawal(context, available),
                    icon: const Icon(Icons.account_balance_outlined),
                    label: const Text('Request withdrawal'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Withdrawals',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (settlements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No withdrawal requests yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            )
          else
            ...settlements.map((s) => _SettlementTile(settlement: s)),
        ],
      ),
    );
  }

  Future<void> _requestWithdrawal(
      BuildContext context, int availableMinor) async {
    final request = await showDialog<_WithdrawalRequest>(
      context: context,
      builder: (_) => _WithdrawalDialog(availableMinor: availableMinor),
    );
    if (request == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      await context.read<FarmoraState>().requestWithdrawal(
            amount: request.amount,
            bankName: request.bankName,
            accountNumber: request.accountNumber,
            payoutMethod: request.payoutMethod,
          );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Withdrawal requested. It will appear below once '
              'processed by Farmora.'),
        ));
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: errorColor,
          content: Text(userMessage(error, action: 'request a withdrawal')),
        ));
    }
  }
}

class _WithdrawalRequest {
  final double amount;
  final String bankName;
  final String accountNumber;
  final String payoutMethod;

  const _WithdrawalRequest({
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.payoutMethod,
  });
}

class _WithdrawalDialog extends StatefulWidget {
  final int availableMinor;

  const _WithdrawalDialog({required this.availableMinor});

  @override
  State<_WithdrawalDialog> createState() => _WithdrawalDialogState();
}

class _WithdrawalDialogState extends State<_WithdrawalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  final _bank = TextEditingController();
  final _account = TextEditingController();
  String _method = 'CEFT';

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: (widget.availableMinor / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _bank.dispose();
    _account.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: const Text('Request withdrawal'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (LKR)',
                  helperText:
                      'Available: ${AppFormat.lkr(widget.availableMinor / 100, decimals: 2)}',
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return l10n.invalidPayoutAmount;
                  }
                  if ((amount * 100).round() > widget.availableMinor) {
                    return 'Amount exceeds your available balance.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _bank,
                decoration: InputDecoration(
                  labelText: l10n.bankNameLabel,
                  hintText: l10n.bankNameHint,
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Enter your bank name.'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _account,
                decoration: const InputDecoration(labelText: 'Account number'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return l10n.pleaseEnterAccountNumber;
                  if (text.length < 4 ||
                      !RegExp(r'^[0-9A-Za-z -]+$').hasMatch(text)) {
                    return 'Invalid account number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Payout method'),
                items: const [
                  DropdownMenuItem(value: 'CEFT', child: Text('CEFT')),
                  DropdownMenuItem(value: 'SLIP', child: Text('SLIP')),
                  DropdownMenuItem(
                      value: 'Mobile Wallet', child: Text('Mobile Wallet')),
                ],
                onChanged: (value) => setState(() => _method = value ?? 'CEFT'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _WithdrawalRequest(
                amount: double.parse(_amount.text.trim()),
                bankName: _bank.text.trim(),
                accountNumber: _account.text.trim(),
                payoutMethod: _method,
              ),
            );
          },
          child: Text(l10n.commonSubmit),
        ),
      ],
    );
  }
}

class _SettlementTile extends StatelessWidget {
  final SettlementPayout settlement;

  const _SettlementTile({required this.settlement});

  @override
  Widget build(BuildContext context) {
    final status = settlement.status;
    final color = switch (status) {
      'settled' || 'paid' || 'completed' => AppColors.primary,
      'rejected' || 'failed' => AppColors.error,
      'on_hold' => Colors.orange,
      _ => AppColors.statusPendingText,
    };
    final label = status.replaceAll('_', ' ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      child: ListTile(
        leading: Icon(Icons.account_balance_wallet_outlined, color: color),
        title: Text(
          AppFormat.lkr(settlement.netAmount, decimals: 2),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            '${settlement.bankName} • ${settlement.payoutMethod}',
            AppFormat.date(settlement.createdAt),
            if ((settlement.holdReason ?? '').isNotEmpty)
              settlement.holdReason!,
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label.isEmpty
                ? '-'
                : label[0].toUpperCase() + label.substring(1),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
