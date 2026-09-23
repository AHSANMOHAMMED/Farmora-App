import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../application/transporter_controller.dart';
import '../domain/collection_job.dart';
import 'collection_job_details_screen.dart';
import 'widgets/collection_job_card.dart';
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('My Jobs'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _JobList(
              jobs: state.activeJobs,
              emptyTitle: 'No active jobs',
              emptyMessage: 'Jobs you accept will appear here.',
              busyJobId: _busyJobId,
              actionFor: (job) => switch (job.status) {
                CollectionJobStatus.accepted => const _JobAction(
                    label: 'Confirm pickup',
                    icon: Icons.inventory_2_outlined,
                  ),
                CollectionJobStatus.collected => const _JobAction(
                    label: 'Start delivery',
                    icon: Icons.local_shipping_outlined,
                  ),
                CollectionJobStatus.inTransit => const _JobAction(
                    label: 'Confirm delivery',
                    icon: Icons.task_alt_rounded,
                  ),
                _ => null,
              },
              onAction: (job) => _performAction(state, job),
            ),
            _JobList(
              jobs: state.completedJobs,
              emptyTitle: 'No completed deliveries',
              emptyMessage: 'Your delivery history will appear here.',
              busyJobId: _busyJobId,
            ),
            _JobList(
              jobs: state.cancelledJobs,
              emptyTitle: 'No cancelled jobs',
              emptyMessage: 'Cancelled assigned jobs will appear here.',
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
    final confirmed = await confirmTransporterAction(
      context,
      title: nextStatus == CollectionJobStatus.collected
          ? 'Confirm pickup?'
          : nextStatus == CollectionJobStatus.inTransit
              ? 'Start delivery?'
              : 'Confirm delivery?',
      message: nextStatus == CollectionJobStatus.collected
          ? 'Have you collected this produce from the farmer?'
          : 'Continue this delivery to ${job.deliveryLocation}?',
      confirmLabel: nextStatus == CollectionJobStatus.collected
          ? 'Confirm pickup'
          : nextStatus == CollectionJobStatus.inTransit
              ? 'Start delivery'
              : 'Confirm delivery',
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
