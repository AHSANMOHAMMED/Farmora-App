import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/product.dart';
import '../../../providers/farmora_state.dart';

class CheckoutScreen extends StatelessWidget {
  final ProductModel product;
  final double quantity;

  const CheckoutScreen({super.key, required this.product, required this.quantity});

  @override
  Widget build(BuildContext context) {
    final total = product.priceMinor / 100 * quantity;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: const Color(0xffdcedc8), child: const Text('🥬', style: TextStyle(fontSize: 24))),
              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${quantity.toStringAsFixed(1)} × ${product.displayPrice}'),
              trailing: Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xff1f7a4d))),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Enter your delivery address',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.money, color: Color(0xff1f7a4d)),
            title: const Text('Cash on Delivery'),
            trailing: const Icon(Icons.check_circle, color: Color(0xff1f7a4d)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xff1f7a4d))),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order placed successfully!'), backgroundColor: Color(0xff1f7a4d)),
              );
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: Text('Place Order — \$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
