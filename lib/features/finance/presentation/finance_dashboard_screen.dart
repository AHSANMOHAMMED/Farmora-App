import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../providers/farmora_state.dart';

/// Finance home: payout pipeline totals and paid order value, with a
/// shortcut to the settlements queue (shared with admins).
class FinanceDashboardScreen extends StatelessWidget {
  const FinanceDashboardScreen({super.key, required this.onOpenSettlements});

  final VoidCallback onOpenSettlements;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<FarmoraState>();
    double total(bool Function(String) match) => state.settlements
        .where((s) => match(s.status.toLowerCase()))
        .fold<double>(0, (sum, s) => sum + s.netAmount);
    int count(bool Function(String) match) => state.settlements
        .where((s) => match(s.status.toLowerCase()))
        .length;
    bool pending(String s) => s == 'pending';
    bool processing(String s) => s == 'processing';
    bool hold(String s) => s.contains('hold');
    bool settled(String s) => s == 'settled' || s == 'completed';
    final paidMinor = state.orders
        .where((o) =>
            o.paymentStatus == 'paid' || o.paymentStatus == 'released')
        .fold<int>(0, (sum, o) => sum + o.totalMinor);

    Widget tile(IconData icon, String label, int n, double amount, Color c) =>
        Card(
          child: ListTile(
            leading: Icon(icon, color: c),
            title: Text(label),
            subtitle: Text('$n'),
            trailing: Text(AppFormat.lkr(amount),
                style: TextStyle(fontWeight: FontWeight.w800, color: c)),
            onTap: onOpenSettlements,
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l.finTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          tile(Icons.pending_actions_outlined, l.finPending, count(pending),
              total(pending), const Color(0xFFE65100)),
          tile(Icons.sync_rounded, l.finProcessing, count(processing),
              total(processing), const Color(0xFF1565C0)),
          tile(Icons.pause_circle_outline, l.finOnHold, count(hold),
              total(hold), AppColors.error),
          tile(Icons.check_circle_outline, l.finSettled, count(settled),
              total(settled), AppColors.primary),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(l.finCashCollected),
              trailing: Text(AppFormat.lkr(paidMinor / 100),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onOpenSettlements,
            icon: const Icon(Icons.account_balance_outlined),
            label: Text(l.finOpenSettlements),
          ),
        ],
      ),
    );
  }
}
