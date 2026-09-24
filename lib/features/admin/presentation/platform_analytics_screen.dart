import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import '../../../core/constants/app_colors.dart';

class PlatformAnalyticsScreen extends StatelessWidget {
  const PlatformAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();

    // Calculate Financial metrics
    double totalGmv = 0.0;
    double escrowLocked = 0.0;
    int completedCount = 0;
    int disputedCount = 0;
    int inTransitCount = 0;

    for (final o in state.orders) {
      totalGmv += o.total;
      final st = o.status.toLowerCase();
      if (st == 'completed' || st == 'delivered') {
        completedCount++;
      } else if (st == 'disputed') {
        disputedCount++;
      } else {
        inTransitCount++;
      }
      if (o.paymentStatus == 'paid' && st != 'completed' && st != 'delivered') {
        escrowLocked += o.total;
      }
    }

    final platformCut = totalGmv * (state.commissionRate / 100.0);
    final avgOrderSize =
        state.orders.isNotEmpty ? totalGmv / state.orders.length : 0.0;

    // User breakdown
    final farmerCount = state.users
        .where((u) => (u['role'] ?? '').toString().toLowerCase() == 'farmer')
        .length;
    final buyerCount = state.users
        .where((u) => (u['role'] ?? '').toString().toLowerCase() == 'buyer')
        .length;
    final transporterCount = state.users
        .where(
            (u) => (u['role'] ?? '').toString().toLowerCase() == 'transporter')
        .length;
    final categories = <String, int>{};
    final regions = <String, int>{};
    for (final product in state.products.where((product) => product.isActive)) {
      final category = product.category.trim().isEmpty
          ? 'Uncategorized'
          : product.category.trim();
      categories.update(category, (count) => count + 1, ifAbsent: () => 1);
      final region = product.location.trim();
      if (region.isNotEmpty) {
        regions.update(region, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Analytics & Insights',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report export is not available yet.'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                const Row(
                  children: [
                    Icon(Icons.insights_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Gross Merchandise Value (GMV)',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'LKR ${totalGmv.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Est. commission (${state.commissionRate}%): LKR ${platformCut.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Avg Deal: LKR ${avgOrderSize.toStringAsFixed(0)}',
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
                  title: 'Paid, unfinished',
                  value: 'LKR ${escrowLocked.toStringAsFixed(0)}',
                  subtitle: 'Order value; provider balance unverified',
                  icon: Icons.shield_outlined,
                  color: const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Order Fulfillment',
                  value:
                      '${state.orders.isNotEmpty ? ((completedCount / state.orders.length) * 100).toStringAsFixed(0) : '0'}%',
                  subtitle: '$completedCount delivered safely',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Product listing distribution by region
          const Text(
            'Active Listings by Product Location',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Counts are based on the currently loaded active listings.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                    ? const [
                        Text('No active listings with a location are loaded.')
                      ]
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
                                volume:
                                    '${entry.value} active ${entry.value == 1 ? 'listing' : 'listings'}',
                              ),
                            ))
                        .toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Active listings by category
          const Text(
            'Active Listings by Category',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            const Text('No active listings are loaded.')
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
                          sample:
                              '${entry.value} active ${entry.value == 1 ? 'listing' : 'listings'}',
                          icon: Icons.eco_rounded,
                          color: AppColors.primary,
                        ),
                      ))
                  .toList(),
            ),

          const SizedBox(height: 24),

          // User Ecosystem Demographics
          const Text(
            'Registered Marketplace Ecosystem',
            style: TextStyle(
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
                  _DemographicItem(
                      label: 'Farmers',
                      count: farmerCount,
                      icon: Icons.agriculture_rounded,
                      color: AppColors.primary),
                  Container(
                      width: 1, height: 40, color: AppColors.outlineVariant),
                  _DemographicItem(
                      label: 'Buyers',
                      count: buyerCount,
                      icon: Icons.storefront_rounded,
                      color: const Color(0xFF1B6BD8)),
                  Container(
                      width: 1, height: 40, color: AppColors.outlineVariant),
                  _DemographicItem(
                      label: 'Transporters',
                      count: transporterCount,
                      icon: Icons.local_shipping_rounded,
                      color: const Color(0xFFE65100)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Escrow & Quality Health
          const Text(
            'Trading Trust & Dispute Ratio',
            style: TextStyle(
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
                      const Text('Dispute Arbitration Rate',
                          style: TextStyle(fontSize: 13)),
                      Text(
                        '${state.orders.isNotEmpty ? ((disputedCount / state.orders.length) * 100).toStringAsFixed(1) : '0.0'}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: state.orders.isNotEmpty
                          ? (disputedCount / state.orders.length)
                          : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(Colors.orange),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active In-Transit Escrow Orders: $inTransitCount',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text('Resolved Orders: $completedCount',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
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
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value,
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
            Text(name,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
        Text('$count',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
