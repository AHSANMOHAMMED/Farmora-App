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
  String _searchQuery = '';
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final allProducts = state.products;
    final activeCount = allProducts.where((p) => p.isActive).length;
    final outOfStockCount = allProducts.where((p) => p.isEmpty).length;

    final filteredProducts = allProducts.where((p) {
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesSearch) return false;
      }
      switch (_selectedFilter) {
        case 1: return p.isActive;
        case 2: return p.isEmpty;
        default: return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Products',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  _buildProfileAvatar(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 22, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: const InputDecoration(
                          hintText: 'Search my products...',
                          hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.onSurfaceVariant),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 15),
                      ),
                    ),
                    const Icon(Icons.tune, size: 22, color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Filter Tabs ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(0, 'All Products', allProducts.length),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, 'Active', activeCount),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, 'Out of Stock', outOfStockCount),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Products List ──
            Expanded(
              child: filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _buildProductCard(filteredProducts[index]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddProductScreen())),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      child: const Icon(Icons.person, color: Colors.white, size: 22),
    );
  }

  Widget _buildFilterChip(int index, String title, int count) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? null : Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Text(
          '$title ($count)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isEmpty = product.isEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 80,
              height: 80,
              color: const Color(0xFFF5F5F0),
              child: product.imagePath != null && product.imagePath!.isNotEmpty
                  ? Image.asset(product.imagePath!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackImage(product))
                  : _buildFallbackImage(product),
            ),
          ),
          const SizedBox(width: 14),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.more_vert, size: 20, color: AppColors.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'LKR ${product.pricePerUnit.toStringAsFixed(2)} / ${product.unit}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 14,
                            color: isEmpty ? AppColors.error : AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${product.quantity} ${product.unit} available',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: isEmpty ? AppColors.error : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isEmpty ? const Color(0xFFFEE2E2) : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isEmpty ? 'OUT OF STOCK' : 'ACTIVE',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isEmpty ? const Color(0xFF93000A) : const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage(Product product) {
    return Center(child: Text(product.emoji, style: const TextStyle(fontSize: 32)));
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.outlineVariant),
          SizedBox(height: 16),
          Text('No products found', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
