import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/product.dart';
import '../../../core/repositories/product_repository.dart';
import '../../auth/providers/auth_provider.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  ProductCategory _selectedCategory = ProductCategory.vegetables;

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (nameController.text.isEmpty || quantityController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final qty = double.tryParse(quantityController.text) ?? 0.0;
    final priceStr = priceController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final priceMinor = ((double.tryParse(priceStr) ?? 0.0) * 100).toInt();

    final product = ProductModel(
      id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
      farmerId: user.id,
      name: nameController.text,
      category: _selectedCategory,
      quantityAvailable: qty,
      unit: 'kg', // Defaulting to kg for simplicity
      priceMinor: priceMinor,
      location: 'Your farm', // Can be enhanced with actual location later
      createdAt: DateTime.now(),
    );

    // Provide immediate optimistic update/invalidate
    await ref.read(productRepositoryProvider).createProduct(product);
    // Ideally we would invalidate the provider here, but we can't easily invalidate
    // the FutureProvider since we don't know exactly which one is active.
    // In a real app we'd invalidate `buyerProductsProvider` or similar.

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a product'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ProductCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: ProductCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity (kg)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price per kg (LKR)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Publish'),
        ),
      ],
    );
  }
}

/// Alias for backward compatibility
typedef AddProduct = AddProductDialog;
