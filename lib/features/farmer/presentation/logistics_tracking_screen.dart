import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/farmora_strings.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';

class LogisticsTrackingScreen extends StatefulWidget {
  final FarmoraOrder order;

  const LogisticsTrackingScreen({super.key, required this.order});

  @override
  State<LogisticsTrackingScreen> createState() =>
      _LogisticsTrackingScreenState();
}

class _LogisticsTrackingScreenState extends State<LogisticsTrackingScreen> {
  final Set<int> _checkedItems = {0};

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final strings = FarmoraStrings.of(context);
    final order = state.orders.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );

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
              child:
                  const Icon(Icons.person, color: Colors.white, size: 20),
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
                          border:
                              Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined,
                                size: 16, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                    '${order.productName.isNotEmpty ? order.productName : order.title} (${order.quantity.isNotEmpty ? order.quantity : '28 kg'})',
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
                          Text(strings.t('pickupToday'),
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
                              'FULFILLMENT DISPATCH',
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
                      Text(strings.t('driverEnRoute'),
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
                          ClipOval(
                            child: Image.asset(
                              'assets/images/driver_john.png',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: AppColors.surfaceContainerLow,
                                child: const Icon(Icons.person,
                                    color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('John Davis',
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onSurface)),
                                    SizedBox(width: 6),
                                    Icon(Icons.star_rounded,
                                        size: 14, color: Color(0xFFF9A825)),
                                    Text('4.9',
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onSurface)),
                                  ],
                                ),
                                Text('GreenRoute Logistics',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w600)),
                                Text('White Ford Transit (Lic: 7XF-902)',
                                    style: TextStyle(
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(strings.t('estimatedArrival'),
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface)),
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
                            child: const Text('On\nSchedule',
                                style: TextStyle(
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
                              onPressed: () {},
                              icon: const Icon(Icons.phone_outlined,
                                  size: 16),
                              label: Text(strings.t('callDriver'),
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.onSurface,
                                side: const BorderSide(
                                    color: Color(0xFFE0E0E0)),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.chat_bubble_outline,
                                  size: 16),
                              label: Text(strings.t('message'),
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.onSurface,
                                side: const BorderSide(
                                    color: Color(0xFFE0E0E0)),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                    const Text('29.6 km total',
                        style: TextStyle(
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
                      // Map area (static placeholder)
                      Stack(
                        children: [
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD6E4F0),
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(14)),
                            ),
                            child: CustomPaint(
                              painter: _RoutePainter(),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.navigation_rounded,
                                      size: 12, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text('Live telemetry active',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                              name: 'Sunny Valley Farm',
                              detail: 'Gate B, Loading Dock · Kurunegala',
                              iconBg: const Color(0xFFE8F5E9),
                              iconColor: AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            _buildWaypoint(
                              icon: Icons.location_on_rounded,
                              label: strings.t('deliveryDestination'),
                              name: order.buyerCompany,
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
                              child: const Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.sticky_note_2_outlined,
                                      size: 14,
                                      color: AppColors.onSurfaceVariant),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Buyer Special Note:',
                                            style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    AppColors.onSurface)),
                                        SizedBox(height: 2),
                                        Text(
                                            '"Deliver to back alley loading dock. Call shop manager upon arrival."',
                                            style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11,
                                                fontStyle:
                                                    FontStyle.italic,
                                                color: AppColors
                                                    .onSurfaceVariant,
                                                height: 1.35)),
                                      ],
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
                    const Text('Stage 3 of 6',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildLifecycle(),
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
                      child: Text('${_checkedItems.length}/3 ${strings.t('done')}',
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
                            border: Border.all(
                                color: const Color(0xFFE0E0E0))),
                        child: const Icon(Icons.verified_user_outlined,
                            size: 16, color: AppColors.onSurface),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(strings.t('escrowProtected'),
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface)),
                            const SizedBox(height: 3),
                            const Text(
                                "The buyer's deposit is securely held. Payout clears automatically upon delivery confirmation.",
                                style: TextStyle(
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
                      icon: const Icon(Icons.local_shipping_rounded,
                          size: 18),
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
                      onPressed: () {},
                      icon: const Icon(Icons.account_balance_rounded,
                          size: 16),
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
          decoration:
              BoxDecoration(color: iconBg, shape: BoxShape.circle),
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

  Widget _buildLifecycle() {
    final steps = [
      (
        title: 'Order Received',
        subtitle: 'Payment escrow secured (LKR 38,500)',
        time: '07:30 AM',
        done: true,
        active: false,
        locked: false,
      ),
      (
        title: 'Order Accepted',
        subtitle: 'Accepted by Sunny Valley Farm',
        time: '07:45 AM',
        done: true,
        active: false,
        locked: false,
      ),
      (
        title: 'Logistics Assigned',
        subtitle: 'GreenRoute Logistics · Driver John D.',
        time: '',
        done: false,
        active: true,
        locked: false,
      ),
      (
        title: 'Items Picked Up from Farm',
        subtitle: 'Driver arrives at collection Gate B',
        time: '',
        done: false,
        active: false,
        locked: false,
      ),
      (
        title: 'Out for Delivery',
        subtitle: 'En route to Fresh Market Co. dock',
        time: '',
        done: false,
        active: false,
        locked: false,
      ),
      (
        title: 'Delivered & Payout Released',
        subtitle: 'LKR 38,500 credited to Farmora Wallet',
        time: '',
        done: false,
        active: false,
        locked: true,
      ),
    ];

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
            dot = const Icon(Icons.check_rounded,
                size: 12, color: Colors.white);
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
                                  borderRadius:
                                      BorderRadius.circular(10),
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
    final items = [
      (
        title: 'Harvest packed into 2×14kg crates',
        hasPrint: false,
        trailingIcon: Icons.check_circle_outline_rounded,
      ),
      (
        title: 'Attach Farmora Waybill #WB-8492',
        hasPrint: true,
        trailingIcon: Icons.receipt_long_outlined,
      ),
      (
        title: 'Hand off produce to driver John D.',
        hasPrint: false,
        trailingIcon: Icons.inventory_2_outlined,
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
                      color: checked
                          ? AppColors.primary
                          : const Color(0xFFCCCCCC),
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
                      decoration:
                          checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (item.hasPrint)
                  const Text('Print',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary))
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Water backdrop
    final waterPaint = Paint()..color = const Color(0xFFA8C8E0);
    canvas.drawRect(Offset.zero & size, waterPaint);

    // Land masses
    final landPaint = Paint()..color = const Color(0xFFE8EDE3);
    final landPath = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.15,
          size.width * 0.55, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.5,
          size.width, size.height * 0.45)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(landPath, landPaint);

    final land2 = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.6,
          size.width * 0.8, size.height * 0.8)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(land2, landPaint);

    // Route line
    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final route = Path()
      ..moveTo(size.width * 0.15, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.5,
          size.width * 0.5, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.6,
          size.width * 0.85, size.height * 0.25);
    canvas.drawPath(route, routePaint);

    // Pickup marker
    final startPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.8), 6,
        startPaint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.8), 6,
        Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke);

    // Destination marker
    final endPaint = Paint()..color = AppColors.error;
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.25), 6, endPaint);

    // City label
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Colombo',
        style: TextStyle(
            color: Color(0xFF5A6B5D),
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(size.width * 0.38, size.height * 0.42));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
