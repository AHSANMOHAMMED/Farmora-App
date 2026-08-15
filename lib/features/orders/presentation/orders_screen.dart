import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/farmora_state.dart';
import '../../../core/widgets/order_card.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Track every step from farm to table.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ...state.orders.map(
            (o) => OrderCard(
              title: o.title,
              detail: o.detail,
              status: o.status,
              color: o.color,
              progress: o.progress,
            ),
          ),
        ],
      ),
    );
  }
}

/// Alias for backward compatibility
typedef Orders = OrdersScreen;
