import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import 'user_management_screen.dart';
import 'logistics_management_screen.dart';
import 'system_settings_screen.dart';
import '../../../../theme/app_colors.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          bottom: const TabBar(
            isScrollable: true,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
              Tab(text: 'Users', icon: Icon(Icons.people_outline)),
              Tab(text: 'Logistics', icon: Icon(Icons.local_shipping_outlined)),
              Tab(text: 'Settings', icon: Icon(Icons.settings_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCardsRow(state),
          const SizedBox(height: 24),
          const Text('Recent Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: AppColors.surfaceContainerLowest,
            child: recentActivities.isEmpty 
              ? const Padding(padding: EdgeInsets.all(16), child: Text('No recent activities.'))
              : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentActivities.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = recentActivities[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child: Icon(Icons.notifications_outlined, color: AppColors.primary),
                  ),
                  title: Text('Order ${tx.orderNumber} completed'),
                  subtitle: Text(tx.date),
                  trailing: Text('\$${tx.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCardsRow(FarmoraState state) {
    return Row(
      children: [
        Expanded(child: _StatCard(title: 'Total Users', value: '${state.users.length}', icon: Icons.group, color: Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(title: 'Active Orders', value: '${state.orders.length}', icon: Icons.shopping_bag, color: Colors.green)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: color.withOpacity(0.8), fontSize: 14)),
        ],
      ),
    );
  }
}
