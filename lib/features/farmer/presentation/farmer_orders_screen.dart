import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/farmer_header.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import 'order_detail_screen.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  int _selectedTab = 0; // 0: Pending, 1: Accepted, 2: Completed

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();

    List<FarmoraOrder> displayOrders;
    if (_selectedTab == 0) {
      displayOrders = state.pendingOrders;
    } else if (_selectedTab == 1) {
      displayOrders = state.acceptedOrders;
    } else {
      displayOrders = state.completedOrders;
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const FarmerHeader(title: 'Orders'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Segmented Filter Tabs
            // Stitch: flex items-center w-full bg-surface-container-low rounded-full p-xs sticky
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildTabButton(0, 'Pending'),
                  _buildTabButton(1, 'Accepted'),
                  _buildTabButton(2, 'Completed'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Orders List
            if (displayOrders.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.shopping_basket_outlined,
                        size: 64,
                        color: AppColors.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No ${_selectedTab == 0 ? "pending" : _selectedTab == 1 ? "accepted" : "completed"} orders',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final order = displayOrders[index];
                  return _buildOrderCard(context, state, order);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(9999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            // Stitch: selected = bg-primary text-on-primary, else transparent
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    FarmoraState state,
    FarmoraOrder order,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        // Stitch: bg-surface-container-lowest rounded-[16px] shadow-sm relative overflow-hidden
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Stitch: absolute left-0 top-0 bottom-0 w-1 bg-surface-tint opacity-70
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                // surface-tint = #006e1c (same as primary)
                color: AppColors.primary.withValues(alpha: 0.70),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge + timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1EFFE),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events_outlined,
                              size: 14,
                              color: Color(0xFF1D4ED8),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              order.status.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        order.timestamp,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475467),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Thumbnail + item details
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: const Color(0xFFE2E8F0),
                          child: _buildOrderThumbnail(order),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.productName.isNotEmpty ? order.productName : order.title,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF101828),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.quantity.isNotEmpty ? order.quantity : order.detail,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Color(0xFF475467),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Divider
                  const Divider(
                    color: Color(0xFFEAECF0),
                    height: 1,
                  ),
                  const SizedBox(height: 12),

                  // Buyer + Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buyer',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF667085),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                order.buyerIcon,
                                size: 16,
                                color: const Color(0xFF0C5123),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                order.buyerCompany,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF101828),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF667085),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.totalAmount,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0C5123),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Action Buttons for Pending Orders
                  if (order.isPending) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                state.declineOrder(order.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Declined ${order.orderNumber}')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFE3EFF8),
                                foregroundColor: const Color(0xFF101828),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text(
                                'Decline',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                state.acceptOrder(order.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Color(0xFF0C5123),
                                    content: Text('Order accepted! Balance updated.'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C5123),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text(
                                'Accept',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderThumbnail(FarmoraOrder order) {
    final name = (order.productName + order.title).toLowerCase();
    if (name.contains('cherry')) {
      return Image.asset('assets/images/cherry_tomatoes.png', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon());
    }
    if (name.contains('lettuce') || name.contains('romaine')) {
      return Image.asset('assets/images/romaine_lettuce.png', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon());
    }
    if (name.contains('apple') || name.contains('fuji')) {
      return Image.asset('assets/images/heirloom_tomatoes.png', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon());
    }
    if (name.contains('carrot')) {
      return Image.asset('assets/images/nantes_carrots.png', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon());
    }
    if (name.contains('kale')) {
      return Image.asset('assets/images/dinosaur_kale.png', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon());
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      color: AppColors.surfaceContainer,
      child: const Center(
        child: Icon(Icons.eco, color: AppColors.primary),
      ),
    );
  }
}
