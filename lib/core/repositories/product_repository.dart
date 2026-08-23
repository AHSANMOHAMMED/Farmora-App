import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts();
  Future<List<ProductModel>> getFarmerProducts(String farmerId);
  Future<ProductModel?> getProductById(String id);
  Future<void> createProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
}

class MockProductRepository implements ProductRepository {
  final List<ProductModel> _products = [];

  MockProductRepository() {
    _products.addAll([
      const ProductModel(
        id: '1',
        farmerId: 'demo-farmer',
        name: 'Organic Tomatoes',
        category: ProductCategory.vegetables,
        description: 'Fresh organic tomatoes directly from the farm.',
        quantityAvailable: 100,
        unit: 'kg',
        priceMinor: 25000, // 250.00 Rs
        currency: 'LKR',
        location: 'Nuwara Eliya',
      ),
      const ProductModel(
        id: '2',
        farmerId: 'demo-farmer',
        name: 'Carrots',
        category: ProductCategory.vegetables,
        description: 'Fresh carrots directly from the farm.',
        quantityAvailable: 50,
        unit: 'kg',
        priceMinor: 15000, // 150.00 Rs
        currency: 'LKR',
        location: 'Matale',
      ),
      const ProductModel(
        id: '3',
        farmerId: 'other-farmer',
        name: 'Cabbage',
        category: ProductCategory.vegetables,
        description: 'Fresh cabbage.',
        quantityAvailable: 80,
        unit: 'kg',
        priceMinor: 12000, // 120.00 Rs
        currency: 'LKR',
        location: 'Badulla',
      ),
    ]);
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_products);
  }

  @override
  Future<List<ProductModel>> getFarmerProducts(String farmerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _products.where((p) => p.farmerId == farmerId).toList();
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createProduct(ProductModel product) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _products.add(product);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _products.removeWhere((p) => p.id == id);
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return MockProductRepository();
});
