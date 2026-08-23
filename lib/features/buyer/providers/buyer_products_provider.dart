import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/product.dart';
import '../../../core/repositories/product_repository.dart';

final buyerProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getProducts();
});

final productSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<ProductCategory?>((ref) => null);

final filteredProductsProvider = Provider<List<ProductModel>>((ref) {
  final productsAsync = ref.watch(buyerProductsProvider);
  final searchQuery = ref.watch(productSearchQueryProvider).toLowerCase();
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return productsAsync.maybeWhen(
    data: (products) {
      return products.where((product) {
        final matchesSearch = product.name.toLowerCase().contains(searchQuery) ||
            product.location.toLowerCase().contains(searchQuery);
        final matchesCategory = selectedCategory == null || product.category == selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    },
    orElse: () => [],
  );
});
