import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/order.dart';
import '../../../models/transport_job.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/delivery_location_service.dart';
import '../../../services/firebase_service.dart';
import '../../../core/widgets/route_progress_map.dart';
import '../../messaging/presentation/conversations_screen.dart';

class LogisticsTrackingScreen extends StatefulWidget {
  final FarmoraOrder order;

  const LogisticsTrackingScreen({super.key, required this.order});

  @override
  State<LogisticsTrackingScreen> createState() =>
      _LogisticsTrackingScreenState();
}

class _LogisticsTrackingScreenState extends State<LogisticsTrackingScreen> {
  final Set<int> _checkedItems = {0};
  final FirestoreService _service = FirestoreService();
  StreamSubscription<List<TransportJob>>? _jobSub;
  StreamSubscription<Map<String, dynamic>?>? _transporterSub;
  TransportJob? _job;
  Map<String, dynamic>? _transporter;
  bool _handoverBusy = false;

  Future<void> _confirmHandover(FarmoraOrder order) async {
    if (_handoverBusy) return;
    final state = context.read<FarmoraState>();
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() => _handoverBusy = true);
    try {
      await state.confirmHandover(order.id);
      messenger.showSnackBar(
        SnackBar(
            content: Text(l.farmerTrackHandedConfirmed),
            backgroundColor: AppColors.primary),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(userMessage(e, action: 'confirm the handover')),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _handoverBusy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (widget.order.id.isNotEmpty && uid.isNotEmpty) {
      _jobSub = _service.jobByOrderStream(widget.order.id, uid).listen((jobs) {
        if (mounted && jobs.isNotEmpty) {
          final job = jobs.first;
          setState(() => _job = job);
          _watchTransporter(job.transporterId);
        }
      }, onError: (e) => debugPrint('Tracking job stream error: $e'));
    }
  }

  void _watchTransporter(String? transporterId) {
    _transporterSub?.cancel();
    if (transporterId == null || transporterId.isEmpty) {
      if (mounted) setState(() => _transporter = null);
      return;
    }
    _transporterSub = _service
        .transporterPublicProfileStream(transporterId)
        .listen((profile) {
      if (mounted) setState(() => _transporter = profile);
    }, onError: (e) => debugPrint('Transporter profile stream error: $e'));
  }

  @override
  void dispose() {
    _jobSub?.cancel();
    _transporterSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final l = context.l10n;
    final order = state.orders.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );
    final courierLive = _job?.hasCourierLocation ?? false;
    final courierFresh =
        DeliveryLocationService.isLocationFresh(_job?.locationUpdatedAt);
    final vehicleDetails = [
      _transporter?['vehicleType'],
      _transporter?['vehicleRegistration'],
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.farmerOrderDetailTitle,
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Order Summary Header ──
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined,
                                size: 16, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.farmerTrackOrderHash(order.displayNumber),
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface),
                                  ),
                                  Text(
                                    '${order.productName.isNotEmpty ? order.productName : order.title} (${order.quantity.isNotEmpty ? order.quantity : '—'})',
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8EFC9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle,
                              size: 8, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 6),
                          Text(
                              _job?.status == 'requested'
                                  ? l.farmerTrackPickupRequested
                                  : statusLabel(
                                      _job?.status ?? order.status, l),
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32),
                                  height: 1.15)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Fulfillment Dispatch ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.farmerTrackDeliveryStatus,
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                                color: Color(0xFFB8E986),
                                shape: BoxShape.circle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                          statusLabel(
                              _job == null ? order.status : _job!.status, l),
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.pedal_bike_rounded,
                                size: 16, color: AppColors.onSurface),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l.farmerTrackPickupNote,
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Driver Card ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.surfaceContainerLow,
                            backgroundImage:
                                (_transporter?['photoUrl'] as String?)
                                            ?.isNotEmpty ==
                                        true
                                    ? NetworkImage(
                                        _transporter!['photoUrl'] as String)
                                    : null,
                            child: (_transporter?['photoUrl'] as String?)
                                        ?.isNotEmpty ==
                                    true
                                ? null
                                : const Icon(Icons.person,
                                    color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                          _transporter?['displayName']
                                                  as String? ??
                                              l.farmerTrackTransportProvider,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.onSurface)),
                                    ),
                                    if (_transporter?['isVerified'] ==
                                        true) ...[
                                      const SizedBox(width: 5),
                                      const Icon(Icons.verified_rounded,
                                          size: 15, color: AppColors.primary),
                                    ],
                                  ],
                                ),
                                Text(
                                    _job?.transporterId == null
                                        ? l.farmerTrackAwaitingTransporter
                                        : l.farmerTrackAssignedTransporter,
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    vehicleDetails.isEmpty
                                        ? l.farmerTrackVehicleUnavailable
                                        : vehicleDetails,
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.access_time_rounded,
                                size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.farmerTrackEstimatedArrival,
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface)),
                                Text(
                                  l.farmerTrackEtaUnavailable,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBC4AB)
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                                statusLabel(_job?.status ?? order.status, l),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8A4B24),
                                    height: 1.15)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showCallDriverDialog(context, order),
                              icon: const Icon(Icons.chat_bubble_outline,
                                  size: 16),
                              label: Text(l.farmerTrackCallDriver,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.onSurface,
                                side:
                                    const BorderSide(color: Color(0xFFE0E0E0)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ConversationsScreen(orderId: order.id),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline,
                                  size: 16),
                              label: Text(l.message,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.onSurface,
                                side:
                                    const BorderSide(color: Color(0xFFE0E0E0)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (courierLive) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.swap_calls_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l.farmerTrackLiveGps(
                                    _job!.courierLat!.toStringAsFixed(4),
                                    _job!.courierLng!.toStringAsFixed(4)),
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Route Waypoints ──
                Row(
                  children: [
                    Expanded(
                      child: Text(l.farmerTrackRouteWaypoints,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        _job?.hasRouteCoordinates == true
                            ? l.farmerTrackGpsRoute
                            : l.farmerTrackRoutePreview,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Show the real route when coordinates and a Maps key
                      // are configured; otherwise show the neutral progress view.
                      Stack(
                        children: [
                          RouteProgressMap(
                            progress: RouteProgressMap.progressForJobStatus(
                              _job?.status ?? 'requested',
                            ),
                            // Null falls back to RouteProgressMap's own
                            // localized "Farm pickup" / "Delivery point".
                            pickupLabel: _job?.pickup,
                            dropoffLabel: _job?.dropoff,
                            statusLabel: _job?.status ?? order.status,
                            pickup: _job?.hasRouteCoordinates == true
                                ? LatLng(_job!.pickupLat!, _job!.pickupLng!)
                                : null,
                            dropoff: _job?.hasRouteCoordinates == true
                                ? LatLng(_job!.dropoffLat!, _job!.dropoffLng!)
                                : null,
                            courier: courierLive
                                ? LatLng(_job!.courierLat!, _job!.courierLng!)
                                : null,
                          ),
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: courierLive && courierFresh
                                    ? AppColors.primary
                                    : Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    courierLive && courierFresh
                                        ? Icons.my_location_rounded
                                        : Icons.navigation_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    courierLive
                                        ? (courierFresh
                                            ? l.farmerTrackDriverLive
                                            : l.farmerTrackDriverUpdating)
                                        : l.farmerTrackRouteProgress,
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Live driver position banner
                      if (courierLive)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: courierFresh
                                ? const Color(0xFFE8F5E9)
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: courierFresh
                                  ? AppColors.primary
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                courierFresh
                                    ? Icons.satellite_alt_rounded
                                    : Icons.location_searching_rounded,
                                size: 16,
                                color: courierFresh
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  courierFresh
                                      ? l.farmerTrackSharingLive
                                      : l.farmerTrackLastKnown,
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statusLabel(_job!.status, l).toUpperCase(),
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface),
                              ),
                            ],
                          ),
                        ),
                      // Waypoint details
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(14)),
                        ),
                        child: Column(
                          children: [
                            _buildWaypoint(
                              icon: Icons.storefront_rounded,
                              label: l.farmerTrackPickupOrigin,
                              name: state.displayName.isEmpty
                                  ? l.farmerTrackFarmPickup
                                  : state.displayName,
                              detail: _job?.pickup ?? order.detail,
                              iconBg: const Color(0xFFE8F5E9),
                              iconColor: AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            _buildWaypoint(
                              icon: Icons.location_on_rounded,
                              label: l.farmerTrackDeliveryDestination,
                              name: order.buyerCompany.isNotEmpty
                                  ? order.buyerCompany
                                  : order.buyerName.isNotEmpty
                                      ? order.buyerName
                                      : l.roleBuyer,
                              detail: order.deliveryAddress,
                              iconBg: const Color(0xFFFDE8E8),
                              iconColor: AppColors.error,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.sticky_note_2_outlined,
                                      size: 14,
                                      color: AppColors.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      order.detail.isNotEmpty
                                          ? order.detail
                                          : l.farmerTrackNoInstructions,
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: AppColors.onSurfaceVariant,
                                          height: 1.35),
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
                const SizedBox(height: 20),

                // ── Order Lifecycle ──
                Row(
                  children: [
                    Expanded(
                      child: Text(l.farmerTrackOrderLifecycle,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        statusLabel(_job?.status ?? order.status, l)
                            .toUpperCase(),
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildLifecycle(l, order.status),
                const SizedBox(height: 20),

                // ── Pickup Checklist ──
                Row(
                  children: [
                    Expanded(
                      child: Text(l.farmerTrackPickupChecklist,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                          l.farmerTrackChecklistDone(_checkedItems.length, 3),
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l.farmerTrackPrepareBefore,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 12),
                ..._buildChecklist(l),
                const SizedBox(height: 16),

                // ── Escrow Guarantee ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE0E0E0))),
                        child: const Icon(Icons.verified_user_outlined,
                            size: 16, color: AppColors.onSurface),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.paymentStatus,
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface)),
                            const SizedBox(height: 3),
                            Text(order.paymentStatusLabel,
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                    height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Actions ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((order.statusKey == 'assigned' ||
                          order.statusKey == 'pickedUp') &&
                      order.farmerHandedOverAt == null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _handoverBusy
                          ? null
                          : () => _confirmHandover(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.local_shipping_rounded, size: 18),
                      label: Text(l.farmerTrackConfirmHanded,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _showEscrowDetailsSheet(context, order),
                      icon: const Icon(Icons.account_balance_rounded, size: 16),
                      label: Text(l.farmerTrackViewPaymentStatus,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaypoint({
    required IconData icon,
    required String label,
    required String name,
    required String detail,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(name,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface)),
              Text(detail,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLifecycle(AppLocalizations l, String orderStatus) {
    final normalized = (_job?.status ?? orderStatus)
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '');
    final stage = switch (normalized) {
      'requested' || 'pending' => 0,
      'accepted' || 'confirmed' || 'assigned' => 1,
      'pickedup' => 2,
      'intransit' => 3,
      'delivered' || 'completed' => 4,
      _ => -1,
    };
    final titles = [
      l.farmerTrackStepRequested,
      l.farmerTrackStepAccepted,
      l.farmerTrackStepPickedUp,
      l.farmerTrackStepInTransit,
      l.farmerTrackStepCompleted,
    ];
    final descriptions = [
      l.farmerTrackStepRequestedDesc,
      l.farmerTrackStepAcceptedDesc,
      l.farmerTrackStepPickedUpDesc,
      l.farmerTrackStepInTransitDesc,
      l.farmerTrackStepCompletedDesc,
    ];
    final steps = List.generate(titles.length, (index) {
      final done = normalized == 'delivered' || normalized == 'completed'
          ? index <= 4
          : stage > index;
      return (
        title: titles[index],
        subtitle: descriptions[index],
        time: '',
        done: done,
        active: stage == index,
        locked: false,
      );
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final s = steps[i];
          final isLast = i == steps.length - 1;
          Color dotColor;
          Widget dot;
          if (s.done) {
            dotColor = AppColors.primary;
            dot =
                const Icon(Icons.check_rounded, size: 12, color: Colors.white);
          } else if (s.active) {
            dotColor = AppColors.primary;
            dot = Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
            );
          } else if (s.locked) {
            dotColor = const Color(0xFFD7D7D2);
            dot = const Icon(Icons.lock_rounded,
                size: 10, color: AppColors.onSurfaceVariant);
          } else {
            dotColor = const Color(0xFFE5E5E0);
            dot = const SizedBox.shrink();
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                          color: dotColor, shape: BoxShape.circle),
                      child: Center(child: dot),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: s.done
                              ? AppColors.primary
                              : const Color(0xFFE5E5E0),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(s.title,
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: (s.done || s.active)
                                          ? AppColors.onSurface
                                          : AppColors.onSurfaceVariant)),
                            ),
                            if (s.active)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD8EFC9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(l.statusActive,
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2E7D32))),
                              ),
                            if (s.time.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(s.time,
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(s.subtitle,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                                height: 1.35)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildChecklist(AppLocalizations l) {
    final providerName = _transporter?['displayName'] as String?;
    final items = [
      (title: l.farmerTrackCheckPack,),
      (title: l.farmerTrackCheckReview,),
      (
        title: providerName == null
            ? l.farmerTrackCheckHandOffAssigned
            : l.farmerTrackCheckHandOffTo(providerName),
      ),
    ];

    return List.generate(items.length, (i) {
      final item = items[i];
      final checked = _checkedItems.contains(i);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => setState(() {
            checked ? _checkedItems.remove(i) : _checkedItems.add(i);
          }),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: checked ? AppColors.primary : const Color(0xFFE5E7EB),
                width: checked ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: checked ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color:
                          checked ? AppColors.primary : const Color(0xFFCCCCCC),
                      width: 1.5,
                    ),
                  ),
                  child: checked
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: checked
                          ? AppColors.onSurfaceVariant
                          : AppColors.onSurface,
                      decoration: checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Contact is routed through the order-scoped, E2E-encrypted chat — the
  /// platform deliberately never exposes driver phone numbers or fabricated
  /// contact cards.
  void _showCallDriverDialog(BuildContext context, FarmoraOrder order) {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l.farmerTrackContactPartner,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.farmerTrackContactBody,
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              l.farmerTrackContactNote,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.commonClose),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConversationsScreen(orderId: order.id),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: Text(l.openOrderChat),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showEscrowDetailsSheet(BuildContext context, FarmoraOrder order) {
    final l = context.l10n;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security_rounded,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.farmerTrackPaymentDetails,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(l.farmerTrackOrderTotal,
                            style: const TextStyle(
                                color: AppColors.onSurfaceVariant)),
                      ),
                      Text(order.displayTotal,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(l.farmerTrackPaymentStatusColon,
                            style: const TextStyle(
                                color: AppColors.onSurfaceVariant)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.paymentStatusLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.farmerTrackSettlementInfo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              l.farmerTrackSettlementBody,
              style: const TextStyle(
                  fontSize: 13, height: 1.4, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(l.understood),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
