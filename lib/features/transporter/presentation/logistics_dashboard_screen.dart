import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../application/transporter_controller.dart';
import 'collection_job_details_screen.dart';
import 'transporter_payouts_screen.dart';
import 'widgets/collection_job_card.dart';
import 'widgets/transporter_actions.dart';
import 'widgets/transporter_states.dart';

class LogisticsDashboardScreen extends StatelessWidget {
  final VoidCallback onBrowseJobs;
  final VoidCallback onViewMyJobs;
  final VoidCallback onOpenNotifications;

  const LogisticsDashboardScreen({
    super.key,
    required this.onBrowseJobs,
    required this.onViewMyJobs,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransporterController>();
    final nearby = state.unfilteredAvailableJobs.take(3).toList();
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => state.loadJobs(refresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _DashboardHeader(
                name: state.profileName,
                unreadCount: state.unreadNotificationCount,
                onNotifications: onOpenNotifications,
              ),
              const SizedBox(height: 20),
              _AvailabilityBanner(
                available: state.isAvailable,
                onChanged: (value) async {
                  final result = await state.setAvailability(value);
                  if (context.mounted) showTransporterResult(context, result);
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: l10n.transporterSummaryAvailable,
                      value: state.unfilteredAvailableJobs.length,
                      icon: Icons.work_outline_rounded,
                      color: AppColors.statusPendingText,
                      onTap: onBrowseJobs,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      label: l10n.statusActive,
                      value: state.activeJobs.length,
                      icon: Icons.local_shipping_outlined,
                      color: const Color(0xFF1565C0),
                      onTap: onViewMyJobs,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      label: l10n.statusCompleted,
                      value: state.completedJobs.length,
                      icon: Icons.task_alt_rounded,
                      color: AppColors.primary,
                      onTap: onViewMyJobs,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _EarningsStrip(
                state: state,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TransporterPayoutsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.transporterNearbyJobs,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(onPressed: onBrowseJobs, child: Text(l10n.seeAll)),
                ],
              ),
              const SizedBox(height: 10),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.all(42),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.loadError != null)
                TransporterErrorState(
                  message: state.loadError!,
                  onRetry: state.loadJobs,
                )
              else if (nearby.isEmpty)
                TransporterEmptyState(
                  icon: Icons.route_outlined,
                  title: l10n.transporterNoOpenJobsNearby,
                  message: l10n.transporterPullToRefresh,
                  actionLabel: l10n.transporterRefresh,
                  onAction: () => state.loadJobs(refresh: true),
                )
              else
                ...nearby.map(
                  (job) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CollectionJobCard(
                      job: job,
                      onViewDetails: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CollectionJobDetailsScreen(jobId: job.id),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String name;
  final int unreadCount;
  final VoidCallback onNotifications;

  const _DashboardHeader({
    required this.name,
    required this.unreadCount,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.transporterGoodDay,
                  style: const TextStyle(color: AppColors.textMuted)),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              Text(context.l10n.transporterTagline,
                  style: const TextStyle(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
              tooltip: context.l10n.notifications,
              onPressed: onNotifications,
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -1,
                top: -2,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AvailabilityBanner extends StatelessWidget {
  final bool available;
  final ValueChanged<bool> onChanged;

  const _AvailabilityBanner({required this.available, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: available
              ? const [Color(0xFF006E1C), Color(0xFF4CAF50)]
              : const [Color(0xFF546E7A), Color(0xFF78909C)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded,
              color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  available
                      ? context.l10n.transporterAvailableForJobs
                      : context.l10n.transporterCurrentlyUnavailable,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
                Text(
                  available
                      ? context.l10n.transporterReadyToClaim
                      : context.l10n.transporterJobsStillVisible,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .82), fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: available, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          child: Column(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text('$value',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarningsStrip extends StatelessWidget {
  final TransporterController state;
  final VoidCallback onTap;

  const _EarningsStrip({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String money(int minor) => AppFormat.lkr(minor / 100);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.primaryLight,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.payments_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(context.l10n.earnings,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.transporterEarningsSummary(
                    money(state.todayEarningsMinor),
                    money(state.thisWeekEarningsMinor),
                    money(state.totalEarningsMinor),
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
