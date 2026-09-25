import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/order.dart';
import '../../../models/transport_job.dart';
import '../../../providers/farmora_state.dart';
import 'logistics_tracking_screen.dart';

class FarmerJobsScreen extends StatelessWidget {
  const FarmerJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final l10n = AppLocalizations.of(context);
    final currentUserId = state.currentUserId;

    final farmerOrders = state.orders
        .where((o) =>
            currentUserId.isEmpty ||
            o.farmerId == currentUserId ||
            o.farmerId == 'farmer_demo_1' ||
            o.farmerId.isEmpty)
        .map((o) => o.id)
        .toSet();
    final myJobs = state.jobs
        .where((j) =>
            (j.orderId != null && farmerOrders.contains(j.orderId)) ||
            (currentUserId.isEmpty && j.status != 'cancelled'))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.deliveries,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: AsyncStateView(
        isLoading: currentUserId.isNotEmpty && !state.profileLoaded,
        isEmpty: myJobs.isEmpty,
        emptyMessage: l10n.noJobs,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: myJobs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final job = myJobs[index];
            return _buildJobCard(context, state, job);
          },
        ),
      ),
    );
  }

  Widget _buildJobCard(
      BuildContext context, FarmoraState state, TransportJob job) {
    final bool canCancel = job.status == 'requested';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                _buildStatusPill(job.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.route_outlined,
                    size: 18, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.route,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.outlineVariant, height: 1),
            const SizedBox(height: 12),
            // Wraps on narrow screens instead of overflowing.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  job.fee,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canCancel) ...[
                      TextButton.icon(
                        onPressed: () => _showCancelDialog(context, state, job),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                    ElevatedButton.icon(
                      onPressed: () {
                        final matchedOrder = state.orders
                            .where((o) => o.id == job.orderId)
                            .firstOrNull;
                        final targetOrder = matchedOrder ??
                            FarmoraOrder(
                              id: job.orderId ?? 'ORD-${job.id}',
                              title: job.title,
                              detail: job.detail,
                              productName: job.title,
                              totalAmount: job.fee,
                              totalAmountNumber: double.tryParse(job.fee
                                      .replaceAll(RegExp(r'[^0-9.]'), '')) ??
                                  0.0,
                              quantity: '1 load',
                              buyerName: 'Direct Buyer',
                              deliveryAddress: job.route,
                              status: job.status == 'completed'
                                  ? 'Delivered'
                                  : 'In transit',
                              progress: job.status == 'completed' ? 1.0 : 0.6,
                              color: const Color(0xFF2E7D32),
                              timestamp: 'Today',
                            );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LogisticsTrackingScreen(order: targetOrder),
                          ),
                        );
                      },
                      icon: const Icon(Icons.navigation_outlined, size: 16),
                      label: const Text('Track Live'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'requested':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        break;
      case 'accepted':
      case 'pickedUp':
      case 'inTransit':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        break;
      case 'delivered':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        break;
      case 'cancelled':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        break;
      default:
        bgColor = AppColors.surfaceContainerHigh;
        textColor = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  void _showCancelDialog(
      BuildContext context, FarmoraState state, TransportJob job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text(
            'Are you sure you want to cancel this transport request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              state.deleteTransportJob(job.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transport request cancelled')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }
}
