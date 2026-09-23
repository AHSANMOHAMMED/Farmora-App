import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/collection_job.dart';

/// Visual step-by-step status history for a job.
///
/// Completed steps show a check with their timestamp; pending steps are
/// greyed out. Cancelled jobs show a red note after the last completed step.
class JobTimeline extends StatelessWidget {
  final CollectionJob job;

  const JobTimeline({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final steps = job.timeline;
    final isCancelled = job.status == CollectionJobStatus.cancelled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < steps.length; index++)
          _TimelineTile(
            step: steps[index].step,
            at: steps[index].at,
            isFirst: index == 0,
            isLast: index == steps.length - 1,
          ),
        if (isCancelled) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.cancel_rounded,
                  size: 18, color: Colors.redAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Job cancelled${job.notes == null ? '' : ' — see notes below'}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final CollectionJobTimelineStep step;
  final DateTime? at;
  final bool isFirst;
  final bool isLast;

  const _TimelineTile({
    required this.step,
    required this.at,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final done = at != null;
    final color = done ? AppColors.primary : AppColors.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 2, height: 8, color: AppColors.outlineVariant),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? color : Colors.transparent,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 12, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: done ? color : AppColors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              // Align the label with the dot, leaving room for the connector.
              padding: EdgeInsets.only(
                top: isFirst ? 0 : 8,
                bottom: isLast ? 0 : 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontWeight: done ? FontWeight.w800 : FontWeight.w600,
                      color: done
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (at != null)
                    Text(
                      DateFormat('d MMM yyyy • h:mm a').format(at!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
