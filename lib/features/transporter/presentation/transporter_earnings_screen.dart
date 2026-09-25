import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../application/transporter_controller.dart';

class TransporterEarningsScreen extends StatelessWidget {
  const TransporterEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TransporterController>();
    final l10n = context.l10n;
    String money(double amount) => AppFormat.lkr(amount, decimals: 2);

    final completed = controller.completedJobs;
    double total = 0;
    double month = 0;
    double week = 0;
    final now = DateTime.now();

    for (final job in completed) {
      final amount = (job.deliveryFeeMinor ?? 0) / 100;
      total += amount;

      final date = job.completedAt ?? job.updatedAt;
      if (date.year == now.year && date.month == now.month) {
        month += amount;
      }
      if (now.difference(date).inDays <= 7) {
        week += amount;
      }
    }

    final recent = completed.reversed.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l10n.earnings),
        actions: [
          IconButton(
            tooltip: l10n.notifications,
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _EarningsHero(amount: money(total)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: l10n.transporterThisMonth,
                  value: money(month),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: l10n.transporterThisWeek,
                  value: money(week),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.transporterRecentTransactions,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            _EmptyState(
              icon: Icons.receipt_long_outlined,
              message: l10n.transporterNoEarningsYet,
            )
          else
            ...recent.map((job) {
              final amount = (job.deliveryFeeMinor ?? 0) / 100;
              final dateStr = AppFormat.date(job.completedAt ?? job.updatedAt);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.local_shipping_outlined,
                        color: AppColors.primary),
                  ),
                  title: Text(job.produceName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(dateStr),
                  trailing: Text(
                    '+ ${money(amount)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _EarningsHero extends StatelessWidget {
  final String amount;
  const _EarningsHero({required this.amount});

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
                Text(context.l10n.transporterTotalEarnings,
                    style:
                        const TextStyle(color: AppColors.onPrimaryContainer)),
                const SizedBox(height: 6),
                Text(amount,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimaryContainer)),
                const SizedBox(height: 4),
                Text(context.l10n.transporterThisMonth,
                    style:
                        const TextStyle(color: AppColors.onPrimaryContainer)),
              ],
            ),
          ),
          const Icon(Icons.bar_chart_rounded,
              size: 42, color: AppColors.onPrimaryContainer),
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
            Text(label,
                style: const TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
            Text(message,
                style: const TextStyle(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
