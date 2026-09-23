import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/farmora_strings.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import 'logistics_tracking_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final FarmoraOrder order;

  const OrderDetailScreen({super.key, required this.order});

  String _fmtLKR(double v) {
    final whole = v.round();
    final s = whole.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return 'LKR $s';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final strings = FarmoraStrings.of(context);
    final currentOrder =
        state.orders.firstWhere((o) => o.id == order.id, orElse: () => order);

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
            child: _buildProfileAvatar(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Order Request Header ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                          color: Color(0xFF6B4F3A), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        strings.t('newOrderRequest'),
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                            height: 1.25),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBC4AB).withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 16, color: Color(0xFF8A4B24)),
                          const SizedBox(width: 6),
                          Text(
                            strings.t('pendingAcceptance'),
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8A4B24),
                                height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${currentOrder.quantity.isNotEmpty ? currentOrder.quantity : '28 kg'} @ '
                  '${_fmtLKR(_parseUnitPrice(currentOrder.unitPrice))} / kg',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),

                // ── Buyer Card ──
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
                              currentOrder.buyerAvatar,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 52,
                                height: 52,
                                color: AppColors.surfaceContainerLow,
                                child: const Icon(Icons.storefront_rounded,
                                    color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        currentOrder.buyerCompany,
                                        style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onSurface),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified_rounded,
                                        size: 16, color: AppColors.primary),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(strings.t('verifiedBuyer'),
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 2),
                                const Row(
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        size: 13, color: AppColors.onSurfaceVariant),
                                    SizedBox(width: 3),
                                    Text('San Francisco, CA',
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            color: AppColors.onSurfaceVariant)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 18, color: AppColors.onSurface),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                '+94 77 123 4567',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.phone_in_talk_rounded,
                                  size: 16, color: AppColors.primary),
                              label: Text(strings.t('callBuyer'),
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                elevation: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Payout Stats ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(strings.t('totalPayout'),
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: AppColors.onSurfaceVariant)),
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                      color: Color(0xFFE8F5E9),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.account_balance_wallet_rounded,
                                      size: 15, color: AppColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _fmtLKR(currentOrder.totalAmountNumber),
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.receipt_long_rounded,
                                    size: 13, color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(strings.t('guaranteedEscrow'),
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: AppColors.onSurfaceVariant)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(strings.t('orderPlaced'),
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          color: AppColors.onSurfaceVariant)),
                                ),
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFFE5E7EB))),
                                  child: const Icon(Icons.calendar_today_rounded,
                                      size: 14, color: AppColors.onSurface),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentOrder.requestedDate,
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentOrder.timestamp.contains(':')
                                  ? currentOrder.timestamp
                                  : '09:42 AM',
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Produce Details ──
                Row(
                  children: [
                    const Icon(Icons.local_florist_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(strings.t('produceDetails'),
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '1 Item (${currentOrder.quantity.isNotEmpty ? currentOrder.quantity : '28 kg'} total)',
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
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
                    children: [
                      _buildProduceItem(context, currentOrder),
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
                            const Icon(Icons.inventory_2_outlined,
                                size: 16, color: AppColors.onSurface),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(strings.t('packagingProtocol'),
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onSurface)),
                                  const SizedBox(height: 3),
                                  Text(
                                      strings.t('packagingDesc'),
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: AppColors.onSurfaceVariant,
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
                const SizedBox(height: 24),

                // ── 3PL Dispatch Info ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5EC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                                color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.local_shipping_rounded,
                                size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              strings.t('dispatch3pl'),
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B5E20)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        strings.t('dispatch3plDesc'),
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFF33691E),
                            height: 1.45),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                LogisticsTrackingScreen(order: currentOrder),
                          ));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              strings.t('viewLogistics'),
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32)),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 14, color: Color(0xFF2E7D32)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Action Buttons ──
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
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          state.declineOrder(currentOrder.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(strings.t('orderRejected')),
                                backgroundColor: AppColors.error),
                          );
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          backgroundColor: const Color(0xFFFDE8E8),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.close_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(strings.t('reject'),
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          state.acceptOrder(currentOrder.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(strings.t('orderAccepted')),
                                backgroundColor: AppColors.primary),
                          );
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          '${strings.t('acceptOrder')} (${_fmtLKR(currentOrder.totalAmountNumber)})',
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
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

  double _parseUnitPrice(String unitPrice) {
    final digits = unitPrice.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digits) ?? 1375;
  }

  Widget _buildProduceItem(BuildContext context, FarmoraOrder order) {
    final strings = FarmoraStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  order.buyerAvatar,
                  width: 62,
                  height: 62,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 62,
                    height: 62,
                    color: AppColors.surfaceContainerLow,
                    child: const Icon(Icons.eco, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName.isNotEmpty
                          ? order.productName
                          : order.title,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8EFC9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.eco_outlined,
                              size: 13, color: Color(0xFF33691E)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${order.grade} · ${strings.t('harvestReady')}',
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF33691E)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _fmtLKR(order.totalAmountNumber),
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${order.quantity.isNotEmpty ? order.quantity : '28 kg'} @ ${_fmtLKR(_parseUnitPrice(order.unitPrice))} / kg',
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration:
          const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      child: const Icon(Icons.person, color: Colors.white, size: 22),
    );
  }
}
