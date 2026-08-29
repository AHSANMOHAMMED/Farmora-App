import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/product.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  double _quantity = 1.0;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xffdcedc8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(child: Text('🥬', style: TextStyle(fontSize: 80))),
            ),
            const SizedBox(height: 24),
            Text(p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${p.category.label} · ${p.location}', style: const TextStyle(color: Colors.black54, fontSize: 16)),
            const SizedBox(height: 8),
            Text(p.displayPrice, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xff1f7a4d))),
            const SizedBox(height: 16),
            if (p.description.isNotEmpty) ...[
              const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(p.description, style: const TextStyle(color: Colors.black87, height: 1.5)),
            ],
            const SizedBox(height: 24),
            const Text('Quantity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _quantity > 1.0 ? () => setState(() => _quantity -= 1.0) : null,
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                Text('${_quantity.toStringAsFixed(1)} ${p.unit}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  onPressed: _quantity < p.quantityAvailable ? () => setState(() => _quantity += 1.0) : null,
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                Text('Available: ${p.displayQuantity}', style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => CheckoutScreen(product: p, quantity: _quantity)),
              );
            },
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            child: const Text('Buy now'),
          ),
        ),
      ),
    );
  }
}
