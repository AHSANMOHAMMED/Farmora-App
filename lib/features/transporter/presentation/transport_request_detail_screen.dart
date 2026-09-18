import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/farmora_state.dart';
import '../../../models/transport_job.dart';
import '../../messaging/presentation/conversations_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';

class TransportRequestDetailScreen extends StatelessWidget {
  final TransportJob job;

  const TransportRequestDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final linkedOrder = job.orderId == null
        ? null
        : state.orders.where((o) => o.id == job.orderId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Request Details',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          if (job.orderId != null && job.orderId!.isNotEmpty)
            IconButton(
              tooltip: 'Message',
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ConversationsScreen(orderId: job.orderId),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          job.title.isNotEmpty ? job.title : 'Transport job',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      if (job.fee.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            job.fee,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.route, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          job.route.isNotEmpty
                              ? job.route
                              : '${job.pickup ?? 'Pickup'} → ${job.dropoff ?? 'Dropoff'}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (job.detail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      job.detail,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (job.district != null && job.district!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'District: ${job.district}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if ((job.weightKg ?? job.capacityKg) != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Load: ${job.weightKg ?? job.capacityKg} kg',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Job Details',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (job.orderId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Linked Order ID',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            job.orderId!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: ${job.status}',
                          style: const TextStyle(
                              fontFamily: 'Inter', fontWeight: FontWeight.bold),
                        ),
                        if (linkedOrder != null)
                          Text(
                            linkedOrder.deliveryAddress.isNotEmpty
                                ? linkedOrder.deliveryAddress
                                : (job.dropoff ?? job.detail),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.onSurfaceVariant,
                            ),
                          )
                        else if (job.pickup != null || job.dropoff != null)
                          Text(
                            'Pickup: ${job.pickup ?? '—'} · Dropoff: ${job.dropoff ?? '—'}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 4),
                        const Text(
                          'Contact via in-app messaging — phone numbers stay private.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: _buildActionButtons(context),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (!job.accepted && job.status == 'requested') {
      return FilledButton(
        onPressed: () {
          context.read<FarmoraState>().acceptJob(job.id);
          Navigator.of(context).pop();
        },
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: AppColors.primary,
        ),
        child: const Text(
          'Accept Request',
          style: TextStyle(
              fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (job.status == 'accepted') {
      return FilledButton(
        onPressed: () {
          context.read<FarmoraState>().updateJobStatus(job.id, 'pickedUp');
          Navigator.of(context).pop();
        },
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Mark as Picked Up'),
      );
    }

    if (job.status == 'pickedUp') {
      return FilledButton(
        onPressed: () {
          context.read<FarmoraState>().updateJobStatus(job.id, 'inTransit');
          Navigator.of(context).pop();
        },
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Mark as In Transit'),
      );
    }

    if (job.status == 'inTransit') {
      return FilledButton(
        onPressed: () {
          context.read<FarmoraState>().updateJobStatus(job.id, 'delivered');
          Navigator.of(context).pop();
        },
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Mark as Delivered'),
      );
    }

    return FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(job.status.toUpperCase()),
    );
  }
}
