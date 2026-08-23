import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductTile extends StatelessWidget {
  final ProductModel product;
  final bool showActions;
  final VoidCallback? onTap;

  const ProductTile(
    this.product, {
    super.key,
    this.showActions = false,
    this.onTap,
  });

  Color _getCategoryColor(ProductCategory category) {
    switch (category) {
      case ProductCategory.vegetables:
        return const Color(0xffdcedc8);
      case ProductCategory.fruits:
        return const Color(0xffffe0b2);
      case ProductCategory.herbs:
        return const Color(0xffc8e6c9);
      default:
        return const Color(0xffeeeeee);
    }
  }

  String _getCategoryEmoji(ProductCategory category) {
    switch (category) {
      case ProductCategory.vegetables:
        return '🥬';
      case ProductCategory.fruits:
        return '🍎';
      case ProductCategory.herbs:
        return '🌿';
      default:
        return '📦';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _getCategoryColor(product.category),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getCategoryEmoji(product.category),
                  style: const TextStyle(fontSize: 36),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${product.category.label} · ${product.location}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      product.displayPrice,
                      style: const TextStyle(
                        color: Color(0xff1f7a4d),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      product.displayQuantity,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (showActions) const Icon(Icons.more_vert),
              if (!showActions && onTap != null)
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alias for backward compatibility
typedef Tile = ProductTile;
