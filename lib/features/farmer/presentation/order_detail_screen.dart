import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';

class OrderDetailScreen extends StatelessWidget {
  final FarmoraOrder order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final currentOrder = state.orders.firstWhere((o) => o.id == order.id, orElse: () => order);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Order Detail',
          style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
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
                // ── Buyer Info Card ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          currentOrder.buyerAvatar,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: AppColors.surfaceContainerLow,
                            child: const Icon(Icons.person, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentOrder.buyerCompany,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currentOrder.buyerName} • ${currentOrder.buyerPhone.isNotEmpty ? currentOrder.buyerPhone : '(555) 123-4567'}',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.phone, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Stats Row ──
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL VALUE',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentOrder.totalAmount,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ORDER DATE',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentOrder.requestedDate,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Order Details ──
                const Text(
                  'Order Details',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildOrderItem(
                        currentOrder.productName.isNotEmpty ? currentOrder.productName : currentOrder.title,
                        '${currentOrder.quantity.isNotEmpty ? currentOrder.quantity : currentOrder.detail} @ ${currentOrder.unitPrice.isNotEmpty ? currentOrder.unitPrice : 'LKR 45.00'}',
                        currentOrder.totalAmount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Delivery & Logistics ──
                const Text(
                  'Delivery & Logistics',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Map placeholder
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.map_outlined, size: 48, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Delivery info
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                            child: const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Requested Delivery', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                                SizedBox(height: 2),
                                Text('Oct 26, 2023 - Morning (8AM - 12PM)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Destination
                      const Text(
                        'DESTINATION',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentOrder.deliveryAddress,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.onSurface, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Note: Deliver to the back alley loading dock.',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.onSurfaceVariant),
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
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
                            const SnackBar(content: Text('Order rejected'), backgroundColor: AppColors.error),
                          );
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          backgroundColor: const Color(0xFFFEE2E2),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reject', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600)),
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
                            const SnackBar(content: Text('Order accepted!'), backgroundColor: AppColors.primary),
                          );
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text('Accept Order', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700)),
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

  Widget _buildProfileAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      child: const Icon(Icons.person, color: Colors.white, size: 22),
    );
  }

  Widget _buildOrderItem(String name, String detail, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}
