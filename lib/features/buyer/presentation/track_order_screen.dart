import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/route_progress_map.dart';
import '../../../models/order.dart';
import '../../../models/transport_job.dart';
import '../../../services/delivery_location_service.dart';
import '../../../services/firebase_service.dart';
import '../../messaging/presentation/conversations_screen.dart';
import 'buyer_l10n.dart';

class TrackOrderScreen extends StatefulWidget {
  final FarmoraOrder order;

  const TrackOrderScreen({super.key, required this.order});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final FirestoreService _service = FirestoreService();
  StreamSubscription<List<TransportJob>>? _jobSub;
  TransportJob? _job;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (widget.order.id.isNotEmpty && uid.isNotEmpty) {
      _jobSub = _service.jobByOrderAsBuyerStream(widget.order.id, uid).listen((jobs) {
        if (mounted) setState(() => _job = jobs.isEmpty ? null : jobs.first);
      }, onError: (e) => debugPrint('Job tracking stream error: $e'));
    }
  }

  @override
  void dispose() {
    _jobSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final courier = (_job?.hasCourierLocation ?? false)
        ? LatLng(_job!.courierLat!, _job!.courierLng!)
        : null;
    final fresh = DeliveryLocationService.isLocationFresh(_job?.locationUpdatedAt);
    final deliveryStatus = _job?.status ?? order.deliveryStatus;
    final l = context.l10n;

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
          l.trackOrder,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
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
                          l.buyerOrderNumber(order.orderNumber.toUpperCase()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.tertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusPendingBg,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          statusLabel(order.status, l),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.statusPendingText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.productName.isNotEmpty
                        ? order.productName
                        : order.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.buyerTotalValue(buyerOrderTotal(order)),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Live courier tracking ──
            if (courier != null) ...[
              _LiveCourierCard(
                courier: courier,
                fresh: fresh,
                jobStatus: deliveryStatus,
                updatedAt: _job?.locationUpdatedAt,
              ),
              const SizedBox(height: 16),
            ],

            RouteProgressMap(
              progress: RouteProgressMap.progressForOrderStatus(order.status),
              pickupLabel: order.productName.isNotEmpty
                  ? order.productName
                  : l.buyerFarmPickup,
              dropoffLabel: order.deliveryAddress.split('\n').first,
              statusLabel:
                  '${statusLabel(order.status, l)} • ${deliveryStatus.isNotEmpty ? statusLabel(deliveryStatus, l) : l.buyerInNetwork}',
              pickup: _job?.pickupLat != null && _job?.pickupLng != null
                  ? LatLng(_job!.pickupLat!, _job!.pickupLng!)
                  : null,
              dropoff: _job?.dropoffLat != null && _job?.dropoffLng != null
                  ? LatLng(_job!.dropoffLat!, _job!.dropoffLng!)
                  : null,
              courier: courier,
            ),
            const SizedBox(height: 24),
            Text(
              l.buyerDeliveryStatus,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ...(() {
                    final s = order.status
                        .toLowerCase()
                        .replaceAll(' ', '')
                        .replaceAll('_', '');
                    final steps = <(String, String, bool)>[
                      (
                        l.buyerStepOrderPlaced,
                        order.deliveryAddress.isNotEmpty
                            ? order.deliveryAddress
                            : l.buyerAwaitingFarmerConfirmation,
                        true
                      ),
                      (
                        l.statusConfirmed,
                        l.buyerStepFarmerAccepted,
                        {
                          'confirmed',
                          'assigned',
                          'pickedup',
                          'intransit',
                          'delivered',
                          'completed',
                          'accepted'
                        }.contains(s)
                      ),
                      (
                        l.statusInTransit,
                        l.buyerStepOnTheWay,
                        {'intransit', 'delivered', 'completed'}.contains(s)
                      ),
                      (
                        l.statusDelivered,
                        l.buyerStepBuyerReceived,
                        {'delivered', 'completed'}.contains(s)
                      ),
                    ];
                    return [
                      for (var i = 0; i < steps.length; i++)
                        _buildTimelineStep(
                          steps[i].$1,
                          steps[i].$2,
                          steps[i].$3,
                          steps[i].$3,
                          isLast: i == steps.length - 1,
                        ),
                    ];
                  })(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => ConversationsScreen(orderId: order.id)),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: Text(l.messageFarmerTransporter),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(String title, String subtitle, bool isActive,
      bool isCompleted, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color:
                    isActive ? AppColors.primary : AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : isActive
                      ? Center(
                          child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle)))
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted
                    ? AppColors.primary
                    : AppColors.surfaceContainerHigh,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

/// Live status banner shown while the transporter broadcasts their position.
class _LiveCourierCard extends StatelessWidget {
  final LatLng courier;
  final bool fresh;
  final String jobStatus;
  final DateTime? updatedAt;

  const _LiveCourierCard({
    required this.courier,
    required this.fresh,
    required this.jobStatus,
    this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status =
        jobStatus.isEmpty ? l.buyerInProgress : statusLabel(jobStatus, l);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fresh ? const Color(0xFFE8F5E9) : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: fresh ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            fresh ? Icons.my_location_rounded : Icons.location_searching_rounded,
            color: fresh ? AppColors.primary : AppColors.onSurfaceVariant,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fresh ? l.buyerCourierLive : l.buyerCourierLastKnown,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  updatedAt != null
                      ? l.buyerCourierUpdated(
                          AppFormat.relative(updatedAt!), status)
                      : l.buyerCourierDelivery(status),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
