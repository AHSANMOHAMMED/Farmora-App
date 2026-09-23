import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';
import 'user_management_screen.dart';
import 'logistics_management_screen.dart';
import 'system_settings_screen.dart';
import 'verification_review_screen.dart';
import 'market_price_management_screen.dart';
import 'dispute_resolution_screen.dart';
import 'broadcast_advisory_screen.dart';
import '../../../core/constants/app_colors.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Operations Control',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Overview', icon: Icon(Icons.dashboard_rounded, size: 20)),
              Tab(text: 'Disputes & Escrow', icon: Icon(Icons.gavel_rounded, size: 20)),
              Tab(text: 'Market Rates', icon: Icon(Icons.trending_up_rounded, size: 20)),
              Tab(text: 'Advisories', icon: Icon(Icons.campaign_rounded, size: 20)),
              Tab(text: 'Users & KYC', icon: Icon(Icons.people_alt_rounded, size: 20)),
              Tab(text: 'Fleet Logistics', icon: Icon(Icons.local_shipping_rounded, size: 20)),
              Tab(text: 'Settings', icon: Icon(Icons.tune_rounded, size: 20)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            DisputeResolutionScreen(),
            MarketPriceManagementScreen(),
            BroadcastAdvisoryScreen(),
            UserManagementScreen(),
            LogisticsManagementScreen(),
            SystemSettingsScreen(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final recentActivities = state.transactions.take(5).toList();

    // Calculate Platform GMV, Commission, and Escrow
    double platformGmv = 0.0;
    double escrowHeld = 0.0;
    for (final o in state.orders) {
      platformGmv += o.total;
      if (o.paymentStatus == 'paid' && o.status.toLowerCase() != 'completed' && o.status.toLowerCase() != 'delivered') {
        escrowHeld += o.total;
      }
    }
    final platformCommission = platformGmv * 0.05; // 500 bps default

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Financial & Platform KPIs
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'Platform GMV',
                  value: 'LKR ${platformGmv.toStringAsFixed(0)}',
                  subtitle: '${state.orders.length} total trades',
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFF1B6BD8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  title: 'Platform Cut (5%)',
                  value: 'LKR ${platformCommission.toStringAsFixed(0)}',
                  subtitle: 'Earned commission',
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
                  title: 'Escrow Locked',
                  value: 'LKR ${escrowHeld.toStringAsFixed(0)}',
                  subtitle: 'Pending buyer delivery',
                  icon: Icons.lock_clock_rounded,
                  color: const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  title: 'Registered Users',
                  value: '${state.users.length}',
                  subtitle: '${state.verificationDocs.where((d) => d.status.toString().contains('pending')).length} pending KYC',
                  icon: Icons.supervised_user_circle_rounded,
                  color: const Color(0xFF6A1B9A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Action Hub
          const Text(
            'Quick Operations Hub',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.verified_user_rounded,
                  label: 'Review KYC',
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
                  label: 'Pola Rates',
                  color: const Color(0xFF1B6BD8),
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
                  label: 'Broadcast',
                  color: const Color(0xFFE65100),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BroadcastAdvisoryScreen()),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Escrow Release Section
          const Text('Escrow Releases',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _EscrowReleaseSection(),

          const SizedBox(height: 24),

          // Recent Activities
          const Text('Recent Platform Activities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            color: Colors.white,
            child: recentActivities.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No recent activities.', style: TextStyle(color: AppColors.textSecondary)),
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
                            'Order ${tx.orderNumber} completed',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(tx.date, style: const TextStyle(fontSize: 12)),
                          trailing: Text(
                            'LKR ${tx.amount.toStringAsFixed(0)}',
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
        ],
      ),
    );
  }
}

class _EscrowReleaseSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final eligible = state.orders
        .where((o) =>
            o.status.toLowerCase() == 'delivered' &&
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
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No delivered orders pending escrow release at this time.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
              subtitle: Text('${o.orderNumber} · ${o.displayTotal} · Delivered'),
              trailing: FilledButton(
                onPressed: () async {
                  try {
                    await FirestoreService().releaseEscrow(orderId: o.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Escrow released to farmer successfully')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Release failed: $e')),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Release'),
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
              Text(
                title,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
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
