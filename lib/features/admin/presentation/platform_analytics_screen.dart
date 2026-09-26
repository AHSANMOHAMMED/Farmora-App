import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import 'admin_csv_export.dart';

class PlatformAnalyticsScreen extends StatelessWidget {
  const PlatformAnalyticsScreen({super.key});

  /// Display name for a product category (stored values stay English).
  static String _categoryLabel(AppLocalizations l, String category) =>
      switch (category.toLowerCase()) {
        '' => l.adminAnalyticsUncategorized,
        'vegetables' => l.vegetables,
        'fruits' => l.fruits,
        'spices' => l.spices,
        'grains' => l.grains,
        _ => category,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<FarmoraState>();

    final stats = state.adminStats;
    final orders = state.orders;
    final rate = state.commissionRate / 100.0;

    // Financial metrics from the loaded order stream.
    double localGmv = 0.0;
    double localCut = 0.0;
    double escrowLocked = 0.0;
    int completedCount = 0;
    int disputedCount = 0;
    int inTransitCount = 0;
    int activeOrderCount = 0;

    for (final o in orders) {
      final key = o.statusKey;
      if (o.isDisputed) disputedCount++;
      if (o.isCancelled) continue;
      activeOrderCount++;
      localGmv += o.total;
      localCut += o.platformFeeMinor > 0
          ? o.platformFee
          : (o.subtotalMinor > 0 ? o.subtotalMinor / 100.0 : o.total) * rate;
      if (key == 'completed' || key == 'delivered') {
        completedCount++;
      } else if (!o.isDisputed) {
        inTransitCount++;
      }
      if (o.paymentStatus == 'paid' && key != 'completed' && key != 'delivered') {
        escrowLocked += o.total;
      }
    }

    // Aggregate totals (adminStats) win once loaded; local values are the
    // fallback until then.
    final totalGmv = stats.isLoaded ? stats.grossVolume : localGmv;
    final totalOrders = stats.isLoaded ? stats.totalOrders : orders.length;
    final platformCut =
        stats.isLoaded && activeOrderCount < stats.totalOrders
            ? stats.grossVolume * rate
            : localCut;
    final avgOrderSize = totalOrders > 0 ? totalGmv / totalOrders : 0.0;
    final fulfillmentRate =
        orders.isNotEmpty ? completedCount / orders.length : 0.0;
    final disputeRate = orders.isNotEmpty
        ? disputedCount / orders.length
        : (stats.totalOrders > 0 ? stats.openDisputes / stats.totalOrders : 0.0);

    // User breakdown
    int roleCount(String role) => state.users
        .where((u) => (u['role'] ?? '').toString().toLowerCase() == role)
        .length;
    final farmerCount = stats.isLoaded ? stats.farmers : roleCount('farmer');
    final buyerCount = stats.isLoaded ? stats.buyers : roleCount('buyer');
    final transporterCount =
        stats.isLoaded ? stats.transporters : roleCount('transporter');
    final categories = <String, int>{};
    final regions = <String, int>{};
    for (final product in state.products.where((product) => product.isActive)) {
      final category = _categoryLabel(l, product.category.trim());
      categories.update(category, (count) => count + 1, ifAbsent: () => 1);
      final region = product.location.trim();
      if (region.isNotEmpty) {
        regions.update(region, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.adminAnalyticsTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: l.adminAnalyticsExportTooltip,
            onPressed: () => _export(
              context,
              state,
              totalGmv: totalGmv,
              platformCut: platformCut,
              escrowLocked: escrowLocked,
              totalOrders: totalOrders,
              completedCount: completedCount,
              disputedCount: disputedCount,
              inTransitCount: inTransitCount,
              farmerCount: farmerCount,
              buyerCount: buyerCount,
              transporterCount: transporterCount,
              categories: categories,
              regions: regions,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (state.adminStatsLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.adminAnalyticsGmv,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppFormat.lkr(totalGmv),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      l.adminAnalyticsEstCommission(
                          AppFormat.number(state.commissionRate, decimals: 1), AppFormat.lkr(platformCut)),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      l.adminAnalyticsAvgDeal(AppFormat.lkr(avgOrderSize)),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Secondary Financial KPI Grid
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: l.adminAnalyticsPaidUnfinished,
                  value: AppFormat.lkr(escrowLocked),
                  subtitle: l.adminAnalyticsPaidUnfinishedHint,
                  icon: Icons.shield_outlined,
                  color: const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: l.adminAnalyticsFulfillment,
                  value:
                      '${(fulfillmentRate * 100).toStringAsFixed(0)}%',
                  subtitle: l.adminAnalyticsDeliveredSafely(completedCount),
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Product listing distribution by region
          Text(
            l.adminAnalyticsByLocation,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            l.adminAnalyticsLoadedNote,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: regions.isEmpty
                    ? [Text(l.adminAnalyticsNoLocationListings)]
                    : (regions.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value)))
                        .take(5)
                        .map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RegionBar(
                                name: entry.key,
                                share: state.products.isEmpty
                                    ? 0
                                    : entry.value /
                                        state.products
                                            .where((p) => p.isActive)
                                            .length,
                                volume: l.adminAnalyticsActiveListings(
                                    entry.value),
                              ),
                            ))
                        .toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Active listings by category
          Text(
            l.adminAnalyticsByCategory,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            Text(l.adminAnalyticsNoListings)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (categories.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .map((entry) => SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 48) / 2,
                        child: _CategoryPill(
                          title: entry.key,
                          percent:
                              '${(entry.value / categories.values.fold<int>(0, (sum, count) => sum + count) * 100).toStringAsFixed(0)}%',
                          sample: l.adminAnalyticsActiveListings(entry.value),
                          icon: Icons.eco_rounded,
                          color: AppColors.primary,
                        ),
                      ))
                  .toList(),
            ),

          const SizedBox(height: 24),

          // User Ecosystem Demographics
          Text(
            l.adminAnalyticsEcosystem,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _DemographicItem(
                        label: l.adminAnalyticsFarmers,
                        count: farmerCount,
                        icon: Icons.agriculture_rounded,
                        color: AppColors.primary),
                  ),
                  Container(
                      width: 1, height: 40, color: AppColors.outlineVariant),
                  Expanded(
                    child: _DemographicItem(
                        label: l.adminAnalyticsBuyers,
                        count: buyerCount,
                        icon: Icons.storefront_rounded,
                        color: const Color(0xFF1B6BD8)),
                  ),
                  Container(
                      width: 1, height: 40, color: AppColors.outlineVariant),
                  Expanded(
                    child: _DemographicItem(
                        label: l.adminAnalyticsTransporters,
                        count: transporterCount,
                        icon: Icons.local_shipping_rounded,
                        color: const Color(0xFFE65100)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Escrow & Quality Health
          Text(
            l.adminAnalyticsTrust,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(l.adminAnalyticsDisputeRate,
                            style: const TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(disputeRate * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: disputeRate.clamp(0.0, 1.0).toDouble(),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(Colors.orange),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                            l.adminAnalyticsInTransitOrders(inTransitCount),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            l.adminAnalyticsResolvedOrders(completedCount),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (stats.fetchedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Platform totals updated ${AppFormat.dateTime(stats.fetchedAt!)} · pull down to refresh',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<FarmoraState>().refreshAdminStats();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(userMessage(e, action: 'load platform statistics'))));
    }
  }

  Future<void> _export(
    BuildContext context,
    FarmoraState state, {
    required double totalGmv,
    required double platformCut,
    required double escrowLocked,
    required int totalOrders,
    required int completedCount,
    required int disputedCount,
    required int inTransitCount,
    required int farmerCount,
    required int buyerCount,
    required int transporterCount,
    required Map<String, int> categories,
    required Map<String, int> regions,
  }) async {
    final stats = state.adminStats;
    final rows = <List<Object?>>[
      ['summary', 'generated_at', DateTime.now()],
      ['summary', 'stats_fetched_at', stats.fetchedAt],
      ['summary', 'gross_volume_lkr', totalGmv.toStringAsFixed(2)],
      ['summary', 'commission_rate_percent', state.commissionRate],
      ['summary', 'platform_cut_lkr', platformCut.toStringAsFixed(2)],
      ['summary', 'escrow_locked_lkr', escrowLocked.toStringAsFixed(2)],
      ['summary', 'total_orders', totalOrders],
      ['summary', 'loaded_orders', state.orders.length],
      ['summary', 'completed_orders', completedCount],
      ['summary', 'disputed_orders', disputedCount],
      ['summary', 'in_progress_orders', inTransitCount],
      ['summary', 'open_disputes', stats.openDisputes],
      ['users', 'total', stats.isLoaded ? stats.totalUsers : state.users.length],
      ['users', 'farmers', farmerCount],
      ['users', 'buyers', buyerCount],
      ['users', 'transporters', transporterCount],
      if (stats.isLoaded) ['users', 'admins', stats.admins],
      for (final e in categories.entries) ['listings_by_category', e.key, e.value],
      for (final e in regions.entries) ['listings_by_location', e.key, e.value],
    ];
    final csv = buildCsv(const ['section', 'metric', 'value'], rows);
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    await exportCsv(context,
        fileName: 'farmora_analytics_$stamp.csv', csv: csv);
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              radius: 18,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _RegionBar extends StatelessWidget {
  final String name;
  final double share;
  final String volume;

  const _RegionBar({
    required this.name,
    required this.share,
    required this.volume,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Text('${(share * 100).toInt()}%',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: share,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(height: 2),
        Text(volume,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String title;
  final String percent;
  final String sample;
  final IconData icon;
  final Color color;

  const _CategoryPill({
    required this.title,
    required this.percent,
    required this.sample,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Text(percent,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _DemographicItem extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _DemographicItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          radius: 18,
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(AppFormat.number(count),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
