import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/product.dart';

/// Demo product data that matches the existing hardcoded state.
/// This will be replaced with Firestore-backed providers once Firebase is connected.
class DemoProductNotifier extends StateNotifier<List<ProductModel>> {
  DemoProductNotifier() : super(_demoProducts);

  void addProduct(ProductModel product) {
    state = [product, ...state];
  }

  void removeProduct(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void updateProduct(ProductModel updated) {
    state = state.map((p) => p.id == updated.id ? updated : p).toList();
  }
}

final demoProductsProvider =
    StateNotifierProvider<DemoProductNotifier, List<ProductModel>>((ref) {
  return DemoProductNotifier();
});

final _demoProducts = <ProductModel>[
  const ProductModel(
    id: 'prod-1',
    farmerId: 'farmer-1',
    name: 'Organic Tomatoes',
    category: ProductCategory.vegetables,
    description: 'Fresh organic tomatoes from Nuwara Eliya highlands',
    quantityAvailable: 20,
    unit: 'kg',
    priceMinor: 420,
    currency: 'LKR',
    location: 'Nuwara Eliya',
  ),
  const ProductModel(
    id: 'prod-2',
    farmerId: 'farmer-1',
    name: 'Cavendish Bananas',
    category: ProductCategory.fruits,
    description: 'Sweet Cavendish bananas from Ambalantota',
    quantityAvailable: 45,
    unit: 'kg',
    priceMinor: 280,
    currency: 'LKR',
    location: 'Ambalantota',
  ),
  const ProductModel(
    id: 'prod-3',
    farmerId: 'farmer-2',
    name: 'Gotukola Bunches',
    category: ProductCategory.herbs,
    description: 'Fresh Gotukola (Centella Asiatica) bunches',
    quantityAvailable: 80,
    unit: 'bunch',
    priceMinor: 90,
    currency: 'LKR',
    location: 'Kandy',
  ),
];
