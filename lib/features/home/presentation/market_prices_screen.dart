import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/market_prices_provider.dart';
import '../../../core/models/market_price.dart';

class MarketPricesScreen extends ConsumerWidget {
  const MarketPricesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prices = ref.watch(marketPricesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Prices'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffe8f5e9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xff1f7a4d)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Daily prices from Dambulla and Manning Market',
                    style: TextStyle(color: Color(0xff1f7a4d)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Dambulla Wholesale Market',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prices
                .where((p) => p.marketName == 'Dambulla')
                .map((price) => _PriceChip(price: price))
                .toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Manning Market Colombo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prices
                .where((p) => p.marketName == 'Manning Market')
                .map((price) => _PriceChip(price: price))
                .toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.update, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Last updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final MarketPrice price;

  const _PriceChip({required this.price});

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
