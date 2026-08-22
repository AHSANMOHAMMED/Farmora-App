import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/order.dart';

class DemoOrderNotifier extends StateNotifier<List<OrderModel>> {
  DemoOrderNotifier() : super(_demoOrders);
}

final demoOrdersProvider =
    StateNotifierProvider<DemoOrderNotifier, List<OrderModel>>((ref) {
  return DemoOrderNotifier();
});

final _demoOrders = <OrderModel>[
  const OrderModel(
    id: 'ord-1',
    buyerId: 'buyer-1',
    farmerId: 'farmer-1',
    transporterId: 'transporter-1',
    items: [
      OrderItem(
        productId: 'prod-1',
        productName: 'Organic Tomatoes',
        quantity: 20,
        unit: 'kg',
        pricePerUnitMinor: 420,
        subtotalMinor: 8400,
      ),
    ],
    subtotalMinor: 8400,
    deliveryFeeMinor: 1500,
    totalMinor: 9900,
    currency: 'LKR',
    status: OrderStatus.inTransit,
    deliveryAddress: 'Colombo 07',
    pickupAddress: 'Nuwara Eliya',
  ),
  const OrderModel(
    id: 'ord-2',
    buyerId: 'buyer-1',
    farmerId: 'farmer-1',
    items: [
      OrderItem(
        productId: 'prod-2',
        productName: 'Cavendish Bananas',
        quantity: 15,
        unit: 'kg',
        pricePerUnitMinor: 280,
        subtotalMinor: 4200,
      ),
    ],
    subtotalMinor: 4200,
    totalMinor: 4200,
    currency: 'LKR',
    status: OrderStatus.delivered,
  ),
];
