import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/order.dart';
import '../../../core/widgets/order_card.dart';
import '../../../core/widgets/async_state_handler.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: AsyncStateHandler(
        value: ordersAsync,
        dataBuilder: (context, orders) {
          if (orders.isEmpty) {
             return const EmptyStateWidget(
               icon: Icons.receipt_long_outlined,
               title: 'No orders yet',
               subtitle: 'When you buy or sell products, they will appear here.',
             );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Track every step from farm to table.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ...orders.map(
                (o) {
                  final title = o.items.isNotEmpty ? o.items.first.productName : 'Order';
                  final detail = o.items.isNotEmpty
                      ? '${o.items.first.quantity} ${o.items.first.unit} · ${o.displayTotal}'
                      : o.displayTotal;

                  Color statusColor = Colors.orange;
                  if (o.status == OrderStatus.delivered) {
                    statusColor = Colors.green;
                  } else if (o.status == OrderStatus.cancelled || o.status == OrderStatus.rejected) {
                    statusColor = Colors.red;
                  } else if (o.status == OrderStatus.inTransit || o.status == OrderStatus.pickedUp) {
                    statusColor = Colors.blue;
                  }

                  return OrderCard(
                    title: title,
                    detail: detail,
                    status: o.status.label,
                    color: statusColor,
                    progress: o.status.progress,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Alias for backward compatibility
typedef Orders = OrdersScreen;
