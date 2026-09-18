import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import '../../../models/order.dart';
import '../../buyer/presentation/create_dispute_screen.dart';
import '../../reviews/presentation/submit_review_screen.dart';

class LogisticsManagementScreen extends StatelessWidget {
  const LogisticsManagementScreen({super.key});

  List<FarmoraOrder> _eligibleEscrow(FarmoraState state) {
    return state.orders.where((o) {
      return o.isCompleted &&
          o.paymentStatus == 'paid' &&
          o.escrowStatus != 'released' &&
          !o.isDisputed;
    }).toList();
  }

  Future<void> _releaseEscrow(BuildContext context, FarmoraOrder order) async {
    try {
      await context.read<FarmoraState>().releaseEscrow(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Escrow released for ${order.orderNumber}.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Release failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final activeJobs =
        state.jobs.where((j) => j.isActive || j.status == 'requested').toList();
    final escrowOrders = _eligibleEscrow(state);
    final disputed = state.orders.where((o) => o.isDisputed).toList();
    final reviewable =
        state.orders.where((o) => o.canReview && o.isCompleted).take(5).toList();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Active Deliveries',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (activeJobs.isEmpty)
            const Text('No active deliveries.')
          else
            ...activeJobs.map((job) {
              return _buildDeliveryTile(
                job.orderId != null && job.orderId!.isNotEmpty
                    ? job.orderId!
                    : job.id,
                job.status.toUpperCase(),
                'Route: ${job.route}',
              );
            }),
          const SizedBox(height: 28),
          const Text('Release escrow',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Paid + delivered orders with no open dispute.',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (escrowOrders.isEmpty)
            const Text('No eligible orders.')
          else
            ...escrowOrders.map((order) {
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.outlineVariant),
                ),
                child: ListTile(
                  title: Text(
                    order.orderNumber.isNotEmpty
                        ? order.orderNumber
                        : order.id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${order.displayTotal} · ${order.status} · ${order.paymentStatus}',
                  ),
                  trailing: FilledButton(
                    onPressed: () => _releaseEscrow(context, order),
                    child: const Text('Release'),
                  ),
                ),
              );
            }),
          const SizedBox(height: 28),
          const Text('Disputes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (disputed.isEmpty)
            const Text('No open disputes.')
          else
            ...disputed.map((order) {
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.outlineVariant),
                ),
                child: ListTile(
                  title: Text(order.orderNumber.isNotEmpty
                      ? order.orderNumber
                      : order.id),
                  subtitle: Text('Dispute: ${order.disputeId}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateDisputeScreen(order: order),
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 28),
          const Text('Recent completed (reviews)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (reviewable.isEmpty)
            const Text('No reviewable orders.')
          else
            ...reviewable.map((order) {
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.outlineVariant),
                ),
                child: ListTile(
                  title: Text(order.productName.isNotEmpty
                      ? order.productName
                      : order.title),
                  subtitle: Text(order.displayTotal),
                  trailing: const Icon(Icons.rate_review_outlined),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SubmitReviewScreen(order: order),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDeliveryTile(String orderId, String status, String subtitle) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.local_shipping,
              color: AppColors.onPrimaryContainer),
        ),
        title: Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Text(status,
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
