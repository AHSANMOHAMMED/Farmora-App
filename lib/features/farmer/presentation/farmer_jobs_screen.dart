import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/farmora_state.dart';
import '../../../models/transport_job.dart';

class FarmerJobsScreen extends StatelessWidget {
  const FarmerJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final currentUserId = state.currentUserId;
    
    // Filter jobs belonging to this farmer
    // (A job belongs to the farmer if the associated order's farmerId == currentUserId)
    final farmerOrders = state.orders.where((o) => o.farmerId == currentUserId).map((o) => o.id).toSet();
    final myJobs = state.jobs.where((j) => j.orderId != null && farmerOrders.contains(j.orderId)).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'My Deliveries',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: myJobs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: AppColors.outlineVariant,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No delivery requests',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: myJobs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final job = myJobs[index];
                return _buildJobCard(context, state, job);
              },
            ),
    );
  }

  Widget _buildJobCard(BuildContext context, FarmoraState state, TransportJob job) {
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
                const Icon(Icons.route_outlined, size: 18, color: AppColors.onSurfaceVariant),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                if (canCancel)
                  TextButton.icon(
                    onPressed: () {
                      _showCancelDialog(context, state, job);
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel Request'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
                else
                  Text(
                    'Accepted',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
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

  void _showCancelDialog(BuildContext context, FarmoraState state, TransportJob job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel this transport request?'),
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
