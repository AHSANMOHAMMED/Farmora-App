import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';

/// Firestore-backed implementation of [OrderRepository].
class FirestoreOrderRepository implements OrderRepository {
  final FirebaseFirestore _db;

  FirestoreOrderRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');

  @override
  Future<List<OrderModel>> getBuyerOrders(String buyerId) async {
    final snapshot = await _orders
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return OrderModel.fromJson(data);
    }).toList();
  }

  @override
  Future<List<OrderModel>> getFarmerOrders(String farmerId) async {
    final snapshot = await _orders
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return OrderModel.fromJson(data);
    }).toList();
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    final doc = await _orders.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return OrderModel.fromJson(data);
  }

  @override
  Future<void> createOrder(OrderModel order) async {
    final data = order.toJson();
    data.remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _orders.doc(order.id).set(data);
  }

  @override
  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    await _orders.doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == OrderStatus.delivered) 'deliveredAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Provider that gives the Firestore-backed order repository.
final firestoreOrderRepositoryProvider = Provider<OrderRepository>((ref) {
  return FirestoreOrderRepository(FirebaseFirestore.instance);
});
