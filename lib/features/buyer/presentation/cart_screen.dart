import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<String?> _chooseTransporter(BuildContext context) async {
    final transporters = await FirestoreService().getAvailableTransporters();
    if (!context.mounted) return null;
    if (transporters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No verified transporters are available right now.'),
        ),
      );
      return null;
    }
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose a transporter'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: transporters.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transporter = transporters[index];
              final name =
                  (transporter['displayName'] ?? 'Transporter').toString();
              final district = (transporter['district'] ?? '').toString();
              final vehicle = (transporter['vehicleType'] ?? '').toString();
              final capacity = transporter['vehicleCapacity'];
              final details = [
                if (district.isNotEmpty) district,
                if (vehicle.isNotEmpty) vehicle,
                if (capacity != null) '$capacity kg capacity',
              ].join(' • ');
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      (transporter['photoUrl'] ?? '').toString().isNotEmpty
                          ? NetworkImage(transporter['photoUrl'].toString())
                          : null,
                  child: (transporter['photoUrl'] ?? '').toString().isEmpty
                      ? const Icon(Icons.local_shipping_outlined)
                      : null,
                ),
                title: Text(name),
                subtitle: Text(
                  details.isEmpty ? 'Verified transporter' : details,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(dialogContext)
                    .pop(transporter['uid'].toString()),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final cartItems = state.cartItems;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () {
                state.clearCart();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cart cleared'),
                    backgroundColor: AppColors.error,
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppColors.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse fresh produce and add items to your cart',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continue Shopping',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Thumbnail
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: item.product.color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: item.product.imagePath != null
                                    ? SafeImage(
                                        path: item.product.imagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                          item.product.emoji,
                                          style: const TextStyle(fontSize: 32),
                                        )),
                                      )
                                    : Text(
                                        item.product.emoji,
                                        style: const TextStyle(fontSize: 32),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.product.price,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity controls
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (item.quantity <= 1) {
                                        state.removeFromCart(item.product.id);
                                      } else {
                                        state.updateCartQuantity(
                                          item.product.id,
                                          item.quantity - 1,
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      item.quantity <= 1
                                          ? Icons.delete_outline
                                          : Icons.remove,
                                      size: 18,
                                      color: item.quantity <= 1
                                          ? AppColors.error
                                          : AppColors.onSurface,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      state.updateCartQuantity(
                                        item.product.id,
                                        item.quantity + 1,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.add,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Checkout bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFeeRow('Subtotal (${state.cartItemCount} items)',
                          'LKR ${state.cartSubtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      _buildFeeRow('Delivery fee',
                          'LKR ${state.cartDeliveryFee.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: AppColors.onSurfaceVariant)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.statusPendingBg,
                                borderRadius: BorderRadius.circular(9999)),
                            child: const Text('COD after delivery',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.statusPendingText)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          Text(
                            'LKR ${state.cartGrandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        onChanged: (v) => state.deliveryAddressDraft = v,
                        decoration: const InputDecoration(
                          labelText: 'Delivery address',
                          hintText: 'Street, city, district',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                          'Server verifies price, stock and totals. Pay COD after delivery (or PayHere when configured).',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: state.placingOrder
                              ? null
                              : () async {
                                  final address =
                                      state.deliveryAddressDraft.trim();
                                  if (address.length < 5) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Enter a delivery address to place the order.'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  final transporterId =
                                      await _chooseTransporter(context);
                                  if (transporterId == null) return;
                                  final ok = await state.placeOrder(
                                    deliveryAddress: address,
                                    transporterId: transporterId,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? 'Request sent. Order will confirm after transporter accepts.'
                                          : 'Could not place order. Check address or try again.'),
                                      backgroundColor: ok
                                          ? AppColors.primary
                                          : AppColors.onSurfaceVariant,
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  if (ok) Navigator.of(context).pop();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          icon: context.watch<FarmoraState>().placingOrder
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_outline,
                                  size: 20),
                          label: Text(
                            context.watch<FarmoraState>().placingOrder
                                ? 'Placing…'
                                : 'Place Order',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFeeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurfaceVariant)),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
