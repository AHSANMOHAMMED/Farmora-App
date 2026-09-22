import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/earnings_model.dart';
import '../../../models/transport_job.dart';
import '../../../providers/farmora_state.dart';

class TransporterEarningsScreen extends StatelessWidget {
  const TransporterEarningsScreen({super.key});

  double _feeToLkr(TransportJob job) {
    final digits =
        RegExp(r'[\d.]+').allMatches(job.fee).map((m) => m.group(0)!);
    if (digits.isEmpty) return 0;
    return double.tryParse(digits.first) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final l10n = AppLocalizations.of(context);
    const currency = 'Rs. ';

    final completedJobs =
        state.jobs.where((j) => j.isDelivered).toList();
    final totalEarned = completedJobs.fold<double>(
      0,
      (sum, j) => sum + _feeToLkr(j),
    );

    // If state transactions exist, prefer those; otherwise build from completed jobs
    final transactions = state.transactions.isNotEmpty
        ? state.transactions.reversed.take(10).toList()
        : completedJobs.map((j) {
            final routeDesc = j.route.isNotEmpty
                ? j.route
                : (j.pickup != null && j.dropoff != null
                    ? '${j.pickup} -> ${j.dropoff}'
                    : 'Delivery');
            return EarningsTransaction(
              id: j.id,
              orderNumber: j.id.length > 8 ? j.id.substring(0, 8) : j.id,
              date: routeDesc,
              amount: _feeToLkr(j),
            );
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l10n.earnings),
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
      ),
      body: AsyncStateView(
        isLoading: state.currentUserId.isNotEmpty && !state.profileLoaded,
        isEmpty: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _EarningsHero(
              amount: '$currency${totalEarned > 0 ? totalEarned.toStringAsFixed(2) : state.totalEarnings.toStringAsFixed(2)}',
              label: l10n.netEarnings,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'This month',
                    value: '$currency${state.thisMonth.toStringAsFixed(2)}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'This week',
                    value: '$currency${state.thisWeek.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (transactions.isEmpty)
              const _EmptyState(
                icon: Icons.receipt_long_outlined,
                message: 'No earnings yet',
              )
            else
              ...transactions.map(
                (transaction) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.local_shipping_outlined,
                          color: AppColors.primary),
                    ),
                    title: Text(
                      transaction.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(transaction.date),
                    trailing: Text(
                      '+ $currency${transaction.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EarningsHero extends StatelessWidget {
  final String amount;
  final String label;
  const _EarningsHero({required this.amount, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.onPrimaryContainer),
                ),
                const SizedBox(height: 6),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Available Balance',
                  style: TextStyle(color: AppColors.onPrimaryContainer, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.bar_chart_rounded,
            size: 42,
            color: AppColors.onPrimaryContainer,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.outlineVariant),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
