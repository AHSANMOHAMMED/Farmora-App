import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/route_progress_map.dart';
import '../../../models/transport_job.dart';
import '../../../services/delivery_location_service.dart';
import '../../../services/firebase_service.dart';
import '../../messaging/presentation/conversations_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';

class ActiveDeliveryScreen extends StatelessWidget {
  final TransportJob job;

  const ActiveDeliveryScreen({super.key, required this.job});

  Future<void> _transition(BuildContext context, String next) async {
    try {
      if (next == 'pickedUp' || next == 'inTransit') {
        await DeliveryLocationService.instance
            .requestConsentAndStart(jobId: job.id);
        final pos = await DeliveryLocationService.instance.currentPosition();
        if (pos != null) {
          await FirestoreService().updateTransportJobLocation(
            jobId: job.id,
            lat: pos.latitude,
            lng: pos.longitude,
          );
        }
      }
      await FirestoreService().transitionTransport(job.id, next);
      DeliveryLocationService.instance.onJobStatusChanged(job.id, next);
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
    final destination = job.dropoff ?? job.route;
    final steps = [
      ('Accepted', job.status != 'requested'),
      ('Picked up', ['pickedUp', 'inTransit', 'delivered'].contains(job.status)),
      ('In transit', ['inTransit', 'delivered'].contains(job.status)),
      ('Delivered', job.status == 'delivered'),
    ];

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
        actions: [
          IconButton(
            tooltip: 'Messages',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConversationsScreen()),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
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
                          job.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusApprovedBg,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          job.status.toUpperCase(),
                          style: const TextStyle(
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
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Destination: $destination',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (job.fee.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Fee: ${job.fee}',
                        style: const TextStyle(fontFamily: 'Inter')),
                  ],
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
                  for (var i = 0; i < steps.length; i++)
                    _buildTimelineStep(
                      steps[i].$1,
                      steps[i].$2 ? 'Done' : 'Pending',
                      steps[i].$2,
                      i < steps.length - 1 && steps[i].$2,
                      isLast: i == steps.length - 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: job.canTransition
          ? Container(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () => _transition(context, job.nextStatuses.first),
                child: Text('Mark ${job.nextStatuses.first}'),
              ),
            )
          : null,
    );
  }

  Widget _buildTimelineStep(
    String title,
    String subtitle,
    bool completed,
    bool showLine, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: completed ? AppColors.primary : AppColors.outlineVariant,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: showLine ? AppColors.primary : AppColors.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
