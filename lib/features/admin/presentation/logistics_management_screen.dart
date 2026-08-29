import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';

class LogisticsManagementScreen extends StatelessWidget {
  const LogisticsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final activeDeliveries = state.orders.where((o) => o.status == 'In transit' || o.status == 'Pending').toList();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Active Deliveries', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (activeDeliveries.isEmpty)
            const Center(child: Text('No active deliveries.'))
          else
            ...activeDeliveries.map((order) {
              return _buildDeliveryTile(
                order.orderNumber, 
                order.status, 
                'Buyer: ${order.buyerName}'
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDeliveryTile(String orderId, String status, String subtitle) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.local_shipping, color: AppColors.onPrimaryContainer),
        ),
        title: Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Text(status, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
