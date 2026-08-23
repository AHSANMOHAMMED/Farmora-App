import 'package:flutter/material.dart';
import '../models/market_price.dart';

class MarketPriceChip extends StatelessWidget {
  final MarketPrice price;

  const MarketPriceChip(this.price, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffe8f5e9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getCropEmoji(price.cropName),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                price.cropName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                price.displayPrice,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xff1f7a4d),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCropEmoji(String cropName) {
    const cropEmoji = {
      'Tomato': '🍅',
      'Carrot': '🥕',
      'Green Chilli': '🌶️',
      'Capsicum': '🫑',
      'Brinjal': '🍆',
      'Banana': '🍌',
      'Mango': '🥭',
      'Papaya': '🍈',
      'Leeks': '🧅',
      'Beans': '🫘',
      'Potato': '🥔',
      'Cabbage': '🥬',
    };
    return cropEmoji[cropName] ?? '🌾';
  }
}
