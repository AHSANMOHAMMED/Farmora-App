import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import 'user_management_screen.dart';
import 'verification_review_screen.dart';
import 'market_price_management_screen.dart';
import 'dispute_resolution_screen.dart';
import 'broadcast_advisory_screen.dart';
import 'platform_analytics_screen.dart';
import 'review_management_screen.dart';
import 'server_maintenance_screen.dart';
import 'settlement_management_screen.dart';
import 'logistics_management_screen.dart';
import 'audit_log_screen.dart';
import 'market_price_review_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 12,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.adminDashTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: l.adminDashTabOverview, icon: const Icon(Icons.dashboard_rounded, size: 20)),
              Tab(text: l.adminDashTabAnalytics, icon: const Icon(Icons.insights_rounded, size: 20)),
              Tab(text: l.adminDashTabUsers, icon: const Icon(Icons.people_alt_rounded, size: 20)),
              Tab(text: l.adminDashTabReviews, icon: const Icon(Icons.rate_review_rounded, size: 20)),
              Tab(text: l.adminDashTabTreasury, icon: const Icon(Icons.account_balance_wallet_rounded, size: 20)),
              Tab(text: l.adminDashTabDisputes, icon: const Icon(Icons.gavel_rounded, size: 20)),
              Tab(text: l.adminDashTabFleet, icon: const Icon(Icons.local_shipping_rounded, size: 20)),
              Tab(text: l.adminDashTabMarket, icon: const Icon(Icons.trending_up_rounded, size: 20)),
              const Tab(text: 'Price Reports', icon: Icon(Icons.fact_check_outlined, size: 20)),
              Tab(text: l.adminDashTabAudit, icon: const Icon(Icons.shield_rounded, size: 20)),
              Tab(text: l.adminDashTabServer, icon: const Icon(Icons.cloud_sync_rounded, size: 20)),
              Tab(text: l.adminDashTabAdvisories, icon: const Icon(Icons.campaign_rounded, size: 20)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            PlatformAnalyticsScreen(),
            UserManagementScreen(),
            ReviewManagementScreen(),
            SettlementManagementScreen(),
            DisputeResolutionScreen(),
            LogisticsManagementScreen(),
            MarketPriceManagementScreen(),
            MarketPriceReviewScreen(),
            AuditLogScreen(),
            ServerMaintenanceScreen(),
            BroadcastAdvisoryScreen(),
          ],
        ),
      ),
    );
  }
}

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.adminDashTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: const _OverviewTab(),
    );
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.read<FarmoraState>().adminStats.isLoaded) _refresh();
    });
  }

  Future<void> _refresh() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<FarmoraState>().refreshAdminStats();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(userMessage(e, action: 'load platform statistics'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<FarmoraState>();
    final stats = state.adminStats;
    final recentActivities = state.transactions.take(5).toList();

    // Platform totals come from the aggregate queries (adminStats); the
    // loaded order stream is the fallback before they arrive.
    final activeOrders =
        state.orders.where((o) => !o.isCancelled).toList();
    double localGmv = 0.0;
    double localCut = 0.0;
    double escrowHeld = 0.0;
    final rate = state.commissionRate / 100.0;
    for (final o in activeOrders) {
      localGmv += o.total;
      localCut += o.platformFeeMinor > 0
          ? o.platformFee
          : (o.subtotalMinor > 0 ? o.subtotalMinor / 100.0 : o.total) * rate;
      final key = o.statusKey;
      if (o.paymentStatus == 'paid' && key != 'completed' && key != 'delivered') {
        escrowHeld += o.total;
      }
    }
    final platformGmv = stats.isLoaded ? stats.grossVolume : localGmv;
    final totalOrders = stats.isLoaded ? stats.totalOrders : state.orders.length;
    // Per-order fees where the order list is complete; otherwise apply the
    // configured commission rate to the aggregate volume.
    final platformCommission =
        stats.isLoaded && activeOrders.length < stats.totalOrders
            ? stats.grossVolume * rate
            : localCut;
    final registeredUsers =
        stats.isLoaded ? stats.totalUsers : state.users.length;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.adminStatsLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          // Row 1: Financial & Platform KPIs
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: l.adminDashGmv,
                  value: AppFormat.lkr(platformGmv),
                  subtitle: l.adminDashTotalTrades(totalOrders),
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFF1B6BD8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  title: l.adminDashPlatformCut,
                  value: AppFormat.lkr(platformCommission),
                  subtitle: '${l.adminDashEarnedCommission} · ${AppFormat.number(state.commissionRate, decimals: 1)}%',
                  icon: Icons.savings_rounded,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: l.adminDashEscrowLocked,
                  value: AppFormat.lkr(escrowHeld),
                  subtitle: l.adminDashPendingBuyerDelivery,
                  icon: Icons.lock_clock_rounded,
                  color: const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  title: l.adminDashRegisteredUsers,
                  value: AppFormat.number(registeredUsers),
                  subtitle: l.adminDashPendingKyc(state.verificationDocs.where((d) => d.status.toString().contains('pending')).length),
                  icon: Icons.supervised_user_circle_rounded,
                  color: const Color(0xFF6A1B9A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Action Hub
          Text(
            l.adminDashQuickHub,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.insights_rounded,
                  label: l.adminDashTabAnalytics,
                  color: const Color(0xFF1B6BD8),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlatformAnalyticsScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.rate_review_rounded,
                  label: l.adminDashTabReviews,
                  color: Colors.amber.shade800,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReviewManagementScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.cloud_sync_rounded,
                  label: l.adminDashServerOps,
                  color: Colors.teal.shade700,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ServerMaintenanceScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.verified_user_rounded,
                  label: l.adminDashReviewKyc,
                  color: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VerificationReviewScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.trending_up_rounded,
                  label: l.adminDashPolaRates,
                  color: const Color(0xFF2E7D32),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MarketPriceManagementScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.campaign_rounded,
                  label: l.adminDashBroadcast,
                  color: const Color(0xFFE65100),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BroadcastAdvisoryScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.account_balance_wallet_rounded,
                  label: l.adminDashTreasuryPayouts,
                  color: const Color(0xFF2E7D32),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettlementManagementScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.local_shipping_rounded,
                  label: l.adminDashTabFleet,
                  color: const Color(0xFF1B6BD8),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogisticsManagementScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.shield_rounded,
                  label: l.adminDashTabAudit,
                  color: const Color(0xFF5E35B1),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuditLogScreen()),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Escrow Release Section
          Text(l.adminDashEscrowReleases,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _EscrowReleaseSection(),

          const SizedBox(height: 24),

          // Recent Activities
          Text(l.adminDashRecentActivities,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            color: Colors.white,
            child: recentActivities.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(l.adminDashNoRecentActivities, style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentActivities.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = recentActivities[index];
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                          ),
                          title: Text(
                            l.adminDashOrderCompleted(tx.orderNumber),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(tx.date, style: const TextStyle(fontSize: 12)),
                          trailing: Text(
                            AppFormat.lkr(tx.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (stats.fetchedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Totals updated ${AppFormat.dateTime(stats.fetchedAt!)} · pull down to refresh',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _EscrowReleaseSection extends StatefulWidget {
  @override
  State<_EscrowReleaseSection> createState() => _EscrowReleaseSectionState();
}

class _EscrowReleaseSectionState extends State<_EscrowReleaseSection> {
  final Set<String> _releasing = {};

  Future<void> _release(String orderId) async {
    if (_releasing.contains(orderId)) return;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final state = context.read<FarmoraState>();
    setState(() => _releasing.add(orderId));
    try {
      await state.releaseEscrow(orderId);
      messenger.showSnackBar(SnackBar(content: Text(l.adminDashEscrowReleased)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.adminDashReleaseFailed(
              userMessage(e, action: 'release escrow'))),
        ),
      );
    } finally {
      if (mounted) setState(() => _releasing.remove(orderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<FarmoraState>();
    final eligible = state.orders
        .where((o) =>
            o.statusKey == 'delivered' &&
            o.paymentStatus == 'paid' &&
            (o.disputeId == null || o.disputeId!.isEmpty))
        .toList();

    if (eligible.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l.adminDashNoEscrowPending,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: eligible.map((o) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.outlineVariant),
          ),
          color: Colors.white,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              title: Text(
                o.productName.isNotEmpty ? o.productName : o.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text('${o.displayNumber} · ${o.displayTotal} · ${l.statusDelivered}'),
              trailing: FilledButton(
                onPressed:
                    _releasing.contains(o.id) ? null : () => _release(o.id),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
                child: _releasing.contains(o.id)
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.release),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
