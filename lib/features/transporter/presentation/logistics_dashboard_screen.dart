import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../application/transporter_controller.dart';
import 'collection_job_details_screen.dart';
import 'widgets/collection_job_card.dart';
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
                onChanged: state.setAvailability,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Available',
                      value: state.unfilteredAvailableJobs.length,
                      icon: Icons.work_outline_rounded,
                      color: AppColors.statusPendingText,
                      onTap: onBrowseJobs,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Active',
                      value: state.activeJobs.length,
                      icon: Icons.local_shipping_outlined,
                      color: const Color(0xFF1565C0),
                      onTap: onViewMyJobs,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Completed',
                      value: state.completedJobs.length,
                      icon: Icons.task_alt_rounded,
                      color: AppColors.primary,
                      onTap: onViewMyJobs,
                    ),
                  ),
                ],
              ),
              if (state.completedJobs
                  .any((job) => job.deliveryFeeMinor != null)) ...[
                const SizedBox(height: 12),
                _EarningsStrip(state: state),
              ],
              const SizedBox(height: 26),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nearby available jobs',
                      style:
                          TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                      onPressed: onBrowseJobs, child: const Text('See all')),
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
                  title: 'No open jobs nearby',
                  message: 'Pull down to refresh or check again shortly.',
                  actionLabel: 'Refresh',
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
              const Text('Good day,',
                  style: TextStyle(color: AppColors.textMuted)),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const Text('Keep Sri Lanka’s harvest moving',
                  style: TextStyle(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
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
                  available ? 'Available for jobs' : 'Currently unavailable',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
                Text(
                  available
                      ? 'Ready to claim collections'
                      : 'New jobs remain visible',
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

  const _EarningsStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    String money(int minor) => 'Rs. ${(minor / 100).toStringAsFixed(0)}';
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.payments_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Earnings',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            Text(
              'Today ${money(state.todayEarningsMinor)}\n'
              'Week ${money(state.thisWeekEarningsMinor)}\n'
              'Total ${money(state.totalEarningsMinor)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
