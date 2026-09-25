import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/firebase_service.dart';
import '../../../models/product.dart';
import '../../../providers/farmora_state.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a product'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price per unit'),
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
          onPressed: () async {
            final state = context.read<FarmoraState>();
            if (state.currentUserId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sign in to publish products.')),
              );
              return;
            }
            final quantity = int.tryParse(quantityController.text.trim());
            final price = double.tryParse(priceController.text.trim());
            if (nameController.text.trim().isEmpty ||
                quantity == null ||
                quantity <= 0 ||
                price == null ||
                price <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Enter a product name, valid quantity, and price.')),
              );
              return;
            }
            try {
              await FirestoreService().createSecureProduct(
                Product(
                  name: nameController.text.trim(),
                  category: 'Vegetables',
                  location: state.district,
                  quantity: '$quantity kg',
                  quantityAvailable: quantity,
                  unit: 'kg',
                  price: 'LKR $price / kg',
                  pricePerUnit: price,
                  priceMinor: (price * 100).round(),
                ),
              );
              if (context.mounted) Navigator.pop(context);
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not publish product: $error')),
              );
            }
          },
          child: const Text('Publish'),
        ),
      ],
    );
  }
}

/// Alias for backward compatibility
typedef AddProduct = AddProductDialog;
