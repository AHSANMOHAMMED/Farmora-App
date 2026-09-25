import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_format.dart';
import '../../../../core/localization/l10n.dart';
import '../../application/job_suitability.dart';
import '../../domain/collection_job.dart';
import 'job_score_badge.dart';
import 'job_status_chip.dart';

/// A job card with an optional suitability [score] badge shown next to the
/// status chip when the transporter's vehicle capacity is known.
class CollectionJobCard extends StatelessWidget {
  final CollectionJob job;
  final JobSuitability? score;
  final VoidCallback onViewDetails;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool actionLoading;

  const CollectionJobCard({
    super.key,
    required this.job,
    required this.onViewDetails,
    this.score,
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
    final l10n = context.l10n;
    final date = AppFormat.dateTime(displayDate);
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
              if (score != null) ...[
                const SizedBox(height: 8),
                JobScoreBadge(suitability: score!),
              ],
              if (job.deliveryFeeMinor != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.jobDeliveryFeeLine(
                    AppFormat.lkr(job.deliveryFeeMinor! / 100),
                  ),
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
                label: l10n.jobPickupLabel,
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
                label: l10n.jobDeliverLabel,
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
                      isCompleted
                          ? l10n.jobCompletedOn(date)
                          : l10n.jobCollectOn(date),
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
                      child: Text(
                        l10n.commonViewDetails,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                        label: Text(
                          actionLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, maxWidth: 110),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(width: 6),
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
