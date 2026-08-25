import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

/// Firestore-backed implementation of [ProductRepository].
class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore _db;

  FirestoreProductRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');

  @override
  Future<List<ProductModel>> getProducts() async {
    final snapshot = await _products.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ProductModel.fromJson(data);
    }).toList();
  }

  @override
  Future<List<ProductModel>> getFarmerProducts(String farmerId) async {
    final snapshot = await _products
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ProductModel.fromJson(data);
    }).toList();
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final doc = await _products.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return ProductModel.fromJson(data);
  }

  @override
  Future<void> createProduct(ProductModel product) async {
    final data = product.toJson();
    data.remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _products.doc(product.id).set(data);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final data = product.toJson();
    data.remove('id');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _products.doc(product.id).update(data);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }
}

/// Provider that gives the Firestore-backed product repository.
final firestoreProductRepositoryProvider = Provider<ProductRepository>((ref) {
  return FirestoreProductRepository(FirebaseFirestore.instance);
});
