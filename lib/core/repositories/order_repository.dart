import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> getBuyerOrders(String buyerId);
  Future<List<OrderModel>> getFarmerOrders(String farmerId);
  Future<OrderModel?> getOrderById(String id);
  Future<void> createOrder(OrderModel order);
  Future<void> updateOrderStatus(String id, OrderStatus status);
}

class MockOrderRepository implements OrderRepository {
  final List<OrderModel> _orders = [];

  @override
  Future<List<OrderModel>> getBuyerOrders(String buyerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _orders.where((o) => o.buyerId == buyerId).toList();
  }

  @override
  Future<List<OrderModel>> getFarmerOrders(String farmerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _orders.where((o) => o.farmerId == farmerId).toList();
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createOrder(OrderModel order) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _orders.add(order);
  }

  @override
  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      final oldOrder = _orders[index];
      // Since OrderModel doesn't have a copyWith, we'll manually copy
      _orders[index] = OrderModel(
        id: oldOrder.id,
        buyerId: oldOrder.buyerId,
        farmerId: oldOrder.farmerId,
        transporterId: oldOrder.transporterId,
        items: oldOrder.items,
        subtotalMinor: oldOrder.subtotalMinor,
        deliveryFeeMinor: oldOrder.deliveryFeeMinor,
        totalMinor: oldOrder.totalMinor,
        currency: oldOrder.currency,
        deliveryAddress: oldOrder.deliveryAddress,
        pickupAddress: oldOrder.pickupAddress,
        status: status, // updated status
        paymentStatus: oldOrder.paymentStatus,
        createdAt: oldOrder.createdAt,
        updatedAt: DateTime.now(),
        deliveredAt: status == OrderStatus.delivered ? DateTime.now() : oldOrder.deliveredAt,
      );
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return MockOrderRepository();
});
