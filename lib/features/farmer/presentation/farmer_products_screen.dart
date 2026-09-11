import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/product.dart';
import '../../../providers/farmora_state.dart';
import 'add_product_screen.dart';

class FarmerProductsScreen extends StatefulWidget {
  const FarmerProductsScreen({super.key});

  @override
  State<FarmerProductsScreen> createState() => _FarmerProductsScreenState();
}

class _FarmerProductsScreenState extends State<FarmerProductsScreen> {
  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final allProducts = state.filteredProducts;

    final filteredProducts = _activeFilter == 'All'
        ? allProducts
        : allProducts.where((p) {
            switch (_activeFilter) {
              case 'Active':
                return p.isActive;
              case 'Pending':
                return p.status.toLowerCase() == 'pending';
              case 'Out of Stock':
                return p.isEmpty;
              default:
                return true;
            }
          }).toList();

    final activeCount = allProducts.where((p) => p.isActive).length;
    final pendingCount = allProducts.where((p) => p.status.toLowerCase() == 'pending').length;
    final outOfStockCount = allProducts.where((p) => p.isEmpty).length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Title + Search + Bell ──────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'My Products',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded, color: AppColors.onSurface, size: 26),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none_rounded, color: AppColors.onSurface, size: 26),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Filter Tabs ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterTab('All', allProducts.length, isActive: true),
                    const SizedBox(width: 8),
                    _buildFilterTab('Active', activeCount),
                    const SizedBox(width: 8),
                    _buildFilterTab('Pending', pendingCount),
                    const SizedBox(width: 8),
                    _buildFilterTab('Out of Stock', outOfStockCount),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Product List ───────────────────────────────
            Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.outlineVariant),
                          SizedBox(height: 12),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return _buildProductCard(context, state, product);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  // ── Filter Tab ────────────────────────────────────────────
  Widget _buildFilterTab(String label, int count, {bool isActive = false}) {
    final isSelected = _activeFilter == label || (label == 'All' && _activeFilter == 'All');
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ── Product Card (full-width image) ───────────────────────
  Widget _buildProductCard(BuildContext context, FarmoraState state, Product product) {
    final isEmpty = product.isEmpty;
    final isPending = product.status.toLowerCase() == 'pending';

    return GestureDetector(
      onTap: () => _showProductActionsModal(context, state, product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product Image ───────────────────────────
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  color: AppColors.surfaceContainer,
                  child: product.imagePath != null && product.imagePath!.isNotEmpty
                      ? Image.asset(
                          product.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackImage(product),
                        )
                      : _buildFallbackImage(product),
                ),
                // Status badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusBadge(product.status, isEmpty, isPending),
                ),
              ],
            ),

            // ── Product Info ─────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Price',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'LKR ${product.pricePerUnit.toStringAsFixed(2)}/${product.unit}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isEmpty ? AppColors.onSurfaceVariant : AppColors.primary,
                              decoration: isEmpty ? TextDecoration.lineThrough : null,
                              decorationColor: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Available',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${product.quantity} ${product.unit}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isEmpty ? AppColors.error : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status Badge ──────────────────────────────────────────
  Widget _buildStatusBadge(String status, bool isEmpty, bool isPending) {
    Color bgColor;
    Color textColor;
    String label;

    if (isEmpty) {
      bgColor = const Color(0xFFFFDAD6);
      textColor = const Color(0xFF93000A);
      label = 'Out of Stock';
    } else if (isPending) {
      bgColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFE65100);
      label = 'Pending';
    } else {
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      label = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage(Product product) {
    return Center(
      child: Text(
        product.emoji,
        style: const TextStyle(fontSize: 48),
      ),
    );
  }

  void _showProductActionsModal(BuildContext context, FarmoraState state, Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  '${product.price} • ${product.quantity}',
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(
                    product.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    product.isActive ? 'Mark as Out of Stock' : 'Mark as Active / In Stock',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    state.toggleProductStock(product.id);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Updated ${product.name} stock status')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text(
                    'Remove Listing',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    state.deleteProduct(product.id);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleted ${product.name}')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
