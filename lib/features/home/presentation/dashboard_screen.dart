import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../models/user_role.dart';
import '../../../models/product.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/earnings_calculator.dart';
import '../../profile/presentation/edit_profile_screen.dart';
import 'order_navigation.dart';
import '../../farmer/presentation/add_product_screen.dart';
import '../../farmer/presentation/farmer_orders_screen.dart';
import '../../farmer/presentation/farmer_products_screen.dart';
import '../../farmer/presentation/farmer_offers_screen.dart';
import '../../farmer/presentation/earnings_screen.dart';
import '../../farmer/presentation/farmer_jobs_screen.dart';
import '../../farmer/presentation/farm_workspace_screen.dart';
import '../../market/presentation/market_price_board_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../buyer/presentation/buyer_products_screen.dart';
import '../../buyer/presentation/buyer_orders_screen.dart';
import '../../buyer/presentation/buyer_offers_screen.dart';
import '../../buyer/presentation/cart_screen.dart';
import '../../buyer/presentation/product_detail_screen.dart';
import '../../buyer/presentation/buyer_market_screen.dart';
import '../../transporter/presentation/active_delivery_screen.dart';
import '../../transporter/presentation/available_jobs_screen.dart';
import '../../transporter/presentation/delivery_history_screen.dart';
import '../../transporter/presentation/nearby_transporters_screen.dart';
import '../../transporter/presentation/transporter_earnings_screen.dart';
import '../../auth/presentation/auth_l10n.dart';

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
    // Admins use the admin tabs (HomeScreen never shows this dashboard to
    // them); keep a neutral screen instead of a dead admin dashboard.
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        _buildHeader(context, state),
        const SizedBox(height: 20),
        _buildGreeting(state),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FARMER DASHBOARD (Stitch Design)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFarmerDashboard(BuildContext context, FarmoraState state) {
    final products = state.products;
    final orders = state.orders;
    final pendingOrders = state.pendingOrders;
    final activeProducts = state.activeProducts;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    bool placedOn(FarmoraOrder o, DateTime day) =>
        !o.isCancelled &&
        o.createdAt.year == day.year &&
        o.createdAt.month == day.month &&
        o.createdAt.day == day.day;
    final todayOrders = orders.where((o) => placedOn(o, today)).length;
    final yesterdayOrders = orders.where((o) => placedOn(o, yesterday)).length;

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
          yesterdayOrders: yesterdayOrders,
          activeProducts: activeProducts.length,
          pendingOrders: pendingOrders.length,
          earnings: state.thisMonth,
        ),
        const SizedBox(height: 32),

        // ── 3. FARM ACTIVITY ──
        _buildSectionTitle(context.l10n.dashboardFarmActivity,
            subtitle: context.l10n.dashboardYourProduce),
        const SizedBox(height: 14),
        _buildFarmActivity(context, products, orders),
        const SizedBox(height: 32),

        // ── 4. EARNINGS OVERVIEW ──
        _buildSectionTitle(context.l10n.dashboardEarningsOverview),
        const SizedBox(height: 14),
        _buildEarningsOverview(context, state),
        const SizedBox(height: 32),

        // ── 5. RECENT ORDERS ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.l10n.dashboardRecentOrders,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FarmerOrdersScreen()),
              ),
              child: Text(
                context.l10n.commonViewAll,
                style: const TextStyle(
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
        _buildSectionTitle(context.l10n.dashboardQuickActions),
        const SizedBox(height: 14),
        _buildQuickActions(context, Role.farmer),
        const SizedBox(height: 32),

        // ── 7. NOTIFICATIONS ──
        _buildSectionTitle(context.l10n.dashboardRecentNotifications),
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
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3), width: 2),
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
            Semantics(
              button: true,
              label: context.l10n.notifications,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.onSurface,
                    size: 22,
                  ),
                ),
              ),
            ),
            if (state.unreadNotificationsCount > 0)
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
      child:
          const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // GREETING
  // ═══════════════════════════════════════════════════════════════
  Widget _buildGreeting(FarmoraState state) {
    final l10n = context.l10n;
    final hour = DateTime.now().hour;
    final name =
        state.displayName.isNotEmpty ? state.displayName : state.role.label;
    final String greeting;
    if (hour < 12) {
      greeting = l10n.dashboardGoodMorning(name);
    } else if (hour < 17) {
      greeting = l10n.dashboardGoodAfternoon(name);
    } else {
      greeting = l10n.dashboardGoodEvening(name);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
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
              ? l10n.dashboardHappeningInDistrict(
                  districtLabel(state.district, l10n))
              : l10n.dashboardHappeningOnFarm,
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
    required int yesterdayOrders,
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
                label: context.l10n.dashboardTodaysOrders,
                value: AppFormat.number(todayOrders),
                trend: _dayTrend(todayOrders - yesterdayOrders),
                trendUp: todayOrders > yesterdayOrders,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.eco_rounded,
                iconColor: const Color(0xFF1565C0),
                iconBg: const Color(0xFFE3F2FD),
                label: context.l10n.dashboardActiveProducts,
                value: AppFormat.number(activeProducts),
                trend: context.l10n.dashboardListedForSale,
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
                label: context.l10n.dashboardPendingOrders,
                value: AppFormat.number(pendingOrders),
                trend: context.l10n.dashboardAwaitingResponse,
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

  /// Change vs yesterday, computed from the orders (no fixed numbers).
  String _dayTrend(int diff) {
    if (diff > 0) return context.l10n.dashboardTrendFromYesterday(diff);
    if (diff == 0) return 'Same as yesterday';
    return '$diff from yesterday';
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
            child: const Icon(Icons.payments_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            AppFormat.lkr(earnings),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.dashboardThisMonth,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  size: 14, color: Color(0xFF81C784)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  context.l10n.earnings,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                    color: trendUp
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
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
  Widget _buildFarmActivity(
      BuildContext context, List<Product> products, List<FarmoraOrder> orders) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: _cardDecoration(),
        child: Center(
          child: Text(context.l10n.dashboardNoProduceYet,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.onSurfaceVariant)),
        ),
      );
    }

    return Column(
      children: products.take(4).map((product) {
        final productOrders = orders
            .where((o) =>
                o.title.toLowerCase() == product.name.toLowerCase() ||
                o.productName.toLowerCase() == product.name.toLowerCase())
            .length;

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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: product.imagePath != null && product.imagePath!.isNotEmpty
                        ? SafeImage(
                            path: product.imagePath!,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                product.emoji.length > 2 ? product.emoji.characters.first : product.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              product.emoji.length > 2 ? product.emoji.characters.first : product.emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                context.l10n.dashboardOrganic,
                                style: const TextStyle(
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
                        '${product.quantity} · ${AppFormat.lkr(product.pricePerUnit, decimals: 2)} / ${_unitLabel(product.unit)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
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
                                  Flexible(
                                    child: Text(
                                      stockStatus.$1,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: stockStatus.$2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (productOrders > 0)
                            Flexible(
                              child: Text(
                                context.l10n
                                    .dashboardActiveOrdersCount(productOrders),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.outlineVariant, size: 22),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  (String, Color) _getStockStatus(Product product) {
    if (product.isEmpty) {
      return (context.l10n.statusOutOfStock, const Color(0xFFB71C1C));
    }
    return (context.l10n.dashboardInStock, const Color(0xFF2E7D32));
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. EARNINGS OVERVIEW
  // ═══════════════════════════════════════════════════════════════
  /// Percentage change of this month/week vs the previous one, from the
  /// same paid-order data as the headline figure. Null when there is no
  /// previous-period income to compare with.
  ({String text, bool up})? _earningsChange(FarmoraState state) {
    final now = DateTime.now();
    final double current;
    final double previous;
    if (_showMonthlyEarnings) {
      final summary = state.earnings.summaryFor(now);
      current = summary.total;
      previous = summary.previousTotal;
    } else {
      current = state.thisWeek;
      previous = EarningsCalculator(
        state.orders,
        farmerId: state.currentUserId.isEmpty ? null : state.currentUserId,
        now: now.subtract(const Duration(days: 7)),
      ).thisWeek;
    }
    if (previous <= 0) return null;
    final pct = (current - previous) / previous * 100;
    final text = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
    return (text: text, up: pct >= 0);
  }

  Widget _buildEarningsOverview(BuildContext context, FarmoraState state) {
    final change = _earningsChange(state);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildToggleChip(
                  context.l10n.dashboardMonthly, _showMonthlyEarnings, () {
                setState(() => _showMonthlyEarnings = true);
              }),
              _buildToggleChip(
                  context.l10n.dashboardWeekly, !_showMonthlyEarnings, () {
                setState(() => _showMonthlyEarnings = false);
              }),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            AppFormat.lkr(
                _showMonthlyEarnings ? state.thisMonth : state.thisWeek,
                decimals: 2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _showMonthlyEarnings
                ? context.l10n.dashboardThisMonthEarnings
                : context.l10n.dashboardThisWeekEarnings,
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
          if (change != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                    change.up
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 16,
                    color: change.up ? AppColors.primary : AppColors.error),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _showMonthlyEarnings
                        ? context.l10n.dashboardVsLastMonth(change.text)
                        : context.l10n.dashboardVsLastWeek(change.text),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: change.up ? AppColors.primary : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      return Center(
          child: Text(context.l10n.dashboardNoData,
              style: const TextStyle(color: AppColors.onSurfaceVariant)));
    }

    final maxAmount =
        bars.map((b) => b.amount).reduce((a, b) => a > b ? a : b).toDouble();

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
                      AppFormat.lkr(bar.amount),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
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
                    color: isHighlighted
                        ? AppColors.primary
                        : const Color(0xFFC8E6C9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _monthLabel(bar.month),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isHighlighted ? FontWeight.w700 : FontWeight.w500,
                    color: isHighlighted
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
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
        child: Center(
          child: Text(context.l10n.dashboardNoRecentOrders,
              style: const TextStyle(color: AppColors.onSurfaceVariant)),
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openOrderDetail(context, order),
      child: Container(
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
                        order.title.isNotEmpty
                            ? order.title
                            : order.productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusLabel(order.status, context.l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    Expanded(
                      child: Text(
                        '${order.displayNumber} · ${order.buyerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.total > 0 || order.totalAmount.isEmpty
                          ? AppFormat.lkr(order.total, decimals: 2)
                          : order.totalAmount,
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 6. QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildQuickActions(BuildContext context, Role role) {
    final l10n = context.l10n;
    final actions = <Map<String, dynamic>>[];

    if (role == Role.farmer) {
      actions.addAll([
        {
          'icon': Icons.add_circle_outline_rounded,
          'label': l10n.dashboardAddProduce,
          'color': const Color(0xFF2E7D32),
          'bg': const Color(0xFFE8F5E9),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              ),
        },
        {
          'icon': Icons.agriculture_outlined,
          'label': 'My Farm',
          'color': const Color(0xFF33691E),
          'bg': const Color(0xFFF1F8E9),
          'onTap': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmWorkspaceScreen())),
        },
        {
          'icon': Icons.receipt_long_outlined,
          'label': l10n.dashboardManageOrders,
          'color': const Color(0xFFE65100),
          'bg': const Color(0xFFFFF3E0),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FarmerOrdersScreen()),
              ),
        },
        {
          'icon': Icons.local_offer_outlined,
          'label': l10n.dashboardPriceOffers,
          'color': const Color(0xFF6A1B9A),
          'bg': const Color(0xFFF3E5F5),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FarmerOffersScreen()),
              ),
        },
        {
          'icon': Icons.payments_outlined,
          'label': l10n.dashboardViewEarnings,
          'color': const Color(0xFF006E1C),
          'bg': const Color(0xFFE8F5E9),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EarningsScreen()),
              ),
        },
        {
          'icon': Icons.person_outline_rounded,
          'label': l10n.dashboardFarmProfile,
          'color': const Color(0xFF1565C0),
          'bg': const Color(0xFFE3F2FD),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
        },
        {
          'icon': Icons.trending_up_rounded,
          'label': l10n.dashboardMarketRates,
          'color': const Color(0xFFC2185B),
          'bg': const Color(0xFFFCE4EC),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const MarketPriceBoardScreen()),
              ),
        },
        {
          'icon': Icons.local_shipping_outlined,
          'label': l10n.deliveries,
          'color': const Color(0xFF00796B),
          'bg': const Color(0xFFE0F2F1),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FarmerJobsScreen()),
              ),
        },
        {
          'icon': Icons.near_me_rounded,
          'label': l10n.dashboardNearbyTransport,
          'color': const Color(0xFF1565C0),
          'bg': const Color(0xFFE3F2FD),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const NearbyTransportersScreen()),
              ),
        },
      ]);
    } else if (role == Role.buyer) {
      actions.addAll([
        {
          'icon': Icons.storefront_outlined,
          'label': l10n.dashboardProduce,
          'color': const Color(0xFF2E7D32),
          'bg': const Color(0xFFE8F5E9),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BuyerProductsScreen()),
              ),
        },
        {
          'icon': Icons.shopping_basket_outlined,
          'label': l10n.dashboardMyOrders,
          'color': const Color(0xFFE65100),
          'bg': const Color(0xFFFFF3E0),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BuyerOrdersScreen()),
              ),
        },
        {
          'icon': Icons.local_offer_outlined,
          'label': l10n.myOffers,
          'color': const Color(0xFF6A1B9A),
          'bg': const Color(0xFFF3E5F5),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BuyerOffersScreen()),
              ),
        },
        {
          'icon': Icons.shopping_cart_outlined,
          'label': l10n.dashboardMyCart,
          'color': const Color(0xFF006D44),
          'bg': const Color(0xFFE8F5E9),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
        },
        {
          'icon': Icons.campaign_outlined,
          'label': 'Request & Rates',
          'color': const Color(0xFF00838F),
          'bg': const Color(0xFFE0F7FA),
          'onTap': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BuyerMarketScreen())),
        },
        {
          'icon': Icons.near_me_rounded,
          'label': l10n.dashboardNearbyTransport,
          'color': const Color(0xFF1565C0),
          'bg': const Color(0xFFE3F2FD),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const NearbyTransportersScreen()),
              ),
        },
      ]);
    } else if (role == Role.transporter) {
      actions.addAll([
        {
          'icon': Icons.local_shipping_outlined,
          'label': l10n.availableJobs,
          'color': const Color(0xFF2E7D32),
          'bg': const Color(0xFFE8F5E9),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AvailableJobsScreen()),
              ),
        },
        {
          'icon': Icons.history_rounded,
          'label': l10n.deliveries,
          'color': const Color(0xFF1565C0),
          'bg': const Color(0xFFE3F2FD),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const DeliveryHistoryScreen()),
              ),
        },
        {
          'icon': Icons.payments_outlined,
          'label': l10n.earnings,
          'color': const Color(0xFF006E1C),
          'bg': const Color(0xFFE8F5E9),
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const TransporterEarningsScreen()),
              ),
        },
        {
          'icon': Icons.my_location_rounded,
          'label': l10n.dashboardLiveTracking,
          'color': const Color(0xFF00796B),
          'bg': const Color(0xFFE0F2F1),
          'onTap': () {
            final jobs = context
                .read<FarmoraState>()
                .jobs
                .where((j) => j.isActive)
                .toList();
            if (jobs.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.dashboardNoActiveDelivery),
              ));
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => ActiveDeliveryScreen(job: jobs.first)),
            );
          },
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
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
                      overflow: TextOverflow.ellipsis,
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
    final notifications = [...context.watch<FarmoraState>().notifications]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (notifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(context.l10n.noNotificationsYet),
      );
    }
    return Column(
      children: notifications.take(4).map((notification) {
        final style = switch (notification.type.toLowerCase()) {
          'order' => (Icons.shopping_cart_rounded, const Color(0xFF2E7D32)),
          'logistics' => (
              Icons.local_shipping_rounded,
              const Color(0xFF1565C0)
            ),
          'payment' => (
              Icons.account_balance_wallet_rounded,
              const Color(0xFF006E1C)
            ),
          _ => (Icons.notifications_rounded, AppColors.primary),
        };
        final time = AppFormat.relative(notification.createdAt);
        return _buildNotificationTile(_NotificationItem(
          icon: style.$1,
          iconColor: style.$2,
          iconBg: style.$2.withValues(alpha: 0.12),
          title: notification.title,
          subtitle: notification.body,
          time: time,
        ));
      }).toList(),
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
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 90),
            child: Text(
              item.time,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
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
    // Only orders that are actually moving: picked up / in transit first,
    // then confirmed / assigned ones. No fallback to an arbitrary order.
    final activeDelivery = state.orders
            .where((o) => !o.isCancelled && o.statusStep == 2)
            .firstOrNull ??
        state.orders
            .where((o) => !o.isCancelled && o.statusStep == 1)
            .firstOrNull;
    final totalSpent = state.orders
        .where((o) => !o.isCancelled)
        .fold<double>(0.0, (sum, o) => sum + o.total);

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
                  Flexible(
                    child: Text(
                      context.l10n.dashboardMarketplaceOrders,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.l10n.dashboardActiveCount(activeOrders.length),
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppFormat.lkr(totalSpent, decimals: 2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.dashboardEscrowNote,
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
                label: context.l10n.dashboardActiveOrders,
                value: AppFormat.number(activeOrders.length),
                trend: context.l10n.dashboardInProgress,
                trendUp: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.shopping_bag_rounded,
                iconColor: const Color(0xFFE65100),
                iconBg: const Color(0xFFFFF3E0),
                label: context.l10n.dashboardInCart,
                value: AppFormat.number(state.cartItemCount),
                trend: context.l10n.dashboardReadyToOrder,
                trendUp: state.cartItemCount > 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.handshake_rounded,
                iconColor: const Color(0xFF6A1B9A),
                iconBg: const Color(0xFFF3E5F5),
                label: context.l10n.dashboardOffers,
                value: AppFormat.number(state.pendingOffersCount),
                trend: context.l10n.dashboardNegotiations,
                trendUp: state.pendingOffersCount > 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // 3. Live Delivery Tracking Banner (if active delivery exists)
        if (activeDelivery != null) ...[
          _buildSectionTitle(context.l10n.dashboardActiveDelivery,
              subtitle: context.l10n.dashboardTrackProduceLive),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => openOrderDetail(context, activeDelivery),
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
                        child: const Icon(Icons.local_shipping_rounded,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeDelivery.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              context.l10n.dashboardOrderAndAddress(
                                  activeDelivery.displayNumber,
                                  activeDelivery.deliveryAddress),
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
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel(activeDelivery.status, context.l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      value: activeDelivery.statusStep / 3,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.dashboardStage(
                              statusLabel(activeDelivery.status, context.l10n)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(context.l10n.commonViewDetails,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          const Icon(Icons.chevron_right_rounded,
                              size: 16, color: AppColors.primary),
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
        _buildSectionTitle(context.l10n.dashboardQuickActions),
        const SizedBox(height: 14),
        _buildQuickActions(context, Role.buyer),
        const SizedBox(height: 32),

        // 5. Featured Produce
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.l10n.dashboardFeaturedProduce,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BuyerProductsScreen()),
              ),
              child: Text(
                context.l10n.dashboardBrowseAll,
                style: const TextStyle(
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
            child: Center(
              child: Text(context.l10n.dashboardNoProduceListed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.onSurfaceVariant)),
            ),
          )
        else
          ...products.take(4).map((product) {
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product)),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: product.imagePath != null && product.imagePath!.isNotEmpty
                            ? SafeImage(
                                path: product.imagePath!,
                                fit: BoxFit.cover,
                                width: 58,
                                height: 58,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    product.emoji.length > 2 ? product.emoji.characters.first : product.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  product.emoji.length > 2 ? product.emoji.characters.first : product.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
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
                              Expanded(
                                child: Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                              if (product.isOrganic)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    context.l10n.dashboardOrganic.toUpperCase(),
                                    style: const TextStyle(
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
                            '${districtLabel(product.location, context.l10n)} • ${product.quantity}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${AppFormat.lkr(product.pricePerUnit)} / ${_unitLabel(product.unit)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  state.addToCart(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(context.l10n
                                          .dashboardAddedToCart(product.name)),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.add_shopping_cart,
                                    size: 14),
                                label: Text(context.l10n.dashboardAdd,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
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
            Expanded(
                child: _buildOverviewCard(
              icon: Icons.local_shipping_rounded,
              iconColor: const Color(0xFF2E7D32),
              iconBg: const Color(0xFFE8F5E9),
              label: context.l10n.dashboardActiveJobs,
              value: AppFormat.number(state.jobs.length),
              trend: context.l10n.dashboardInProgress,
              trendUp: true,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _buildOverviewCard(
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF006E1C),
              iconBg: const Color(0xFFE8F5E9),
              label: context.l10n.statusCompleted,
              value: AppFormat.number(state.completedOrders.length),
              trend: context.l10n.dashboardTotalDeliveries,
              trendUp: true,
            )),
          ],
        ),
        const SizedBox(height: 32),
        _buildSectionTitle(context.l10n.dashboardQuickActions),
        const SizedBox(height: 14),
        _buildQuickActions(context, Role.transporter),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Localized unit label; units are stored in English (e.g. "kg").
  String _unitLabel(String unit) =>
      unit.trim().toLowerCase() == 'kg' ? context.l10n.unitKg : unit;

  /// Earnings bars carry an English short month ("Sep"); show it in the
  /// current language.
  String _monthLabel(String raw) {
    try {
      return AppFormat.shortMonth(DateFormat('MMM', 'en').parseStrict(raw));
    } catch (_) {
      return raw;
    }
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
