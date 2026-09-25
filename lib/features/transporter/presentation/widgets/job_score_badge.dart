import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../application/job_suitability.dart';

/// Compact badge showing a job's suitability score (0-100) for the
/// current transporter's vehicle.
class JobScoreBadge extends StatelessWidget {
  final JobSuitability suitability;

  const JobScoreBadge({super.key, required this.suitability});

  @override
  Widget build(BuildContext context) {
    final color = switch (suitability.score) {
      >= 80 => Colors.green,
      >= 60 => const Color(0xFF1565C0),
      >= 40 => Colors.orange,
      _ => Colors.grey,
    };
    final tooltip = [
      context.l10n.jobScoreTooltip(suitability.score),
      if (suitability.warning != null) suitability.warning!,
    ].join(' · ');
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              suitability.capacityFit
                  ? Icons.bolt_rounded
                  : Icons.warning_amber_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '${suitability.score}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
