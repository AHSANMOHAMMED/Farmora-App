import 'package:flutter/material.dart';
import '../../models/product.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final bool showActions;

  const ProductTile(
    this.product, {
    super.key,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: product.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                product.emoji,
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
                    '${product.category} · ${product.location}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    product.price,
                    style: const TextStyle(
                      color: Color(0xff1f7a4d),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    product.quantity,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (showActions) const Icon(Icons.more_vert),
          ],
        ),
      ),
    );
  }
}

/// Alias for backward compatibility
typedef Tile = ProductTile;
