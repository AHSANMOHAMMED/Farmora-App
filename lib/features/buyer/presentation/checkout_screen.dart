import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/product.dart';
import '../../../core/models/order.dart';
import '../../../core/repositories/order_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/orders_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final ProductModel product;
  final double quantity;

  const CheckoutScreen({
    super.key,
    required this.product,
    required this.quantity,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController(text: '123 Main St, Colombo');
  bool _isProcessing = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _placeOrder() async {
    setState(() => _isProcessing = true);

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final subtotal = (widget.product.priceMinor * widget.quantity).toInt();
    const deliveryFee = 50000; // 500 Rs fixed for now
    final total = subtotal + deliveryFee;

    final order = OrderModel(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      buyerId: user.id,
      farmerId: widget.product.farmerId,
      items: [
        OrderItem(
          productId: widget.product.id,
          productName: widget.product.name,
          quantity: widget.quantity,
          unit: widget.product.unit,
          pricePerUnitMinor: widget.product.priceMinor,
          subtotalMinor: subtotal,
        ),
      ],
      subtotalMinor: subtotal,
      deliveryFeeMinor: deliveryFee,
      totalMinor: total,
      currency: widget.product.currency,
      deliveryAddress: _addressController.text,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
    );

    await ref.read(orderRepositoryProvider).createOrder(order);
    ref.invalidate(userOrdersProvider);

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      // Ensure we pop back correctly depending on navigation stack
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = (widget.product.priceMinor * widget.quantity).toInt();
    const deliveryFee = 50000; // 500.00 LKR
    final total = subtotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xffdcedc8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('🥬', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${widget.quantity.toStringAsFixed(1)} ${widget.product.unit}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${widget.product.currency} ${(subtotal / 100).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Delivery details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SummaryRow('Subtotal', '${widget.product.currency} ${(subtotal / 100).toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _SummaryRow('Delivery fee', '${widget.product.currency} ${(deliveryFee / 100).toStringAsFixed(2)}'),
                    const Divider(height: 24),
                    _SummaryRow(
                      'Total',
                      '${widget.product.currency} ${(total / 100).toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: _isProcessing ? null : _placeOrder,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Confirm and place order', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow(this.label, this.value, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.normal,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
