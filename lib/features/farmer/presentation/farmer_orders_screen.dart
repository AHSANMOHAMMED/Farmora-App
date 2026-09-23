import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/farmora_strings.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import 'order_detail_screen.dart';
import 'logistics_tracking_screen.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final strings = FarmoraStrings.of(context);
    List<FarmoraOrder> displayOrders;
    if (_selectedTab == 0) {
      displayOrders = state.pendingOrders;
    } else if (_selectedTab == 1) {
      displayOrders = state.acceptedOrders;
    } else {
      displayOrders = state.completedOrders;
    }
    final pendingCount = state.pendingOrders.length;
    final acceptedCount = state.acceptedOrders.length;
    final completedCount = state.completedOrders.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.t('incomingOrders'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  _buildProfileAvatar(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Tab Selector ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTabPill(0, strings.t('pending'), pendingCount),
                  const SizedBox(width: 8),
                  _buildTabPill(1, strings.t('accepted'), acceptedCount),
                  const SizedBox(width: 8),
                  _buildTabPill(2, strings.t('completed'), completedCount),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Orders List ──
            Expanded(
              child: displayOrders.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: displayOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _buildOrderCard(displayOrders[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 22),
    );
  }

  Widget _buildTabPill(int index, String title, int count) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? null : Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.onSurface,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(FarmoraOrder order) {
    final strings = FarmoraStrings.of(context);
    return GestureDetector(
      onTap: () {
        // Accepted orders show live logistics tracking; pending shows acceptance detail
        if (order.isAccepted || order.status == 'In transit') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LogisticsTrackingScreen(order: order)),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Buyer name + Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.buyerCompany,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Order ${order.orderNumber}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(order),
              ],
            ),

            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFF0F0F0)),
            const SizedBox(height: 12),

            // Product row
            Row(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFF5F5F0),
                    child: _buildOrderThumbnail(order),
                  ),
                ),
                const SizedBox(width: 14),

                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName.isNotEmpty ? order.productName : order.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
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
                    ],
                  ),
                ),

                // Price & date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      order.totalAmount,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.timestamp,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Note if present
            if (order.detail.isNotEmpty && order.productName.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${order.detail}"',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],

            // Action buttons for accepted orders
            if (order.isAccepted) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<FarmoraState>().completeOrder(order.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.t('markDelivered')), backgroundColor: AppColors.primary),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    strings.t('markDelivered'),
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],

            // Action buttons for pending orders
            if (order.isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<FarmoraState>().declineOrder(order.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Order ${order.orderNumber} ${strings.t('orderDeclined')}'), backgroundColor: AppColors.error),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onSurface,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          strings.t('decline'),
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(                          onPressed: () {
                            context.read<FarmoraState>().acceptOrder(order.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(strings.t('orderAccepted')), backgroundColor: AppColors.primary),
                            );
                          },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(
                          strings.t('accept'),
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700),
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
    );
  }

  Widget _buildStatusBadge(FarmoraOrder order) {
    Color bgColor, textColor;
    String text;
    if (order.isPending) {
      bgColor = const Color(0xFFFFF8E1);
      textColor = const Color(0xFFE65100);
      text = 'Pending';
    } else if (order.isAccepted) {
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      text = 'Accepted';
    } else {
      bgColor = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF0D47A1);
      text = 'Completed';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderThumbnail(FarmoraOrder order) {
    final name = (order.productName + order.title).toLowerCase();
    if (name.contains('tomato')) {
      return Image.asset('assets/images/cherry_tomatoes.png', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon());
    }
    if (name.contains('lettuce')) {
      return Image.asset('assets/images/romaine_lettuce.png', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon());
    }
    if (name.contains('carrot')) {
      return Image.asset('assets/images/nantes_carrots.png', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon());
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return const Center(child: Icon(Icons.eco, color: AppColors.primary, size: 28));
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: AppColors.outlineVariant),
          SizedBox(height: 16),
          Text('No orders found', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
