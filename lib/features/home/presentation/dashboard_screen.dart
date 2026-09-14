import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import '../../farmer/presentation/add_product_screen.dart';
import '../../farmer/presentation/farmer_orders_screen.dart';
import '../../farmer/presentation/earnings_screen.dart';
import '../../buyer/presentation/buyer_products_screen.dart';
import '../../transporter/presentation/available_jobs_screen.dart';

import '../../notifications/presentation/notifications_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final role = state.role;
    final isFarmer = role == Role.farmer;
    final greeting = _getGreeting();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // ── Header: Avatar + Farmora + Bell ─────────────────
        _buildHeader(context, state),
        const SizedBox(height: 20),

        // ── Greeting ───────────────────────────────────────
        Text(
          '$greeting, ${state.signedIn ? 'Farmer' : 'there'}',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Here's what's happening on the farm today.",
          style: TextStyle(
            fontSize: 15,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // ── Stat Cards (vertical stack) ────────────────────
        if (isFarmer) ...[
          _buildStatCard(
            label: 'Total Products',
            value: '${state.products.length}',
            subtitle: '+${state.activeProducts.length} active',
            icon: Icons.shopping_bag_outlined,
            iconColor: const Color(0xFF2E7D32),
            iconBg: const Color(0xFFE8F5E9),
            trailingIcon: Icons.eco_rounded,
            trailingColor: const Color(0xFFC8E6C9),
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            label: 'Active Orders',
            value: '${state.pendingOrders.length + state.acceptedOrders.length}',
            subtitle: '${state.pendingOrders.length} pending dispatch',
            icon: Icons.receipt_long_outlined,
            iconColor: const Color(0xFFE65100),
            iconBg: const Color(0xFFFFF3E0),
            trailingIcon: Icons.shopping_cart_outlined,
            trailingColor: const Color(0xFFC8E6C9),
          ),
          const SizedBox(height: 12),
          _buildEarningsCard(
            amount: 'LKR ${state.thisMonth.toStringAsFixed(2)}',
          ),
        ] else ...[
          // Buyer / Transporter overview
          Row(
            children: [
              Expanded(
                child: _buildSmallStatCard(
                  label: isFarmer ? 'Products' : 'Jobs',
                  value: '${isFarmer ? state.products.length : state.jobs.length}',
                  icon: isFarmer ? Icons.eco_rounded : Icons.local_shipping_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallStatCard(
                  label: 'Orders',
                  value: '${state.orders.length}',
                  icon: Icons.receipt_long_rounded,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 28),

        // ── Quick Actions ──────────────────────────────────
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickActions(context, role),
        const SizedBox(height: 28),

        // ── Recent Orders ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to orders tab (index 2 for farmer)
                // The HomeScreen handles tab switching
              },
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
        const SizedBox(height: 8),
        ...state.orders.take(3).map((order) => _buildRecentOrderTile(order)),
        if (state.orders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No recent orders',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, FarmoraState state) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFE8F5E9),
          child: ClipOval(
            child: Image.asset(
              'assets/images/farmer_headshot.png',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Farmora',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        Stack(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.onSurface,
                size: 26,
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Stat Card (Products / Orders) ──────────────────────────
  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required IconData trailingIcon,
    required Color trailingColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 12),
              Icon(trailingIcon, color: trailingColor, size: 40),
            ],
          ),
        ],
      ),
    );
  }

  // ── Earnings Card (green gradient) ─────────────────────────
  Widget _buildEarningsCard({required String amount}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Earnings (This Month)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFA5D6A7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // ── Small Stat Card (for non-farmer roles) ─────────────────
  Widget _buildSmallStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions Grid ─────────────────────────────────────
  Widget _buildQuickActions(BuildContext context, Role role) {
    final actions = _getQuickActions(context, role);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(
          context: context,
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          onTap: action['onTap'] as VoidCallback,
        );
      },
    );
  }

  List<Map<String, dynamic>> _getQuickActions(BuildContext context, Role role) {
    if (role == Role.farmer) {
      return [
        {
          'icon': Icons.add_circle_outline_rounded,
          'label': 'Add Product',
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          ),
        },
        {
          'icon': Icons.receipt_long_outlined,
          'label': 'View Orders',
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FarmerOrdersScreen()),
          ),
        },
        {
          'icon': Icons.local_shipping_outlined,
          'label': 'Request\nTransport',
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AvailableJobsScreen()),
          ),
        },
        {
          'icon': Icons.bar_chart_rounded,
          'label': 'Analytics',
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EarningsScreen()),
          ),
        },
      ];
    } else if (role == Role.buyer) {
      return [
        {
          'icon': Icons.search_rounded,
          'label': 'Browse\nProducts',
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BuyerProductsScreen()),
          ),
        },
        {
          'icon': Icons.receipt_long_outlined,
          'label': 'My Orders',
          'onTap': () {},
        },
        {
          'icon': Icons.shopping_cart_outlined,
          'label': 'View Cart',
          'onTap': () {},
        },
        {
          'icon': Icons.person_outline_rounded,
          'label': 'Profile',
          'onTap': () {},
        },
      ];
    } else if (role == Role.transporter) {
      return [
        {
          'icon': Icons.local_shipping_outlined,
          'label': 'Find Jobs',
          'onTap': () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AvailableJobsScreen()),
          ),
        },
        {
          'icon': Icons.receipt_long_outlined,
          'label': 'My Deliveries',
          'onTap': () {},
        },
        {
          'icon': Icons.map_outlined,
          'label': 'Route Map',
          'onTap': () {},
        },
        {
          'icon': Icons.bar_chart_rounded,
          'label': 'Earnings',
          'onTap': () {},
        },
      ];
    }
    // Admin
    return [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'onTap': () {},
      },
      {
        'icon': Icons.people_outline_rounded,
        'label': 'Users',
        'onTap': () {},
      },
      {
        'icon': Icons.local_shipping_outlined,
        'label': 'Logistics',
        'onTap': () {},
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Settings',
        'onTap': () {},
      },
    ];
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F5E9), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent Order Tile ──────────────────────────────────────
  Widget _buildRecentOrderTile(dynamic order) {
    final statusColor = _getStatusColor(order.status);
    final statusBg = _getStatusBg(order.status);
    final orderEmoji = _getOrderEmoji(order.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1),
      ),
      child: Row(
        children: [
          // Emoji / icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(orderEmoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),

          // Order info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Order ${order.orderNumber} \u00b7 ${order.quantity}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Chevron
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.onSurfaceVariant,
            size: 22,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFE65100);
      case 'accepted':
      case 'in transit':
        return const Color(0xFF2E7D32);
      case 'delivered':
      case 'completed':
        return const Color(0xFF1B5E20);
      case 'declined':
      case 'rejected':
        return const Color(0xFF93000A);
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF3E0);
      case 'accepted':
      case 'in transit':
        return const Color(0xFFE8F5E9);
      case 'delivered':
      case 'completed':
        return const Color(0xFFC8E6C9);
      case 'declined':
      case 'rejected':
        return const Color(0xFFFFDAD6);
      default:
        return const Color(0xFFF5F5F5);
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

/// Alias for backward compatibility
typedef Dashboard = DashboardScreen;
