import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/farmora_state.dart';

class TransporterEarningsScreen extends StatelessWidget {
  const TransporterEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    const currency = 'Rs. ';
    final transactions = state.transactions.reversed.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _EarningsHero(
              amount: '$currency${state.totalEarnings.toStringAsFixed(2)}'),
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
                  title: Text(transaction.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
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
                const Text('Total Earnings',
                    style: TextStyle(color: AppColors.onPrimaryContainer)),
                const SizedBox(height: 6),
                Text(amount,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimaryContainer)),
                const SizedBox(height: 4),
                const Text('This month',
                    style: TextStyle(color: AppColors.onPrimaryContainer)),
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
