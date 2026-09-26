import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../application/transporter_controller.dart';
import '../domain/collection_job.dart';
import 'collection_job_details_screen.dart';
import 'widgets/collection_job_card.dart';
import 'widgets/live_location.dart';
import 'widgets/transporter_actions.dart';
import 'widgets/transporter_states.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  String? _busyJobId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransporterController>();
    final l10n = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(l10n.transporterMyJobsTitle),
          bottom: TabBar(
            isScrollable: false,
            tabs: [
              Tab(text: l10n.statusActive),
              Tab(text: l10n.statusCompleted),
              Tab(text: l10n.statusCancelled),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _JobList(
              jobs: state.activeJobs,
              emptyTitle: l10n.transporterNoActiveJobs,
              emptyMessage: l10n.transporterNoActiveJobsHint,
              busyJobId: _busyJobId,
              actionFor: (job) => switch (job.status) {
                CollectionJobStatus.accepted => _JobAction(
                    label: l10n.jobConfirmPickupAction,
                    icon: Icons.inventory_2_outlined,
                  ),
                CollectionJobStatus.collected => _JobAction(
                    label: l10n.jobStartDeliveryAction,
                    icon: Icons.local_shipping_outlined,
                  ),
                CollectionJobStatus.inTransit => _JobAction(
                    label: l10n.jobConfirmDeliveryAction,
                    icon: Icons.task_alt_rounded,
                  ),
                _ => null,
              },
              onAction: (job) => _performAction(state, job),
            ),
            _JobList(
              jobs: state.completedJobs,
              emptyTitle: l10n.transporterNoCompletedDeliveries,
              emptyMessage: l10n.transporterNoCompletedHint,
              busyJobId: _busyJobId,
            ),
            _JobList(
              jobs: state.cancelledJobs,
              emptyTitle: l10n.transporterNoCancelledJobs,
              emptyMessage: l10n.transporterNoCancelledHint,
              busyJobId: _busyJobId,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performAction(
    TransporterController state,
    CollectionJob job,
  ) async {
    final nextStatus = switch (job.status) {
      CollectionJobStatus.accepted => CollectionJobStatus.collected,
      CollectionJobStatus.collected => CollectionJobStatus.inTransit,
      _ => CollectionJobStatus.completed,
    };
    final l10n = context.l10n;
    final confirmed = await confirmTransporterAction(
      context,
      title: nextStatus == CollectionJobStatus.collected
          ? l10n.jobConfirmPickupTitle
          : nextStatus == CollectionJobStatus.inTransit
              ? l10n.jobStartDeliveryTitle
              : l10n.jobConfirmDeliveryTitle,
      message: nextStatus == CollectionJobStatus.collected
          ? l10n.jobConfirmPickupMessage
          : l10n.jobContinueDeliveryMessage(job.deliveryLocation),
      confirmLabel: nextStatus == CollectionJobStatus.collected
          ? l10n.jobConfirmPickupAction
          : nextStatus == CollectionJobStatus.inTransit
              ? l10n.jobStartDeliveryAction
              : l10n.jobConfirmDeliveryAction,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busyJobId = job.id);
    final result = switch (nextStatus) {
      CollectionJobStatus.collected => await state.markCollected(job.id),
      CollectionJobStatus.inTransit => await state.startDelivery(job.id),
      _ => await state.completeDelivery(job.id),
    };
    if (!mounted) return;
    setState(() => _busyJobId = null);
    showTransporterResult(context, result);
    if (result.success) await syncLiveSharing(context, job.id, nextStatus);
  }
}

class _JobList extends StatelessWidget {
  final List<CollectionJob> jobs;
  final String emptyTitle;
  final String emptyMessage;
  final String? busyJobId;
  final _JobAction? Function(CollectionJob job)? actionFor;
  final ValueChanged<CollectionJob>? onAction;

  const _JobList({
    required this.jobs,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.busyJobId,
    this.actionFor,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return TransporterEmptyState(
        icon: Icons.local_shipping_outlined,
        title: emptyTitle,
        message: emptyMessage,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = jobs[index];
        final action = actionFor?.call(job);
        return CollectionJobCard(
          job: job,
          actionLabel: action?.label,
          actionIcon: action?.icon,
          actionLoading: busyJobId == job.id,
          onAction: action == null ? null : () => onAction?.call(job),
          onViewDetails: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CollectionJobDetailsScreen(jobId: job.id),
            ),
          ),
        );
      },
    );
  }
}

class _JobAction {
  final String label;
  final IconData icon;

  const _JobAction({required this.label, required this.icon});
}
