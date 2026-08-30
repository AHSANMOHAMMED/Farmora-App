import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/product.dart';
import '../../../providers/farmora_state.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final isInCart = state.cartItems.any((c) => c.product.id == product.id);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          if (isInCart)
            IconButton(
              onPressed: () => state.removeFromCart(product.id),
              icon: const Icon(Icons.shopping_cart, color: AppColors.primary),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: double.infinity,
                  height: 240,
                  decoration: BoxDecoration(
                    color: product.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: product.imagePath != null && product.imagePath!.isNotEmpty
                        ? Image.asset(
                            product.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackImage(),
                          )
                        : _buildFallbackImage(),
                  ),
                ),
                const SizedBox(height: 20),

                // Product Name & Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.isActive ? AppColors.statusActiveBg : AppColors.statusEmptyBg,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        product.status.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: product.isActive ? AppColors.statusActiveText : AppColors.statusEmptyText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location & Category
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      product.location,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.category_outlined, size: 18, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.price,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip(Icons.inventory_outlined, product.quantity),
                          const SizedBox(width: 8),
                          if (product.isOrganic)
                            _buildInfoChip(Icons.eco_outlined, 'Organic'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                if (product.description.isNotEmpty) ...[
                  const Text(
                    'About this product',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Add to Cart bar
          if (product.isActive)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
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
                child: SizedBox(
                  height: 52,
                  child: isInCart
                      ? OutlinedButton.icon(
                          onPressed: () {
                            state.removeFromCart(product.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Removed ${product.name} from cart'),
                                backgroundColor: AppColors.error,
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.errorContainer, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.remove_shopping_cart, size: 20),
                          label: const Text(
                            'Remove from Cart',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            state.addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added ${product.name} to cart'),
                                backgroundColor: AppColors.primary,
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                          label: const Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: product.color,
      child: Center(
        child: Text(
          product.emoji,
          style: const TextStyle(fontSize: 80),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
