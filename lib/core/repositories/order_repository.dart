import '../models/order.dart';

/// Abstract interface for order management operations.
abstract class OrderRepository {
  /// Get order by ID
  Future<OrderModel?> getOrderById(String orderId);

  /// Create a new order
  Future<OrderModel> createOrder(OrderModel order);

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status);

  /// Get orders for a buyer
  Future<List<OrderModel>> getOrdersByBuyer(String buyerId);

  /// Get orders for a farmer
  Future<List<OrderModel>> getOrdersByFarmer(String farmerId);

  /// Get orders for a transporter
  Future<List<OrderModel>> getOrdersByTransporter(String transporterId);

  /// Stream orders for real-time updates
  Stream<List<OrderModel>> watchOrdersByBuyer(String buyerId);

  /// Stream orders for real-time updates
  Stream<List<OrderModel>> watchOrdersByFarmer(String farmerId);

  /// Assign transporter to order
  Future<void> assignTransporter(String orderId, String transporterId);

  /// Cancel order
  Future<void> cancelOrder(String orderId);

  /// Calculate order total server-side (via Cloud Function in production)
  Future<int> calculateOrderTotal(List<OrderItem> items, int deliveryFee);
}
