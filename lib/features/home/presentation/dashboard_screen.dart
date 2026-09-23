import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_role.dart';
import '../../../models/product.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import '../../farmer/presentation/add_product_screen.dart';
import '../../farmer/presentation/farmer_orders_screen.dart';
import '../../farmer/presentation/farmer_products_screen.dart';
import '../../farmer/presentation/farmer_offers_screen.dart';
import '../../farmer/presentation/earnings_screen.dart';
import '../../farmer/presentation/account_verification_screen.dart';
import '../../farmer/presentation/logistics_tracking_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../buyer/presentation/buyer_products_screen.dart';
import '../../buyer/presentation/buyer_orders_screen.dart';
import '../../buyer/presentation/buyer_offers_screen.dart';
import '../../buyer/presentation/cart_screen.dart';
import '../../buyer/presentation/product_detail_screen.dart';
import '../../buyer/presentation/buyer_order_detail_screen.dart';
import '../../transporter/presentation/available_jobs_screen.dart';
import '../../transporter/presentation/delivery_history_screen.dart';
import '../../transporter/presentation/transporter_earnings_screen.dart';
import '../../admin/presentation/user_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showMonthlyEarnings = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final role = state.role;

    if (role == Role.farmer) {
      return _buildFarmerDashboard(context, state);
    } else if (role == Role.buyer) {
      return _buildBuyerDashboard(context, state);
    } else if (role == Role.transporter) {
      return _buildTransporterDashboard(context, state);
    }
    return _buildAdminDashboard(context, state);
  }

  // ═══════════════════════════════════════════════════════════════
  // FARMER DASHBOARD (Stitch Design)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFarmerDashboard(BuildContext context, FarmoraState state) {
    final products = state.products;
    final orders = state.orders;
    final pendingOrders = state.pendingOrders;
    final activeProducts = state.activeProducts;
    final todayOrders = pendingOrders.length + state.acceptedOrders.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // ── 1. HEADER ──
        _buildHeader(context, state),
        const SizedBox(height: 20),
        _buildGreeting(state),
        const SizedBox(height: 28),

        // ── 2. OVERVIEW CARDS ──
        _buildOverviewSection(
          context,
          todayOrders: todayOrders,
          activeProducts: activeProducts.length,
          pendingOrders: pendingOrders.length,
          earnings: state.thisMonth,
        ),
        const SizedBox(height: 32),

        // ── 3. FARM ACTIVITY ──
        _buildSectionTitle('Farm Activity', subtitle: 'Your current produce'),
        const SizedBox(height: 14),
        _buildFarmActivity(context, products, orders),
        const SizedBox(height: 32),

        // ── 4. EARNINGS OVERVIEW ──
        _buildSectionTitle('Earnings Overview'),
        const SizedBox(height: 14),
        _buildEarningsOverview(context, state),
        const SizedBox(height: 32),

        // ── 5. RECENT ORDERS ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FarmerOrdersScreen()),
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildRecentOrders(context, orders),
        const SizedBox(height: 32),

        // ── 6. QUICK ACTIONS ──
        _buildSectionTitle('Quick Actions'),
        const SizedBox(height: 14),
        _buildQuickActions(context, Role.farmer),
        const SizedBox(height: 32),

        // ── 7. NOTIFICATIONS ──
        _buildSectionTitle('Recent Notifications'),
        const SizedBox(height: 14),
        _buildNotifications(context),
        const SizedBox(height: 20),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 1. HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context, FarmoraState state) {
    return Row(
      children: [
        // Profile avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
          ),
          child: ClipOval(
            child: state.photoUrl.isNotEmpty
                ? Image.network(
                    state.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                  )
                : _buildAvatarFallback(),
          ),
        ),
        const SizedBox(width: 12),
        // Farmora branding
        const Text(
          'Farmora',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        // Notification bell
        Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.onSurface,
                  size: 22,
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // GREETING
  // ═══════════════════════════════════════════════════════════════
  Widget _buildGreeting(FarmoraState state) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    final name = state.displayName.isNotEmpty
        ? state.displayName
        : (state.role == Role.farmer ? 'Farmer' : state.role.label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $name 👋',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          state.district.isNotEmpty
              ? "Here's what's happening in ${state.district} today."
              : "Here's what's happening with your farm today.",
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. OVERVIEW CARDS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildOverviewSection(
    BuildContext context, {
    required int todayOrders,
    required int activeProducts,
    required int pendingOrders,
    required double earnings,
  }) {
    return Column(
      children: [
        // Top row: Today's Orders + Active Products
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFF2E7D32),
                iconBg: const Color(0xFFE8F5E9),
                label: "Today's Orders",
                value: '$todayOrders',
                trend: '+2 from yesterday',
                trendUp: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.eco_rounded,
                iconColor: const Color(0xFF1565C0),
                iconBg: const Color(0xFFE3F2FD),
                label: 'Active Products',
                value: '$activeProducts',
                trend: 'Listed for sale',
                trendUp: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom row: Pending Orders + Earnings
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.pending_actions_rounded,
                iconColor: const Color(0xFFE65100),
                iconBg: const Color(0xFFFFF3E0),
                label: 'Pending Orders',
                value: '$pendingOrders',
                trend: 'Awaiting response',
                trendUp: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEarningsCard(earnings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEarningsCard(double earnings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payments_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            'LKR ${earnings.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This Month',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF81C784)),
              const SizedBox(width: 4),
              Text(
                'Earnings',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String trend,
    required bool trendUp,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                trendUp ? Icons.trending_up_rounded : Icons.schedule_rounded,
                size: 14,
                color: trendUp ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 11,
                    color: trendUp ? AppColors.primary : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. FARM ACTIVITY
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFarmActivity(BuildContext context, List<Product> products, List<FarmoraOrder> orders) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: _cardDecoration(),
        child: const Center(
          child: Text('No produce listed yet', style: TextStyle(color: AppColors.onSurfaceVariant)),
        ),
      );
    }

    return Column(
      children: products.take(4).map((product) {
        final productOrders = orders.where((o) =>
            o.title.toLowerCase() == product.name.toLowerCase() ||
            o.productName.toLowerCase() == product.name.toLowerCase()).length;

        final stockStatus = _getStockStatus(product);

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FarmerProductsScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: stockStatus.$2.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(product.emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isOrganic)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Organic',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.quantity} · LKR ${product.pricePerUnit.toStringAsFixed(2)} / ${product.unit}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: stockStatus.$2.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: stockStatus.$2,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                stockStatus.$1,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: stockStatus.$2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (productOrders > 0)
                          Text(
                            '$productOrders active order${productOrders > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: AppColors.outlineVariant, size: 22),
            ],
          ),
        ),
      );
      }).toList(),
    );
  }

  (String, Color) _getStockStatus(Product product) {
    if (product.isEmpty) {
      return ('Out of Stock', const Color(0xFFB71C1C));
    }
    return ('In Stock', const Color(0xFF2E7D32));
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. EARNINGS OVERVIEW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEarningsOverview(BuildContext context, FarmoraState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildToggleChip('Monthly', _showMonthlyEarnings, () {
                setState(() => _showMonthlyEarnings = true);
              }),
              const SizedBox(width: 8),
              _buildToggleChip('Weekly', !_showMonthlyEarnings, () {
                setState(() => _showMonthlyEarnings = false);
              }),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'LKR ${(_showMonthlyEarnings ? state.thisMonth : state.thisWeek).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _showMonthlyEarnings ? "This month's earnings" : "This week's earnings",
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 120,
            child: _buildMiniBarChart(state),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '+15.2% vs last ${_showMonthlyEarnings ? 'month' : 'week'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: AppColors.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBarChart(FarmoraState state) {
    final bars = state.monthlyBars;
    if (bars.isEmpty) {
      return const Center(child: Text('No data', style: TextStyle(color: AppColors.onSurfaceVariant)));
    }

    final maxAmount = bars.map((b) => b.amount).reduce((a, b) => a > b ? a : b).toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((bar) {
        final heightRatio = maxAmount > 0 ? bar.amount / maxAmount : 0.0;
        final isHighlighted = bar.isHighlighted;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isHighlighted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'LKR ${bar.amount}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                Container(
                  height: (heightRatio * 90).clamp(8.0, 90.0),
                  decoration: BoxDecoration(
                    color: isHighlighted ? AppColors.primary : const Color(0xFFC8E6C9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bar.month,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                    color: isHighlighted ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 5. RECENT ORDERS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRecentOrders(BuildContext context, List<FarmoraOrder> orders) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: _cardDecoration(),
        child: const Center(
          child: Text('No recent orders', style: TextStyle(color: AppColors.onSurfaceVariant)),
        ),
      );
    }

    return Column(
      children: orders.take(4).map((order) => _buildOrderCard(order)).toList(),
    );
  }

  Widget _buildOrderCard(FarmoraOrder order) {
    final statusColor = _getStatusColor(order.status);
    final statusBg = _getStatusBg(order.status);
    final emoji = _getOrderEmoji(order.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.title.isNotEmpty ? order.title : order.productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, 6)} · ${order.buyerName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      order.totalAmount.isNotEmpty ? order.totalAmount : 'LKR ${order.totalAmountNumber.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 6. QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildQuickActions(BuildContext context, Role role) {
    final state = context.read<FarmoraState>();
    final actions = <Map<String, dynamic>>[];

    if (role == Role.farmer) {
      actions.addAll([
        {
          'icon': Icons.add_circle_outline_rounded,
          'label': 'Add Produce',
          'color': const Color(0xFF2E7D32),
          'bg': const Color(0xFFE8F5E9),
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          ),
        },
        {
          'icon': Icons.receipt_long_outlined,
          'label': 'Manage Orders',
          'color': const Color(0xFFE65100),
          'bg': const Color(0xFFFFF3E0),
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FarmerOrdersScreen()),
          ),
        },
        {
          'icon': Icons.local_offer_outlined,
          'label': 'Price Offers',
          'color': const Color(0xFF6A1B9A),
          'bg': const Color(0xFFF3E5F5),
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FarmerOffersScreen()),
          ),
        },
        {
          'icon': Icons.payments_outlined,
          'label': 'View Earnings',
          'color': const Color(0xFF006E1C),
          'bg': const Color(0xFFE8F5E9),
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EarningsScreen()),
          ),
        },
        {
          'icon': Icons.person_outline_rounded,
          'label': 'Farm Profile',
          'color': const Color(0xFF1565C0),
          'bg': const Color(0xFFE3F2FD),
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AccountVerificationScreen()),
          ),
        },
        {
          'icon': Icons.local_shipping_outlined,
          'label': 'Logistics',
          'color': const Color(0xFF00796B),
          'bg': const Color(0xFFE0F2F1),
          'onTap': () {
            final activeOrder = state.orders.where((o) => o.isAccepted || o.progress > 0).firstOrNull ??
                (state.orders.isNotEmpty ? state.orders.first : null);
            if (activeOrder != null) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LogisticsTrackingScreen(order: activeOrder)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No active orders to track yet.')),
              );
            }
          },
        },
      ]);
    } else if (role == Role.buyer) {
      actions.addAll([
        {
          'icon': Icons.storefront_outlined,
          'label': 'Produce',
          'color': const Color(0xFF2E7D32),
          'bg': const Color(0xFFE8F5E9),
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BuyerProductsScreen()),
          ),
        },
        {
          'icon': Icons.shopping_basket_outlined,
          'label': 'My Orders',
          'color': const Color(0xFFE65100),
          'bg': const Color(0xFFFFF3E0),
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BuyerOrdersScreen()),
          ),
        },
        {
          'icon': Icons.local_offer_outlined,
          'label': 'My Offers',
          'color': const Color(0xFF6A1B9A),
          'bg': const Color(0xFFF3E5F5),
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BuyerOffersScreen()),
          ),
        },
        {
          'icon': Icons.shopping_cart_outlined,
          'label': 'My Cart',
          'color': const Color(0xFF006D44),
          'bg': const Color(0xFFE8F5E9),
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        },
      ]);
    } else if (role == Role.transporter) {
      actions.addAll([
        {
          'icon': Icons.local_shipping_outlined,
          'label': 'Available Jobs',
          'color': const Color(0xFF2E7D32),
          'bg': const Color(0xFFE8F5E9),
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AvailableJobsScreen()),
          ),
        },
        {
          'icon': Icons.history_rounded,
          'label': 'Deliveries',
          'color': const Color(0xFF1565C0),
          'bg': const Color(0xFFE3F2FD),
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DeliveryHistoryScreen()),
          ),
        },
        {
          'icon': Icons.payments_outlined,
          'label': 'Earnings',
          'color': const Color(0xFF006E1C),
          'bg': const Color(0xFFE8F5E9),
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransporterEarningsScreen()),
          ),
        },
      ]);
    } else if (role == Role.admin) {
      actions.addAll([
        {
          'icon': Icons.people_outline_rounded,
          'label': 'User Management',
          'color': const Color(0xFF1565C0),
          'bg': const Color(0xFFE3F2FD),
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UserManagementScreen()),
          ),
        },
      ]);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.map((action) {
          return Container(
            width: 96,
            margin: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: action['onTap'] as VoidCallback,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: action['bg'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 7. NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildNotifications(BuildContext context) {
    final notifications = [
      const _NotificationItem(
        icon: Icons.shopping_cart_rounded,
        iconColor: Color(0xFF2E7D32),
        iconBg: Color(0xFFE8F5E9),
        title: 'New order received',
        subtitle: 'Green Grocery Store ordered 50 kg Heirloom Tomatoes',
        time: '2 min ago',
      ),
      const _NotificationItem(
        icon: Icons.local_shipping_rounded,
        iconColor: Color(0xFF1565C0),
        iconBg: Color(0xFFE3F2FD),
        title: 'Transport assigned',
        subtitle: 'Your delivery ORD-8892 is on the way',
        time: '15 min ago',
      ),
      const _NotificationItem(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: Color(0xFF006E1C),
        iconBg: Color(0xFFE8F5E9),
        title: 'Payment received',
        subtitle: 'LKR 210.00 from Local Fresh Market',
        time: '1 hour ago',
      ),
      const _NotificationItem(
        icon: Icons.check_circle_rounded,
        iconColor: Color(0xFF2E7D32),
        iconBg: Color(0xFFE8F5E9),
        title: 'Order delivered',
        subtitle: 'ORD-8881 has been delivered to Bistro 44',
        time: '3 hours ago',
      ),
    ];

    return Column(
      children: notifications.map((n) => _buildNotificationTile(n)).toList(),
    );
  }

  Widget _buildNotificationTile(_NotificationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.time,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUYER / TRANSPORTER / ADMIN DASHBOARDS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBuyerDashboard(BuildContext context, FarmoraState state) {
    final products = state.products;
    final activeOrders = [...state.pendingOrders, ...state.acceptedOrders];
    final activeDelivery = state.orders.where((o) =>
        o.status.toLowerCase().contains('transit') ||
        o.status.toLowerCase() == 'accepted').firstOrNull ??
        state.orders.firstOrNull;
    final totalSpent = state.orders.fold<double>(0.0, (sum, o) => sum + o.total);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        _buildHeader(context, state),
        const SizedBox(height: 20),
        _buildGreeting(state),
        const SizedBox(height: 28),

        // 1. Spending Highlights Gradient Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MARKETPLACE ORDERS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${activeOrders.length} active',
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'LKR ${totalSpent.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Total order volume handled via secure escrow',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Stat Cards Row
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.local_shipping_rounded,
                iconColor: const Color(0xFF1565C0),
                iconBg: const Color(0xFFE3F2FD),
                label: 'Active Orders',
                value: '${activeOrders.length}',
                trend: 'In progress',
                trendUp: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.shopping_bag_rounded,
                iconColor: const Color(0xFFE65100),
                iconBg: const Color(0xFFFFF3E0),
                label: 'In Cart',
                value: '${state.cartItemCount}',
                trend: 'Ready to order',
                trendUp: state.cartItemCount > 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.handshake_rounded,
                iconColor: const Color(0xFF6A1B9A),
                iconBg: const Color(0xFFF3E5F5),
                label: 'Offers',
                value: '${state.pendingOffersCount}',
                trend: 'Negotiations',
                trendUp: state.pendingOffersCount > 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // 3. Live Delivery Tracking Banner (if active delivery exists)
        if (activeDelivery != null) ...[
          _buildSectionTitle('Active Delivery', subtitle: 'Track your produce live'),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BuyerOrderDetailScreen(order: activeDelivery),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeDelivery.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              'Order ${activeDelivery.orderNumber} • ${activeDelivery.deliveryAddress}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          activeDelivery.status,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: activeDelivery.progress > 0 ? activeDelivery.progress : 0.3,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stage: ${activeDelivery.status}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                      ),
                      const Row(
                        children: [
                          Text('View Detail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],

        // 4. Quick Actions
        _buildSectionTitle('Quick Actions'),
        const SizedBox(height: 14),
        _buildQuickActions(context, Role.buyer),
        const SizedBox(height: 32),

        // 5. Featured Produce
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Produce',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BuyerProductsScreen()),
              ),
              child: const Text(
                'Browse All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (products.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: _cardDecoration(),
            child: const Center(
              child: Text('No produce currently listed', style: TextStyle(color: AppColors.onSurfaceVariant)),
            ),
          )
        else
          ...products.take(4).map((product) {
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: _cardDecoration(),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: product.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(product.emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                              if (product.isOrganic)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ORGANIC',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product.location} • ${product.quantity}',
                            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'LKR ${product.pricePerUnit.toStringAsFixed(0)} / ${product.unit}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  state.addToCart(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${product.name} added to cart!'),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.add_shopping_cart, size: 14),
                                label: const Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTransporterDashboard(BuildContext context, FarmoraState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        _buildHeader(context, state),
        const SizedBox(height: 20),
        _buildGreeting(state),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(child: _buildOverviewCard(
              icon: Icons.local_shipping_rounded, iconColor: const Color(0xFF2E7D32),
              iconBg: const Color(0xFFE8F5E9), label: 'Active Jobs',
              value: '${state.jobs.length}', trend: 'In progress', trendUp: true,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildOverviewCard(
              icon: Icons.check_circle_rounded, iconColor: const Color(0xFF006E1C),
              iconBg: const Color(0xFFE8F5E9), label: 'Completed',
              value: '${state.completedOrders.length}', trend: 'Total deliveries', trendUp: true,
            )),
          ],
        ),
        const SizedBox(height: 32),
        _buildSectionTitle('Quick Actions'),
        const SizedBox(height: 14),
        _buildQuickActions(context, Role.transporter),
      ],
    );
  }

  Widget _buildAdminDashboard(BuildContext context, FarmoraState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        _buildHeader(context, state),
        const SizedBox(height: 20),
        _buildGreeting(state),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(child: _buildOverviewCard(
              icon: Icons.people_rounded, iconColor: const Color(0xFF1565C0),
              iconBg: const Color(0xFFE3F2FD), label: 'Total Users',
              value: '${state.users.length}', trend: 'Registered', trendUp: true,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildOverviewCard(
              icon: Icons.receipt_long_rounded, iconColor: const Color(0xFF2E7D32),
              iconBg: const Color(0xFFE8F5E9), label: 'Total Orders',
              value: '${state.orders.length}', trend: 'All time', trendUp: true,
            )),
          ],
        ),
        const SizedBox(height: 32),
        _buildSectionTitle('Quick Actions'),
        const SizedBox(height: 14),
        _buildQuickActions(context, Role.admin),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8F5E9).withValues(alpha: 0.6)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return const Color(0xFFE65100);
      case 'accepted': case 'in transit': return const Color(0xFF2E7D32);
      case 'delivered': case 'completed': return const Color(0xFF1B5E20);
      case 'declined': case 'rejected': return const Color(0xFF93000A);
      default: return AppColors.onSurfaceVariant;
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return const Color(0xFFFFF3E0);
      case 'accepted': case 'in transit': return const Color(0xFFE8F5E9);
      case 'delivered': case 'completed': return const Color(0xFFC8E6C9);
      case 'declined': case 'rejected': return const Color(0xFFFFDAD6);
      default: return const Color(0xFFF5F5F5);
    }
  }

  String _getOrderEmoji(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('tomato')) return '🍅';
    if (lower.contains('corn')) return '🌽';
    if (lower.contains('apple')) return '🍏';
    if (lower.contains('carrot')) return '🥕';
    if (lower.contains('lettuce') || lower.contains('romaine')) return '🥬';
    if (lower.contains('kale')) return '🥬';
    if (lower.contains('eggplant')) return '🍆';
    return '🌱';
  }
}

class _NotificationItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String time;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

/// Alias for backward compatibility
typedef Dashboard = DashboardScreen;
