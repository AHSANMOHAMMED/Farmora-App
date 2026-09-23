import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/collection_job.dart';
import 'job_status_chip.dart';

class CollectionJobCard extends StatelessWidget {
  final CollectionJob job;
  final VoidCallback onViewDetails;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool actionLoading;

  const CollectionJobCard({
    super.key,
    required this.job,
    required this.onViewDetails,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.actionLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = job.status == CollectionJobStatus.completed;
    final displayDate =
        isCompleted ? (job.completedAt ?? job.updatedAt) : job.collectionDate;
    final date = DateFormat('EEE, d MMM • h:mm a').format(displayDate);
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side:
            BorderSide(color: AppColors.outlineVariant.withValues(alpha: .35)),
      ),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.eco_outlined,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.produceName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          job.quantityLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  JobStatusChip(status: job.status),
                ],
              ),
              if (job.deliveryFeeMinor != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Delivery fee: Rs. ${(job.deliveryFeeMinor! / 100).toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _RouteLine(
                icon: Icons.trip_origin_rounded,
                iconColor: AppColors.primary,
                label: 'Pickup',
                value: job.pickupLocation,
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 1,
                height: 12,
                color: AppColors.outlineVariant,
              ),
              _RouteLine(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.secondary,
                label: 'Deliver',
                value: job.deliveryLocation,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      isCompleted ? 'Completed $date' : 'Collect $date',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onViewDetails,
                      child: const Text('View details'),
                    ),
                  ),
                  if (actionLabel != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: actionLoading ? null : onAction,
                        icon: actionLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(actionIcon ?? Icons.arrow_forward_rounded,
                                size: 18),
                        label: Text(actionLabel!),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _RouteLine({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(width: 9),
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
