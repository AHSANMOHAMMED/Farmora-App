import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_role.dart';
import '../../../core/models/product.dart';
import '../../../core/widgets/product_tile.dart';
import '../../../core/widgets/async_state_handler.dart';
import '../../farmer/presentation/add_product_dialog.dart';
import 'product_detail_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/buyer_products_provider.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isFarmer = user?.role == Role.farmer;
    final productsAsync = ref.watch(buyerProductsProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isFarmer ? 'My products' : 'Browse produce'),
        actions: [
          if (isFarmer)
            IconButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddProductDialog(),
              ),
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!isFarmer) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SearchBar(
                hintText: 'Search by product or location',
                leading: const Icon(Icons.search_rounded),
                onChanged: (value) => ref.read(productSearchQueryProvider.notifier).state = value,
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: ProductCategory.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = ProductCategory.values[index];
                  final isSelected = selectedCategory == category;
                  return FilterChip(
                    label: Text(category.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref.read(selectedCategoryProvider.notifier).state = selected ? category : null;
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: AsyncStateHandler(
              value: productsAsync,
              dataBuilder: (context, _) {
                if (filteredProducts.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ProductTile(
                      product,
                      showActions: isFarmer,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Alias for backward compatibility
typedef Products = ProductsScreen;
