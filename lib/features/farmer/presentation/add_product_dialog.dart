import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/l10n.dart';
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
      title: Text(context.l10n.addAProduct),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration:
                  InputDecoration(labelText: context.l10n.farmerProductName),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(labelText: context.l10n.quantity),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              decoration:
                  InputDecoration(labelText: context.l10n.farmerPricePerUnit),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
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
          child: Text(context.l10n.publish),
        ),
      ],
    );
  }
}

/// Alias for backward compatibility
typedef AddProduct = AddProductDialog;
