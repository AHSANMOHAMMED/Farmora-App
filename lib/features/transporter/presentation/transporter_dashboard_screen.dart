import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/job_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/transport_job.dart';
import '../../../providers/farmora_state.dart';
import 'active_delivery_screen.dart';

class TransporterDashboardScreen extends StatelessWidget {
  const TransporterDashboardScreen({super.key});

  double _feeToLkr(TransportJob job) {
    final digits = RegExp(r'[\d.]+').allMatches(job.fee).map((m) => m.group(0)!);
    if (digits.isEmpty) return 0;
    return double.tryParse(digits.first) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final l10n = AppLocalizations.of(context);
    final jobs = state.jobs;
    final completed = jobs.where((j) => j.isDelivered).toList();
    final pending = jobs
        .where((j) => j.status == 'requested' || j.status == 'accepted')
        .toList();
    final active = jobs.where((j) => j.isActive).toList();
    final earnings = completed.fold<double>(0, (sum, j) => sum + _feeToLkr(j));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        title: Text(
          l10n.overview,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: AsyncStateView(
        isLoading: state.currentUserId.isNotEmpty && !state.profileLoaded,
        isEmpty: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.netEarnings,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LKR ${earnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${completed.length} ${l10n.delivered.toLowerCase()}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: l10n.delivered,
                      value: '${completed.length}',
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: l10n.pending,
                      value: '${pending.length}',
                      icon: Icons.pending_actions,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.inTransit,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              if (active.isNotEmpty)
                ...active.map(
                  (j) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: JobCard(
                      title: j.title,
                      route: j.route,
                      detail: j.detail,
                      fee: j.fee,
                      accepted: j.accepted,
                      onAccept: () {},
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ActiveDeliveryScreen(job: j),
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.noJobs,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
