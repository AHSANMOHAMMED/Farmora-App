import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/farmora_strings.dart';
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
    final strings = FarmoraStrings.of(context);
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
          strings.t('orderDetail'),
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
                                    'Order #${order.orderNumber}',
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
                                  ? 'Pickup requested'
                                  : (_job?.status ?? order.status),
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
                          const Expanded(
                            child: Text(
                              'DELIVERY STATUS',
                              style: TextStyle(
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
                      Text(_job == null ? order.status : _job!.status,
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
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.pedal_bike_rounded,
                                size: 16, color: AppColors.onSurface),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '3PL Automated Pickup: Driver collects directly from your farm gate loading dock.',
                                style: TextStyle(
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
                                              'Transport provider',
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
                                        ? 'Awaiting transporter acceptance'
                                        : 'Assigned transporter',
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    vehicleDetails.isEmpty
                                        ? 'Vehicle details unavailable'
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
                                Text(strings.t('estimatedArrival'),
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface)),
                                const Text(
                                  'ETA unavailable',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBC4AB)
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_job?.status ?? order.status,
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
                              label: Text(strings.t('callDriver'),
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
                              label: Text(strings.t('message'),
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
                                'Live driver GPS: ${_job!.courierLat!.toStringAsFixed(4)}, ${_job!.courierLng!.toStringAsFixed(4)}',
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
                      child: Text(strings.t('routeWaypoints'),
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface)),
                    ),
                    Text(
                        _job?.hasRouteCoordinates == true
                            ? 'GPS route'
                            : 'Route preview',
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
                            pickupLabel: _job?.pickup ?? 'Farm pickup',
                            dropoffLabel: _job?.dropoff ?? 'Delivery point',
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
                                            ? 'Driver location LIVE'
                                            : 'Driver location updating…')
                                        : 'Route progress',
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
                                      ? 'Driver is sharing live GPS — watch the map marker move.'
                                      : 'Showing last known driver position.',
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant),
                                ),
                              ),
                              Text(
                                _job!.status.toUpperCase(),
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
                              label: strings.t('pickupOrigin'),
                              name: state.displayName.isEmpty
                                  ? 'Farm pickup'
                                  : state.displayName,
                              detail: _job?.pickup ?? order.detail,
                              iconBg: const Color(0xFFE8F5E9),
                              iconColor: AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            _buildWaypoint(
                              icon: Icons.location_on_rounded,
                              label: strings.t('deliveryDestination'),
                              name: order.buyerCompany.isNotEmpty
                                  ? order.buyerCompany
                                  : order.buyerName.isNotEmpty
                                      ? order.buyerName
                                      : 'Buyer',
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
                                          : 'No delivery instructions provided.',
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
                      child: Text(strings.t('orderLifecycle'),
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface)),
                    ),
                    Text((_job?.status ?? order.status).toUpperCase(),
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildLifecycle(order.status),
                const SizedBox(height: 20),

                // ── Pickup Checklist ──
                Row(
                  children: [
                    Expanded(
                      child: Text(strings.t('pickupChecklist'),
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
                          '${_checkedItems.length}/3 ${strings.t('done')}',
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Prepare prior to driver arrival',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 12),
                ..._buildChecklist(),
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
                            const Text('Payment status',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface)),
                            const SizedBox(height: 3),
                            Text(order.paymentStatus.replaceAll('_', ' '),
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
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        state.completeOrder(order.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Produce handed to driver confirmed!'),
                              backgroundColor: AppColors.primary),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.local_shipping_rounded, size: 18),
                      label: Text(strings.t('confirmHanded'),
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _showEscrowDetailsSheet(context, order),
                      icon: const Icon(Icons.account_balance_rounded, size: 16),
                      label: const Text('View Escrow Release Status',
                          style: TextStyle(
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

  Widget _buildLifecycle(String orderStatus) {
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
    const titles = [
      'Transport requested',
      'Transport accepted',
      'Produce picked up',
      'Delivery in transit',
      'Delivery completed',
    ];
    const descriptions = [
      'A transport provider can accept this delivery.',
      'The provider has accepted the delivery request.',
      'The provider has recorded pickup.',
      'The provider has started the delivery route.',
      'The provider has marked the order delivered.',
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
                                child: const Text('Active',
                                    style: TextStyle(
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

  List<Widget> _buildChecklist() {
    final providerName = _transporter?['displayName'] as String?;
    final items = [
      (title: 'Pack the produce for pickup',),
      (title: 'Review the order and delivery instructions',),
      (
        title: providerName == null
            ? 'Hand off produce to the assigned transport provider'
            : 'Hand off produce to $providerName',
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Contact Delivery Partner',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your delivery partner and buyer are reachable through the order chat. '
              'Messages are encrypted for the recipient and phone numbers stay private.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'You will see the assigned driver details (name, vehicle, '
              'ratings) inside the conversation once a transporter accepts '
              'this delivery.',
              style: TextStyle(
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
            child: const Text('Close'),
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
            label: const Text('Open Order Chat'),
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
            const Row(
              children: [
                Icon(Icons.security_rounded,
                    color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text(
                  'Escrow Payment Protection',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
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
                      const Text('Order total:',
                          style: TextStyle(color: AppColors.onSurfaceVariant)),
                      Text(order.totalAmount,
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
                      const Text('Payment status:',
                          style: TextStyle(color: AppColors.onSurfaceVariant)),
                      Text(
                        order.paymentStatus.replaceAll('_', ' '),
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
            const Text(
              'Settlement information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'This screen shows the payment state recorded for this order. '
              'Settlement timing and dispute outcomes depend on the configured '
              'payment provider and platform policy.',
              style: TextStyle(
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
                child: const Text('Understood'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
