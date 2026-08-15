import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          onPressed: () {
            if (nameController.text.isNotEmpty) {
              context.read<FarmoraState>().addProduct(
                    Product(
                      id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text,
                      category: 'Vegetables',
                      location: 'Your farm',
                      quantity: '${quantityController.text} available',
                      price: 'LKR ${priceController.text} / unit',
                      emoji: '🥬',
                      color: const Color(0xffddf1dd),
                    ),
                  );
              Navigator.pop(context);
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
