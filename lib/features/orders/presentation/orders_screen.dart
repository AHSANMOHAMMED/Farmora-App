import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/farmora_state.dart';
import '../../../core/widgets/order_card.dart';
import '../../../core/localization/l10n.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.orders),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l.ordersTrackEveryStep,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ...state.orders.map(
            (o) => OrderCard(
              title: o.title,
              detail: o.detail.isNotEmpty
                  ? '${o.displayNumber} · ${o.detail}'
                  : o.displayNumber,
              status: o.statusKey,
              color: o.color,
              // Progress from the normalised lifecycle step (0..3).
              progress: o.isCancelled ? 0 : o.statusStep / 3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Alias for backward compatibility
typedef Orders = OrdersScreen;
