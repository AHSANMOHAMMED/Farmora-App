import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import '../../../core/widgets/product_tile.dart';
import '../../farmer/presentation/add_product_dialog.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final isFarmer = state.role == Role.farmer;

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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!isFarmer)
            const SearchBar(
              hintText: 'Search by product or location',
              leading: Icon(Icons.search_rounded),
            ),
          const SizedBox(height: 16),
          ...state.products.map(
            (product) => ProductTile(product, showActions: isFarmer),
          ),
        ],
      ),
    );
  }
}

/// Alias for backward compatibility
typedef Products = ProductsScreen;
