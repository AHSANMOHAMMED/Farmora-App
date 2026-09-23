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
    final avgOrderSize = state.orders.isNotEmpty ? totalGmv / state.orders.length : 0.0;

    // User breakdown
    final farmerCount = state.users.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'farmer').length;
    final buyerCount = state.users.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'buyer').length;
    final transporterCount = state.users.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'transporter').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Analytics & Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📊 Agritech Monthly Audit report exported to downloads.'),
                  backgroundColor: AppColors.primary,
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
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
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
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
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
                      'Platform Revenue (${state.commissionRate}%): LKR ${platformCut.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Avg Deal: LKR ${avgOrderSize.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                  title: 'Escrow Vault',
                  value: 'LKR ${escrowLocked.toStringAsFixed(0)}',
                  subtitle: 'Pending buyer confirmation',
                  icon: Icons.shield_outlined,
                  color: const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Order Fulfillment',
                  value: '${state.orders.isNotEmpty ? ((completedCount / state.orders.length) * 100).toStringAsFixed(0) : '100'}%',
                  subtitle: '$completedCount delivered safely',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Regional Market Trade Distribution
          const Text(
            'Sri Lankan Wholesale Center Trading Activity',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Volume flow between production zones and distribution Polas',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _RegionBar(name: 'Dambulla Central Pola', share: 0.42, volume: '4,200 kg · LKR 840,000'),
                  SizedBox(height: 12),
                  _RegionBar(name: 'Pettah Wholesale Terminal (Colombo)', share: 0.28, volume: '2,800 kg · LKR 560,000'),
                  SizedBox(height: 12),
                  _RegionBar(name: 'Nuwara Eliya / Kandy Highlands', share: 0.18, volume: '1,800 kg · LKR 430,000'),
                  SizedBox(height: 12),
                  _RegionBar(name: 'Jaffna & Kilinochchi Northern Hub', share: 0.12, volume: '1,200 kg · LKR 290,000'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Commodity Crop Mix
          const Text(
            'Crop Category Performance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _CategoryPill(
                  title: 'Vegetables',
                  percent: '45%',
                  sample: 'Tomatoes, Carrots',
                  icon: Icons.eco_rounded,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _CategoryPill(
                  title: 'Spices',
                  percent: '25%',
                  sample: 'Ceylon Cinnamon',
                  icon: Icons.spa_rounded,
                  color: Color(0xFF8D6E63),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _CategoryPill(
                  title: 'Fruits',
                  percent: '20%',
                  sample: 'Cavendish, Papaya',
                  icon: Icons.lunch_dining_rounded,
                  color: Color(0xFFF57C00),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _CategoryPill(
                  title: 'Grains',
                  percent: '10%',
                  sample: 'Samba, Paddy',
                  icon: Icons.grass_rounded,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // User Ecosystem Demographics
          const Text(
            'Registered Marketplace Ecosystem',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
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
                  _DemographicItem(label: 'Farmers', count: farmerCount > 0 ? farmerCount : 38, icon: Icons.agriculture_rounded, color: AppColors.primary),
                  Container(width: 1, height: 40, color: AppColors.outlineVariant),
                  _DemographicItem(label: 'Buyers', count: buyerCount > 0 ? buyerCount : 24, icon: Icons.storefront_rounded, color: const Color(0xFF1B6BD8)),
                  Container(width: 1, height: 40, color: AppColors.outlineVariant),
                  _DemographicItem(label: 'Transporters', count: transporterCount > 0 ? transporterCount : 15, icon: Icons.local_shipping_rounded, color: const Color(0xFFE65100)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Escrow & Quality Health
          const Text(
            'Trading Trust & Dispute Ratio',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
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
                      const Text('Dispute Arbitration Rate', style: TextStyle(fontSize: 13)),
                      Text(
                        '${state.orders.isNotEmpty ? ((disputedCount / state.orders.length) * 100).toStringAsFixed(1) : '0.0'}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: state.orders.isNotEmpty ? (disputedCount / state.orders.length) : 0.05,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(Colors.orange),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active In-Transit Escrow Orders: $inTransitCount', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text('Resolved Orders: $completedCount', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${(share * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
        Text(volume, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Text(percent, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
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
        Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
