import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/route_progress_map.dart';
import '../../../models/transport_job.dart';
import '../../../services/firebase_service.dart';

class ActiveDeliveryScreen extends StatelessWidget {
  final TransportJob job;

  const ActiveDeliveryScreen({super.key, required this.job});

  Future<void> _transition(BuildContext context, String next) async {
    try {
      await FirestoreService().transitionTransport(job.id, next);
      if (context.mounted) Navigator.of(context).pop();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not update delivery: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Active Delivery',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
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
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusApprovedBg,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Text(
                          'IN TRANSIT',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.statusApprovedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Destination: Main Warehouse, Colombo',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            RouteProgressMap(
              progress: RouteProgressMap.progressForJobStatus(job.status),
              pickupLabel: job.pickup ?? job.route,
              dropoffLabel: job.dropoff ?? job.detail,
              statusLabel: '${job.title} • ${job.status.toUpperCase()}',
            ),
            const SizedBox(height: 24),
            const Text(
              'Delivery Status',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildTimelineStep('Picked up', '10:30 AM', true, true),
                  _buildTimelineStep(
                      'In Transit', 'Current Status', true, false),
                  _buildTimelineStep('Delivered', 'Pending', false, false,
                      isLast: true),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Status: ${job.status} • Valid next: ${job.nextStatuses.isEmpty ? 'none (terminal)' : job.nextStatuses.join(', ')}',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            for (final next in job.nextStatuses)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton(
                  onPressed: () => _transition(context, next),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: next == 'cancelled' ? AppColors.error : AppColors.primary,
                  ),
                  child: Text(
                    next == 'pickedUp' ? 'Mark Picked Up' : next == 'inTransit' ? 'Mark In Transit' : next == 'delivered' ? 'Mark as Delivered' : next == 'accepted' ? 'Accept Job' : 'Cancel Job',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
      String title, String subtitle, bool isActive, bool isCompleted,
      {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : isActive
                      ? Center(
                          child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle)))
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted
                    ? AppColors.primary
                    : AppColors.surfaceContainerHigh,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
