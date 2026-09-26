import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../messaging/presentation/chat_screen.dart';
import '../application/transporter_controller.dart';
import '../domain/collection_job.dart';
import 'active_delivery_screen.dart';
import 'widgets/job_status_chip.dart';
import 'widgets/job_timeline.dart';
import 'widgets/live_location.dart';
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
    final l10n = context.l10n;
    final job = state.jobById(widget.jobId);
    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.jobDetails)),
        body: TransporterEmptyState(
          icon: Icons.error_outline_rounded,
          title: l10n.jobUnavailableTitle,
          message: l10n.jobUnavailableMessage,
          actionLabel: l10n.jobGoBack,
          onAction: () => Navigator.maybePop(context),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.jobNumberTitle(job.id))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _JobHero(job: job),
          const SizedBox(height: 14),
          _Section(
            title: l10n.jobTimelineTitle,
            children: [JobTimeline(job: job)],
          ),
          if (job.logisticsProviderId == state.providerId &&
              state.vehicleCapacity != null) ...[
            const SizedBox(height: 14),
            _Section(
              title: l10n.jobVehicleSuitability,
              children: [
                Text(
                  _capacityText(l10n, state, job),
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
            title: l10n.jobCollectionRoute,
            children: [
              _DetailRow(
                icon: Icons.trip_origin_rounded,
                label: l10n.jobPickupLabel,
                value: job.pickupLocation,
              ),
              _DetailRow(
                icon: Icons.location_on_rounded,
                label: l10n.jobDeliveryLabel,
                value: job.deliveryLocation,
              ),
              _DetailRow(
                icon: Icons.calendar_month_outlined,
                label: l10n.jobCollectionLabel,
                value: AppFormat.dateTime(job.collectionDate),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: l10n.jobCollectionNotes,
            children: [
              Text(
                job.notes?.trim().isNotEmpty == true
                    ? job.notes!
                    : l10n.jobNoNotes,
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
              title: l10n.jobContacts,
              children: [
                _ContactRow(
                  icon: Icons.agriculture_outlined,
                  role: l10n.roleFarmer,
                  name: job.farmerName,
                  phone: job.farmerPhone,
                  onCall: () => _openPhone(job.farmerPhone),
                  onWhatsApp: () => _openWhatsApp(job.farmerPhone),
                  onChat: _canChat(job, farmer: true)
                      ? () => _openChat(context, state, job, farmer: true)
                      : null,
                ),
                const Divider(height: 24),
                _ContactRow(
                  icon: Icons.storefront_outlined,
                  role: l10n.roleBuyer,
                  name: job.buyerName,
                  phone: job.buyerPhone,
                  onCall: () => _openPhone(job.buyerPhone),
                  onWhatsApp: () => _openWhatsApp(job.buyerPhone),
                  onChat: _canChat(job, farmer: false)
                      ? () => _openChat(context, state, job, farmer: false)
                      : null,
                ),
              ],
            ),
            if (job.status.isActive) ...[
              const SizedBox(height: 14),
              _Section(
                title: l10n.jobActiveDeliveryTitle,
                children: [
                  Text(
                    l10n.jobSharingOffHelp,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ActiveDeliveryScreen(job: transportJobFrom(job)),
                      ),
                    ),
                    icon: const Icon(Icons.my_location_rounded),
                    label: Text(
                      l10n.jobShareLiveLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            _Section(
              title: l10n.jobNavigation,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openLocation(job.pickupLocation),
                      icon: const Icon(Icons.trip_origin_rounded),
                      label: Text(l10n.jobViewPickup),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openLocation(job.deliveryLocation),
                      icon: const Icon(Icons.navigation_outlined),
                      label: Text(l10n.navigateToDelivery),
                    ),
                  ],
                ),
              ],
            ),
          ],
          if (job.completedAt != null) ...[
            const SizedBox(height: 14),
            _Section(
              title: l10n.jobCompletion,
              children: [
                _DetailRow(
                  icon: Icons.task_alt_rounded,
                  label: l10n.statusDelivered,
                  value: AppFormat.dateTime(job.completedAt!),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: l10n.jobTransactionFeedback,
              children: [
                if (state.ratingFor(job.id) != null) ...[
                  Row(
                    children: [
                      for (var i = 0; i < state.ratingFor(job.id)!.stars; i++)
                        const Icon(Icons.star_rounded,
                            size: 22, color: Colors.amber),
                      for (var i = state.ratingFor(job.id)!.stars; i < 5; i++)
                        const Icon(Icons.star_outline_rounded,
                            size: 22, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.ratingFor(job.id)!.comment.isEmpty
                              ? l10n.jobRated
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
                      ? l10n.jobUpdateRating
                      : l10n.jobRateTransaction),
                ),
              ],
            ),
          ],
          if (job.logisticsProviderId == state.providerId &&
              job.status.isActive) ...[
            const SizedBox(height: 14),
            _Section(
              title: l10n.jobDeliverySupport,
              children: [
                if (state.hasReportedIssue(job.id)) ...[
                  Row(
                    children: [
                      const Icon(Icons.report_rounded,
                          size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.jobIssueReportedNote,
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant),
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
                      ? l10n.jobReportAnotherIssue
                      : l10n.jobReportIssue),
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
    final l10n = context.l10n;
    String? label;
    IconData icon = Icons.check_rounded;
    VoidCallback? action;
    if (job.status == CollectionJobStatus.open) {
      label = l10n.jobAcceptJobButton;
      icon = Icons.assignment_turned_in_outlined;
      action = () => _accept(context, state, job);
    } else if (job.logisticsProviderId == state.providerId &&
        job.status == CollectionJobStatus.accepted) {
      label = l10n.jobMarkAsCollected;
      icon = Icons.inventory_2_outlined;
      action = () => _updateStatus(context, state, job,
          nextStatus: CollectionJobStatus.collected);
    } else if (job.logisticsProviderId == state.providerId &&
        job.status == CollectionJobStatus.collected) {
      label = l10n.jobStartDeliveryButton;
      icon = Icons.local_shipping_outlined;
      action = () => _updateStatus(context, state, job,
          nextStatus: CollectionJobStatus.inTransit);
    } else if (job.logisticsProviderId == state.providerId &&
        job.status == CollectionJobStatus.inTransit) {
      label = l10n.jobConfirmDeliveryButton;
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
              label: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (job.status == CollectionJobStatus.open &&
                state.canDecline(job)) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: _busy ? null : () => _decline(context, state, job),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Decline request'),
              ),
            ],
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
                  child: Text(l10n.jobCompleteDeliveryButton),
                ),
              if (job.status == CollectionJobStatus.accepted)
                TextButton(
                  onPressed: _busy ? null : () => _cancel(context, state, job),
                  child: Text(l10n.jobCancelJobButton),
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
      title: context.l10n.jobAcceptConfirmTitle,
      message: context.l10n.jobAcceptConfirmMessage(
        job.quantityLabel,
        job.produceName,
        job.deliveryLocation,
      ),
      confirmLabel: context.l10n.jobAcceptConfirmAction,
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
    final l10n = context.l10n;
    final confirmed = await confirmTransporterAction(
      context,
      title: switch (nextStatus) {
        CollectionJobStatus.collected => l10n.jobConfirmPickupTitle,
        CollectionJobStatus.inTransit => l10n.jobStartDeliveryTitle,
        _ => l10n.jobConfirmDeliveryTitle,
      },
      message: switch (nextStatus) {
        CollectionJobStatus.collected => l10n.jobConfirmPickupMessage,
        CollectionJobStatus.inTransit =>
          l10n.jobStartDeliveryMessage(job.deliveryLocation),
        _ => l10n.jobConfirmDeliveryMessage(job.deliveryLocation),
      },
      confirmLabel: switch (nextStatus) {
        CollectionJobStatus.collected => l10n.jobMarkCollectedAction,
        CollectionJobStatus.inTransit => l10n.jobStartDeliveryAction,
        _ => l10n.jobCompleteDeliveryAction,
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
    if (result.success) await syncLiveSharing(context, job.id, nextStatus);
  }

  Future<void> _decline(
    BuildContext context,
    TransporterController state,
    CollectionJob job,
  ) async {
    final confirmed = await confirmTransporterAction(
      context,
      title: 'Decline this request?',
      message: 'The farmer will be notified so the delivery can be offered '
          'to another transporter.',
      confirmLabel: 'Decline',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    setState(() => _busy = true);
    final result = await state.declineJob(job.id);
    if (!context.mounted) return;
    setState(() => _busy = false);
    showTransporterResult(context, result);
    if (result.success) Navigator.of(context).maybePop();
  }

  bool _canChat(CollectionJob job, {required bool farmer}) =>
      (job.orderId ?? '').isNotEmpty &&
      (farmer ? job.farmerId : job.buyerId).isNotEmpty;

  Future<void> _openChat(
    BuildContext context,
    TransporterController state,
    CollectionJob job, {
    required bool farmer,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final conversation = farmer
          ? await state.chatWithFarmer(job.id)
          : await state.chatWithBuyer(job.id);
      if (!context.mounted) return;
      setState(() => _busy = false);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: conversation),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      setState(() => _busy = false);
      _showError(context, userMessage(error, action: 'open the chat'));
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
  }

  Future<void> _cancel(BuildContext context, TransporterController state,
      CollectionJob job) async {
    final l10n = context.l10n;
    // Stored reason values stay English; only the labels are translated.
    final reasons = [
      ('Vehicle breakdown', l10n.jobCancelReasonBreakdown),
      ('Emergency', l10n.jobCancelReasonEmergency),
      ('Unable to reach pickup location', l10n.jobCancelReasonUnreachable),
      ('Other', l10n.jobReasonOther),
    ];
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.jobCancelReasonTitle),
        children: [
          for (final (value, label) in reasons)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, value),
              child: Text(label),
            ),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;
    final confirmed = await confirmTransporterAction(
      context,
      title: l10n.jobCancelConfirmTitle,
      message: l10n.jobCancelConfirmMessage(job.produceName),
      confirmLabel: l10n.jobCancelJobButton,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    setState(() => _busy = true);
    final result = await state.cancelJob(job.id, reason);
    if (!context.mounted) return;
    setState(() => _busy = false);
    showTransporterResult(context, result);
    if (result.success) {
      await syncLiveSharing(context, job.id, CollectionJobStatus.cancelled);
    }
  }

  Future<void> _reportIssue(BuildContext context, TransporterController state,
      CollectionJob job) async {
    final l10n = context.l10n;
    // Stored reason values stay English; only the labels are translated.
    const reasons = [
      'Vehicle Problem',
      'Farmer Unavailable',
      'Buyer Unavailable',
      'Incorrect Pickup Location',
      'Incorrect Delivery Location',
      'Produce/Quantity Issue',
      'Other',
    ];
    final reasonLabels = {
      'Vehicle Problem': l10n.jobIssueVehicleProblem,
      'Farmer Unavailable': l10n.jobIssueFarmerUnavailable,
      'Buyer Unavailable': l10n.jobIssueBuyerUnavailable,
      'Incorrect Pickup Location': l10n.jobIssueWrongPickup,
      'Incorrect Delivery Location': l10n.jobIssueWrongDelivery,
      'Produce/Quantity Issue': l10n.jobIssueProduceQuantity,
      'Other': l10n.jobReasonOther,
    };
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) {
        String selected = reasons.first;
        final description = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(l10n.jobReportIssue),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selected,
                    isExpanded: true,
                    items: reasons
                        .map((reason) => DropdownMenuItem(
                              value: reason,
                              child: Text(
                                reasonLabels[reason] ?? reason,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selected = value ?? reasons.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: description,
                    maxLines: 3,
                    decoration:
                        InputDecoration(labelText: l10n.jobDescriptionOptional),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, (selected, description.text)),
                child: Text(l10n.commonSubmit),
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
    final l10n = context.l10n;
    var stars = 5;
    final comment = TextEditingController();
    final result = await showDialog<(int, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.jobRateTransaction),
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
                decoration: InputDecoration(
                  labelText: l10n.jobCommentOptional,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, (stars, comment.text)),
              child: Text(l10n.commonSubmit),
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
    await _launch(Uri(scheme: 'tel', path: phone.trim()));
  }

  Future<void> _openWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    await _launch(Uri.parse('https://wa.me/$digits'));
  }

  Future<void> _openLocation(String location) async {
    await _launch(Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}'));
  }

  Future<void> _launch(Uri uri) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      _showError(context, 'Could not open this link on your device.');
    }
  }

  bool _isSuitable(TransporterController state, CollectionJob job) {
    final vehicleKg = (state.vehicleCapacity ?? double.infinity) *
        (state.vehicleCapacityUnit == 'tons' ? 1000 : 1);
    final jobKg = job.unit.toLowerCase().contains('ton')
        ? job.quantity * 1000
        : job.quantity;
    return jobKg <= vehicleKg;
  }

  String _capacityText(
    AppLocalizations l10n,
    TransporterController state,
    CollectionJob job,
  ) =>
      _isSuitable(state, job)
          ? l10n.jobSuitableForVehicle
          : l10n.jobMayExceedCapacity;
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
          if (job.deliveryFeeMinor != null) ...[
            const SizedBox(height: 10),
            Text(
              context.l10n.jobDeliveryFeeLine(
                AppFormat.lkr(job.deliveryFeeMinor! / 100),
              ),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            context.l10n.jobOrderAndPostRefs(
              job.orderId ?? context.l10n.jobNotLinked,
              job.producePostId ?? context.l10n.jobNotLinked,
            ),
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
          Flexible(
            flex: 2,
            child: Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
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
  final String role;
  final String name;
  final String phone;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback? onChat;

  const _ContactRow({
    required this.icon,
    required this.role,
    required this.name,
    required this.phone,
    required this.onCall,
    required this.onWhatsApp,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (hasPhone)
                    Text(phone,
                        style: const TextStyle(
                            color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        if (onChat != null || hasPhone) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (onChat != null)
                OutlinedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 18),
                  label: Text(
                    '${context.l10n.chat} · $role',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (hasPhone) ...[
                IconButton(
                  tooltip: context.l10n.call,
                  onPressed: onCall,
                  icon: const Icon(Icons.call_outlined),
                ),
                IconButton(
                  tooltip: 'WhatsApp',
                  onPressed: onWhatsApp,
                  icon: const Icon(Icons.chat_outlined),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
