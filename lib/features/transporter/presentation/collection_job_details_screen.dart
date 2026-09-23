import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../application/transporter_controller.dart';
import '../domain/collection_job.dart';
import 'widgets/job_status_chip.dart';
import 'widgets/job_timeline.dart';
import 'widgets/transporter_actions.dart';
import 'widgets/transporter_states.dart';

class CollectionJobDetailsScreen extends StatefulWidget {
  final String jobId;

  const CollectionJobDetailsScreen({super.key, required this.jobId});

  @override
  State<CollectionJobDetailsScreen> createState() =>
      _CollectionJobDetailsScreenState();
}

class _CollectionJobDetailsScreenState
    extends State<CollectionJobDetailsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransporterController>();
    final job = state.jobById(widget.jobId);
    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job details')),
        body: TransporterEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Job unavailable',
          message: 'This job may have been removed. Return to the jobs list.',
          actionLabel: 'Go back',
          onAction: () => Navigator.maybePop(context),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text('Job #${job.id}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _JobHero(job: job),
          const SizedBox(height: 14),
          _Section(
            title: 'Job timeline',
            children: [JobTimeline(job: job)],
          ),
          if (job.logisticsProviderId == state.providerId &&
              state.vehicleCapacity != null) ...[
            const SizedBox(height: 14),
            _Section(
              title: 'Vehicle suitability',
              children: [
                Text(
                  _capacityText(state, job),
                  style: TextStyle(
                    color: _isSuitable(state, job)
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          _Section(
            title: 'Collection route',
            children: [
              _DetailRow(
                icon: Icons.trip_origin_rounded,
                label: 'Pickup',
                value: job.pickupLocation,
              ),
              _DetailRow(
                icon: Icons.location_on_rounded,
                label: 'Delivery',
                value: job.deliveryLocation,
              ),
              _DetailRow(
                icon: Icons.calendar_month_outlined,
                label: 'Collection',
                value: DateFormat('EEEE, d MMMM yyyy • h:mm a')
                    .format(job.collectionDate),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Collection notes',
            children: [
              Text(
                job.notes?.trim().isNotEmpty == true
                    ? job.notes!
                    : 'No special collection instructions were provided.',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (job.logisticsProviderId == state.providerId &&
              job.status != CollectionJobStatus.open) ...[
            _Section(
              title: 'Contacts',
              children: [
                _ContactRow(
                  icon: Icons.agriculture_outlined,
                  name: job.farmerName,
                  phone: job.farmerPhone,
                  onCall: () => _openPhone(job.farmerPhone),
                  onWhatsApp: () => _openWhatsApp(job.farmerPhone),
                ),
                const Divider(height: 24),
                _ContactRow(
                  icon: Icons.storefront_outlined,
                  name: job.buyerName,
                  phone: job.buyerPhone,
                  onCall: () => _openPhone(job.buyerPhone),
                  onWhatsApp: () => _openWhatsApp(job.buyerPhone),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Navigation',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openLocation(job.pickupLocation),
                      icon: const Icon(Icons.trip_origin_rounded),
                      label: const Text('View pickup'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openLocation(job.deliveryLocation),
                      icon: const Icon(Icons.navigation_outlined),
                      label: const Text('Navigate to delivery'),
                    ),
                  ],
                ),
              ],
            ),
          ],
          if (job.completedAt != null) ...[
            const SizedBox(height: 14),
            _Section(
              title: 'Completion',
              children: [
                _DetailRow(
                  icon: Icons.task_alt_rounded,
                  label: 'Delivered',
                  value: DateFormat('d MMM yyyy • h:mm a')
                      .format(job.completedAt!),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Transaction feedback',
              children: [
                if (state.ratingFor(job.id) != null) ...[
                  Row(
                    children: [
                      for (var i = 0; i < state.ratingFor(job.id)!.stars; i++)
                        const Icon(Icons.star_rounded,
                            size: 22, color: Colors.amber),
                      for (var i = state.ratingFor(job.id)!.stars;
                          i < 5;
                          i++)
                        const Icon(Icons.star_outline_rounded,
                            size: 22, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.ratingFor(job.id)!.comment.isEmpty
                              ? 'Rated'
                              : state.ratingFor(job.id)!.comment,
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  onPressed: () => _rateDelivery(context, state, job),
                  icon: const Icon(Icons.star_outline_rounded),
                  label: Text(state.ratingFor(job.id) != null
                      ? 'Update rating'
                      : 'Rate this transaction'),
                ),
              ],
            ),
          ],
          if (job.logisticsProviderId == state.providerId &&
              job.status.isActive) ...[
            const SizedBox(height: 14),
            _Section(
              title: 'Delivery support',
              children: [
                if (state.hasReportedIssue(job.id)) ...[
                  const Row(
                    children: [
                      Icon(Icons.report_rounded, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Issue reported — Farmora support is following up.',
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  onPressed: () => _reportIssue(context, state, job),
                  icon: const Icon(Icons.report_problem_outlined),
                  label: Text(state.hasReportedIssue(job.id)
                      ? 'Report another issue'
                      : 'Report an issue'),
                ),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: _bottomAction(context, state, job),
    );
  }

  Widget? _bottomAction(
    BuildContext context,
    TransporterController state,
    CollectionJob job,
  ) {
    String? label;
    IconData icon = Icons.check_rounded;
    VoidCallback? action;
    if (job.status == CollectionJobStatus.open) {
      label = 'Accept Job';
      icon = Icons.assignment_turned_in_outlined;
      action = () => _accept(context, state, job);
    } else if (job.logisticsProviderId == state.providerId &&
        job.status == CollectionJobStatus.accepted) {
      label = 'Mark as Collected';
      icon = Icons.inventory_2_outlined;
      action = () => _updateStatus(context, state, job,
          nextStatus: CollectionJobStatus.collected);
    } else if (job.logisticsProviderId == state.providerId &&
        job.status == CollectionJobStatus.collected) {
      label = 'Start Delivery';
      icon = Icons.local_shipping_outlined;
      action = () => _updateStatus(context, state, job,
          nextStatus: CollectionJobStatus.inTransit);
    } else if (job.logisticsProviderId == state.providerId &&
        job.status == CollectionJobStatus.inTransit) {
      label = 'Confirm Delivery';
      icon = Icons.task_alt_rounded;
      action = () => _updateStatus(context, state, job,
          nextStatus: CollectionJobStatus.completed);
    }
    if (label == null) return null;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : action,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon),
              label: Text(label),
            ),
            if (job.logisticsProviderId == state.providerId &&
                (job.status == CollectionJobStatus.accepted ||
                    job.status == CollectionJobStatus.collected)) ...[
              const SizedBox(height: 6),
              if (job.status == CollectionJobStatus.collected)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _updateStatus(context, state, job,
                          nextStatus: CollectionJobStatus.completed),
                  child: const Text('Complete Delivery'),
                ),
              if (job.status == CollectionJobStatus.accepted)
                TextButton(
                  onPressed: _busy ? null : () => _cancel(context, state, job),
                  child: const Text('Cancel job'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _accept(
    BuildContext context,
    TransporterController state,
    CollectionJob job,
  ) async {
    final confirmed = await confirmTransporterAction(
      context,
      title: 'Accept this job?',
      message:
          'You will be responsible for collecting ${job.quantityLabel} of ${job.produceName} and delivering it to ${job.deliveryLocation}.',
      confirmLabel: 'Accept job',
    );
    if (!confirmed || !context.mounted) return;
    setState(() => _busy = true);
    final result = await state.acceptJob(job.id);
    if (!context.mounted) return;
    setState(() => _busy = false);
    showTransporterResult(context, result);
  }

  Future<void> _updateStatus(
    BuildContext context,
    TransporterController state,
    CollectionJob job, {
    required CollectionJobStatus nextStatus,
  }) async {
    final confirmed = await confirmTransporterAction(
      context,
      title: switch (nextStatus) {
        CollectionJobStatus.collected => 'Confirm pickup?',
        CollectionJobStatus.inTransit => 'Start delivery?',
        _ => 'Confirm delivery?',
      },
      message: switch (nextStatus) {
        CollectionJobStatus.collected =>
          'Have you collected this produce from the farmer?',
        CollectionJobStatus.inTransit =>
          'Start the delivery to ${job.deliveryLocation}?',
        _ => 'Confirm that the produce reached ${job.deliveryLocation}.',
      },
      confirmLabel: switch (nextStatus) {
        CollectionJobStatus.collected => 'Mark collected',
        CollectionJobStatus.inTransit => 'Start delivery',
        _ => 'Complete delivery',
      },
    );
    if (!confirmed || !context.mounted) return;
    setState(() => _busy = true);
    final result = switch (nextStatus) {
      CollectionJobStatus.collected => await state.markCollected(job.id),
      CollectionJobStatus.inTransit => await state.startDelivery(job.id),
      _ => await state.completeDelivery(job.id),
    };
    if (!context.mounted) return;
    setState(() => _busy = false);
    showTransporterResult(context, result);
  }

  Future<void> _cancel(BuildContext context, TransporterController state,
      CollectionJob job) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Why are you cancelling?'),
        children: [
          for (final value in [
            'Vehicle breakdown',
            'Emergency',
            'Unable to reach pickup location',
            'Other',
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, value),
              child: Text(value),
            ),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;
    final confirmed = await confirmTransporterAction(
      context,
      title: 'Cancel this job?',
      message: 'This cancellation will be recorded for ${job.produceName}.',
      confirmLabel: 'Cancel job',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    setState(() => _busy = true);
    final result = await state.cancelJob(job.id, reason);
    if (!context.mounted) return;
    setState(() => _busy = false);
    showTransporterResult(context, result);
  }

  Future<void> _reportIssue(BuildContext context, TransporterController state,
      CollectionJob job) async {
    const reasons = [
      'Vehicle Problem',
      'Farmer Unavailable',
      'Buyer Unavailable',
      'Incorrect Pickup Location',
      'Incorrect Delivery Location',
      'Produce/Quantity Issue',
      'Other',
    ];
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) {
        String selected = reasons.first;
        final description = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Report an issue'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selected,
                    items: reasons
                        .map((reason) => DropdownMenuItem(
                              value: reason,
                              child: Text(reason),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selected = value ?? reasons.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: description,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Description (optional)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, (selected, description.text)),
                child: const Text('Submit'),
              ),
            ],
          ),
        );
      },
    );
    if (result == null || !context.mounted) return;
    final actionResult = await state.reportIssue(
      jobId: job.id,
      reason: result.$1,
      description: result.$2,
    );
    if (!context.mounted) return;
    showTransporterResult(context, actionResult);
  }

  Future<void> _rateDelivery(BuildContext context, TransporterController state,
      CollectionJob job) async {
    var stars = 5;
    final comment = TextEditingController();
    final result = await showDialog<(int, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate this transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () => setState(() => stars = index + 1),
                    icon: Icon(index < stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded),
                    color: Colors.amber,
                  ),
                ),
              ),
              TextField(
                controller: comment,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, (stars, comment.text)),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    final actionResult = await state.rateDelivery(
      jobId: job.id,
      stars: result.$1,
      comment: result.$2,
    );
    if (!context.mounted) return;
    showTransporterResult(context, actionResult);
  }

  Future<void> _openPhone(String phone) async {
    if (phone.trim().isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _openWhatsApp(String phone) async {
    if (phone.trim().isEmpty) return;
    await launchUrl(
        Uri.parse('https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}'));
  }

  Future<void> _openLocation(String location) async {
    await launchUrl(Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}'));
  }

  bool _isSuitable(TransporterController state, CollectionJob job) {
    final vehicleKg = (state.vehicleCapacity ?? double.infinity) *
        (state.vehicleCapacityUnit == 'tons' ? 1000 : 1);
    final jobKg = job.unit.toLowerCase().contains('ton')
        ? job.quantity * 1000
        : job.quantity;
    return jobKg <= vehicleKg;
  }

  String _capacityText(TransporterController state, CollectionJob job) =>
      _isSuitable(state, job)
          ? 'Suitable for your vehicle'
          : 'Load may exceed your vehicle capacity';
}

class _JobHero extends StatelessWidget {
  final CollectionJob job;

  const _JobHero({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.eco_rounded, color: AppColors.primary, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.produceName,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900)),
                    Text(job.quantityLabel,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              JobStatusChip(status: job.status),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Order ${job.orderId ?? 'not linked'}  •  Produce post ${job.producePostId ?? 'not linked'}',
            style: const TextStyle(
                fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 21),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child:
                Text(label, style: const TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String phone;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const _ContactRow(
      {required this.icon,
      required this.name,
      required this.phone,
      required this.onCall,
      required this.onWhatsApp});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(icon, color: AppColors.primary),
        ),
        if (phone.isNotEmpty) ...[
          IconButton(
            tooltip: 'Call',
            onPressed: onCall,
            icon: const Icon(Icons.call_outlined),
          ),
          IconButton(
            tooltip: 'WhatsApp',
            onPressed: onWhatsApp,
            icon: const Icon(Icons.chat_outlined),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(phone.isEmpty ? 'Phone not provided' : phone,
                  style: const TextStyle(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
