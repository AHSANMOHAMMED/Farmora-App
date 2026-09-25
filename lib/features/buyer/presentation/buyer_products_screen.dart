import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/product.dart';
import '../../../providers/farmora_state.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../core/widgets/trust_badge.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import '../../../core/localization/l10n.dart';
import 'buyer_l10n.dart';

class BuyerProductsScreen extends StatefulWidget {
  const BuyerProductsScreen({super.key});

  @override
  State<BuyerProductsScreen> createState() => _BuyerProductsScreenState();
}

class _BuyerProductsScreenState extends State<BuyerProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  // Stored (English) category values; labels are translated for display.
  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Spices',
    'Grains',
    'Herbs',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final products = state.filteredProducts;
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          l.buyerBrowseProduce,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: l.buyerCartTooltip,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
                icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.onSurface),
              ),
              if (state.cartItemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${state.cartItemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search & Filter
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => state.setSearchQuery(val),
                          decoration: InputDecoration(
                            hintText: l.buyerSearchProduceHint,
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.70),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.onSurfaceVariant,
                              size: 22,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    tooltip: l.clear,
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      state.setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: l.buyerFilterTooltip,
                      child: InkWell(
                      onTap: () => _showFilterDialog(context, state),
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.filter_list,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Sort control
                Row(
                  children: [
                    const Icon(Icons.sort, size: 18, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Flexible(
                      child: DropdownButton<String>(
                        value: state.sortOrder,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(value: 'newest', child: Text(l.newest, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'priceAsc', child: Text(l.priceLowToHigh, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'priceDesc', child: Text(l.priceHighToLow, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'name', child: Text(l.nameAz, overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) {
                          if (v != null) state.setSortOrder(v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(l.buyerItemsCount(products.length), style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 8),

                // Active filter badge
                if (state.selectedCategory != 'All')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Chip(
                      label: Text(l.buyerCategoryChip(buyerCategoryLabel(l, state.selectedCategory))),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => state.setSelectedCategory('All'),
                      backgroundColor: AppColors.surfaceContainerHigh,
                    ),
                  ),

                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                  children: _categories.map((cat) {
                    final isSelected = state.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(buyerCategoryLabel(l, cat)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontFamily: 'Inter',
                          fontSize: 13,
                        ),
                        onSelected: (selected) {
                          if (selected) state.setSelectedCategory(cat);
                        },
                      ),
                    );
                  }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Product count
                Text(
                  l.buyerProductsAvailable(products.length),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                // Product list
                if (products.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.eco_outlined,
                            size: 64,
                            color: AppColors.outlineVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l.buyerNoProductsFound,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildProductCard(context, state, products[index]);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, FarmoraState state, Product product) {
    final l = context.l10n;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: product.imagePath != null && product.imagePath!.isNotEmpty
                    ? SafeImage(
                        path: product.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackIcon(product),
                      )
                    : _buildFallbackIcon(product),
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusPill(l, product),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.isOrganic ? l.buyerOrganic : l.buyerConventional} • ${product.location}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  TrustBadge(trustLevel: state.trustLevelForProduct(product)),
                  const SizedBox(height: 6),
                  Text(
                    buyerProductPrice(l, product),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: product.isEmpty ? AppColors.onSurfaceVariant : AppColors.primary,
                      decoration: product.isEmpty ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),

            // Add to cart button
            if (product.isActive)
              IconButton(
                tooltip: l.buyerAddToCart,
                onPressed: () {
                  state.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.buyerAddedToCart(product.name)),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(AppLocalizations l, Product product) {
    final isEmpty = product.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isEmpty ? AppColors.statusEmptyBg : AppColors.statusActiveBg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        isEmpty ? l.statusOutOfStock : l.buyerAvailable,
        maxLines: 1,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: isEmpty ? AppColors.statusEmptyText : AppColors.statusActiveText,
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(Product product) {
    return Container(
      color: product.color,
      child: Center(
        child: Text(
          product.emoji,
          style: const TextStyle(fontSize: 36),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, FarmoraState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l = ctx.l10n;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.buyerFilterByCategory,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = state.selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(buyerCategoryLabel(l, cat)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        state.setSelectedCategory(cat);
                        Navigator.of(ctx).pop();
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
