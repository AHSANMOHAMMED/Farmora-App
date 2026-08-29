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
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge + timestamp
                  // Stitch: flex justify-between items-start mb-sm
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Stitch: inline-flex items-center gap-xs px-sm py-xs rounded-full bg-surface-container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.hourglass_top_rounded,
                              size: 13,
                              color: AppColors.onSurface,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.status.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: AppColors.onSurface,
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
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Thumbnail + item details
                  // Stitch: flex gap-md items-center mb-md
                  Row(
                    children: [
                      // Stitch: w-16 h-16 rounded-lg object-cover bg-surface-container shadow-sm
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
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
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
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
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Divider — Stitch: border-t border-surface-variant/50
                  Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
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
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                order.buyerIcon,
                                size: 15,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order.buyerCompany,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
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
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.totalAmount,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Action Buttons for Pending Orders
                  if (order.isPending) ...[
                    const SizedBox(height: 12),
                    // Stitch: flex gap-sm mt-md pt-sm
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                state.declineOrder(order.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Declined ${order.orderNumber}')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                // Stitch: bg-surface-container text-on-surface rounded-lg
                                backgroundColor: AppColors.surfaceContainer,
                                foregroundColor: AppColors.onSurface,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.close, size: 18),
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
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                state.acceptOrder(order.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.primary,
                                    content: Text('Accepted ${order.orderNumber}! Balance updated.'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                // Stitch: bg-primary text-on-primary rounded-lg shadow-md
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text(
                                'Accept',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
