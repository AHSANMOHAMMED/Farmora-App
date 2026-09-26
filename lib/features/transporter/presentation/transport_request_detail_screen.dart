import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../services/delivery_location_service.dart';
import '../../../providers/farmora_state.dart';
import '../../../models/transport_job.dart';
import '../../messaging/presentation/conversations_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';

class TransportRequestDetailScreen extends StatelessWidget {
  final TransportJob job;

  const TransportRequestDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final l10n = context.l10n;
    final linkedOrder = job.orderId == null
        ? null
        : state.orders.where((o) => o.id == job.orderId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.transporterRequestDetailsTitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          if (job.orderId != null && job.orderId!.isNotEmpty)
            IconButton(
              tooltip: l10n.transporterMessage,
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ConversationsScreen(orderId: job.orderId),
                ),
              ),
            ),
          IconButton(
            tooltip: l10n.notifications,
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          job.title.isNotEmpty
                              ? job.title
                              : l10n.jobTransportJobFallback,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      if (job.fee.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            job.fee,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.route, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          job.route.isNotEmpty
                              ? job.route
                              : l10n.jobRouteLine(
                                  job.pickup ?? l10n.jobPickupLabel,
                                  job.dropoff ?? l10n.jobDropoffLabel,
                                ),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (job.detail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      job.detail,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (job.district != null && job.district!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.transporterDistrictLine(job.district!),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if ((job.weightKg ?? job.capacityKg) != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.transporterLoadLine(
                          '${job.weightKg ?? job.capacityKg}'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.jobDetails,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (job.orderId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.transporterLinkedOrderId,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            job.orderId!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.transporterStatusLine(statusLabel(job.status)),
                          style: const TextStyle(
                              fontFamily: 'Inter', fontWeight: FontWeight.bold),
                        ),
                        if (linkedOrder != null)
                          Text(
                            linkedOrder.deliveryAddress.isNotEmpty
                                ? linkedOrder.deliveryAddress
                                : (job.dropoff ?? job.detail),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.onSurfaceVariant,
                            ),
                          )
                        else if (job.pickup != null || job.dropoff != null)
                          Text(
                            l10n.transporterPickupDropoffLine(
                                job.pickup ?? '—', job.dropoff ?? '—'),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.transporterContactPrivate,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: _buildActionButtons(context),
        ),
      ),
    );
  }

  /// Awaits [call]; pops only after success, otherwise shows the error.
  Future<bool> _run(
    BuildContext context,
    Future<void> Function() call, {
    required String action,
  }) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await call();
      navigator.pop();
      return true;
    } catch (error) {
      messenger.showSnackBar(SnackBar(
        content: Text(userMessage(error, action: action)),
        backgroundColor: AppColors.error,
      ));
      return false;
    }
  }

  Future<void> _setStatus(BuildContext context, String status) async {
    final state = context.read<FarmoraState>();
    final ok = await _run(
      context,
      () => state.updateJobStatus(job.id, status),
      action: 'update the delivery',
    );
    if (!ok) return;
    final location = DeliveryLocationService.instance;
    if (status == 'pickedUp' || status == 'inTransit') {
      try {
        await location.requestConsentAndStart(jobId: job.id);
      } catch (_) {
        // Sharing can be started later from Active delivery.
      }
    } else {
      location.onJobStatusChanged(job.id, status);
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    final l10n = context.l10n;
    if (!job.accepted && job.status == 'requested') {
      return FilledButton(
        onPressed: () => _run(
          context,
          () => context.read<FarmoraState>().acceptJob(job.id),
          action: 'accept the job',
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: AppColors.primary,
        ),
        child: Text(
          l10n.transporterAcceptRequest,
          style: const TextStyle(
              fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (job.status == 'accepted') {
      return FilledButton(
        onPressed: () => _setStatus(context, 'pickedUp'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(l10n.transporterMarkPickedUp),
      );
    }

    if (job.status == 'pickedUp') {
      return FilledButton(
        onPressed: () => _setStatus(context, 'inTransit'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(l10n.transporterMarkInTransit),
      );
    }

    if (job.status == 'inTransit') {
      return FilledButton(
        onPressed: () => _setStatus(context, 'delivered'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(l10n.transporterMarkDelivered),
      );
    }

    return FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(statusLabel(job.status).toUpperCase()),
    );
  }
}
