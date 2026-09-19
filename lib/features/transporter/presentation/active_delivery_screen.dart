import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/transport_job.dart';
import '../../../providers/farmora_state.dart';

class ActiveDeliveryScreen extends StatelessWidget {
  final TransportJob job;

  const ActiveDeliveryScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final currentJob = state.jobs.firstWhere(
      (j) => j.id == job.id,
      orElse: () => job,
    );

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
          if (currentJob.status != TransportJobStatus.cancelled &&
              currentJob.status != TransportJobStatus.delivered)
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              onPressed: () => _showCancelDialog(context, currentJob.id),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Info Card
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
                        currentJob.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      _buildStatusChip(currentJob.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.route, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentJob.route,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentJob.detail,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (currentJob.cargoWeightKg != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.scale, size: 16, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          '${currentJob.cargoWeightKg!.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Map placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: AppColors.outlineVariant),
                    SizedBox(height: 8),
                    Text(
                      'Live Tracking Map',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Delivery Status Timeline
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
              child: _buildTimeline(currentJob.status),
            ),
            const SizedBox(height: 24),

            // Pickup Information
            const Text(
              'Pickup Information',
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
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Farmer Name',
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currentJob.pickupAddress ?? 'Pickup location',
                        style: const TextStyle(fontFamily: 'Inter', color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(context, currentJob),
    );
  }

  Widget _buildStatusChip(TransportJobStatus status) {
    final (backgroundColor, textColor) = switch (status) {
      TransportJobStatus.pending => (AppColors.surfaceContainerHigh, AppColors.onSurfaceVariant),
      TransportJobStatus.accepted => (AppColors.primaryContainer, AppColors.onPrimaryContainer),
      TransportJobStatus.inTransit => (AppColors.statusApprovedBg, AppColors.statusApprovedText),
      TransportJobStatus.delivered => (AppColors.statusApprovedBg, AppColors.statusApprovedText),
      TransportJobStatus.cancelled => (AppColors.errorContainer, AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTimeline(TransportJobStatus currentStatus) {
    final steps = [
      ('Accepted', 'Job assigned', TransportJobStatus.accepted),
      ('Picked Up', 'Cargo collected', TransportJobStatus.inTransit),
      ('Delivered', 'Drop-off complete', TransportJobStatus.delivered),
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final (title, subtitle, status) = entry.value;
        final isActive = currentStatus == status;
        final isCompleted = _isStepCompleted(currentStatus, status);
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.statusApprovedBg
                        : isActive
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: AppColors.statusApprovedText)
                      : isActive
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color: isCompleted ? AppColors.primary : AppColors.surfaceContainerHigh,
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
      }).toList(),
    );
  }

  bool _isStepCompleted(TransportJobStatus current, TransportJobStatus step) {
    return switch (current) {
      TransportJobStatus.delivered => true,
      TransportJobStatus.inTransit => step == TransportJobStatus.accepted,
      TransportJobStatus.accepted => step == TransportJobStatus.accepted,
      _ => false,
    };
  }

  Widget? _buildBottomButton(BuildContext context, TransportJob job) {
    if (job.status == TransportJobStatus.delivered ||
        job.status == TransportJobStatus.cancelled) {
      return null;
    }

    final (buttonText, nextStatus) = switch (job.status) {
      TransportJobStatus.accepted => ('Mark as Picked Up', TransportJobStatus.inTransit),
      TransportJobStatus.inTransit => ('Mark as Delivered', TransportJobStatus.delivered),
      _ => (null, null),
    };

    if (buttonText == null || nextStatus == null) return null;

    return Container(
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
      child: FilledButton(
        onPressed: () async {
          try {
            await context.read<FarmoraState>().transitionTransportJob(job.id, nextStatus);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Delivery updated to ${nextStatus.label}')),
              );
            }
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not update delivery: $error')),
              );
            }
          }
        },
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: AppColors.primary,
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
              fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String jobId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Cancel Delivery',
          style: TextStyle(fontFamily: 'Inter'),
        ),
        content: const Text(
          'Are you sure you want to cancel this delivery? This action cannot be undone.',
          style: TextStyle(fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No', style: TextStyle(fontFamily: 'Inter')),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<FarmoraState>().cancelTransportJob(jobId);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delivery cancelled')),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not cancel delivery: $error')),
                  );
                }
              }
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(fontFamily: 'Inter', color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
