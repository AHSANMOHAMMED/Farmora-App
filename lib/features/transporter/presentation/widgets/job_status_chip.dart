import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/collection_job.dart';

class JobStatusChip extends StatelessWidget {
  final CollectionJobStatus status;

  const JobStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (status) {
      CollectionJobStatus.open => (
          AppColors.statusPendingBg,
          AppColors.statusPendingText,
          Icons.schedule_rounded,
        ),
      CollectionJobStatus.accepted => (
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
          Icons.assignment_turned_in_outlined,
        ),
      CollectionJobStatus.collected => (
          const Color(0xFFEDE7F6),
          const Color(0xFF5E35B1),
          Icons.inventory_2_outlined,
        ),
      CollectionJobStatus.inTransit => (
          const Color(0xFFE0F7FA),
          const Color(0xFF00796B),
          Icons.local_shipping_outlined,
        ),
      CollectionJobStatus.completed => (
          AppColors.statusApprovedBg,
          AppColors.statusApprovedText,
          Icons.check_circle_outline_rounded,
        ),
      CollectionJobStatus.cancelled => (
          AppColors.errorContainer,
          AppColors.onErrorContainer,
          Icons.cancel_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            status.label.toUpperCase(),
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    );
  }
}
