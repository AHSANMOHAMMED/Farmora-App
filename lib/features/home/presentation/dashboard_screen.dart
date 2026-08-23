import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_role.dart';

import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/product_tile.dart';
import '../../../core/widgets/order_card.dart';
import '../../../core/widgets/async_state_handler.dart';
import '../../profile/presentation/role_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../../buyer/providers/buyer_products_provider.dart';
import '../../buyer/presentation/product_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final role = user?.role ?? Role.buyer;
    final isBuyer = role == Role.buyer;
    final productsAsync = ref.watch(buyerProductsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // Greeting header
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xffdcefe2),
              child: Icon(role.icon, color: const Color(0xff1f7a4d)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning, ${user?.displayName ?? ""}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    'Your Farmora network is growing.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Hero card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xff1f7a4d),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isFarmer
                          ? 'ඔබේ අස්වැන්න විකුණන්න / Sell your harvest'
                          : 'Support local farmers today.',
                      style: const TextStyle(color: Color(0xffd8f1df)),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (isFarmer) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const _AddProductPlaceholder(),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xff1f7a4d),
                      ),
                      child: Text(
                        isBuyer
                            ? 'Shop now'
                            : isFarmer
                                ? 'Add product / නව නිෂ්පාදනය'
                                : 'Find jobs',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.eco_rounded,
                color: Color(0xffb9e5c5),
                size: 80,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Stats for farmer/buyer
        if (!isBuyer)
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Active products',
                  value: role == Role.farmer ? '3' : '8',
                  icon: Icons.insights_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Pending orders',
                  value: '${state.orders.where((o) => o.status == 'In transit').length}',
                  icon: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),

        // Search for buyer
        if (isBuyer)
          const SearchBar(
            hintText: 'Search fresh produce',
            leading: Icon(Icons.search_rounded),
          ),
        if (isBuyer) const SizedBox(height: 20),

        // Categories for buyer
        if (isBuyer)
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(avatar: Icon(Icons.grass, size: 18), label: Text('Vegetables')),
              Chip(avatar: Icon(Icons.apple, size: 18), label: Text('Fruits')),
              Chip(avatar: Icon(Icons.local_florist, size: 18), label: Text('Herbs')),
            ],
          ),
        if (isBuyer) const SizedBox(height: 24),

        // Market Prices Section (for farmers)
        if (isFarmer) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Market Prices Today / වෙළඳපොල මිල',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MarketPricesScreen(),
                    ),
                  );
                },
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _getSamplePrices().map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _MiniPriceChip(
                  cropName: p.cropName,
                  pricePerKg: p.pricePerKg,
                  emoji: p.emoji,
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Recent items
        Text(
          isBuyer ? 'Picked for you' : 'Your products',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 12),
        if (isBuyer)
          AsyncStateHandler(
            value: productsAsync,
            dataBuilder: (context, products) {
              if (products.isEmpty) {
                return const Text('No products available right now.');
              }
              return Column(
                children: products.take(2).map((p) => ProductTile(p, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductDetailScreen(product: p))))).toList(),
              );
            },
          ),
        if (!isBuyer)
          const OrderCard(
            title: 'Organic Tomatoes',
            detail: '20 kg · Today',
            status: 'In transit',
            color: Color(0xff3478c5),
          ),
        ),

        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => showModalBottomSheet(
            context: context,
            builder: (_) => const RoleSheet(),
          ),
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('Preview another role'),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 🌅';
    if (hour < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  List<_DemoMarketPrice> _getSamplePrices() {
    final now = DateTime.now();
    return [
      _DemoMarketPrice(cropName: 'Tomato', pricePerKg: 95, emoji: '🍅', recordedDate: now),
      _DemoMarketPrice(cropName: 'Carrot', pricePerKg: 145, emoji: '🥕', recordedDate: now),
      _DemoMarketPrice(cropName: 'Green Chilli', pricePerKg: 220, emoji: '🌶️', recordedDate: now),
      _DemoMarketPrice(cropName: 'Beans', pricePerKg: 130, emoji: '🫘', recordedDate: now),
      _DemoMarketPrice(cropName: 'Cabbage', pricePerKg: 60, emoji: '🥬', recordedDate: now),
    ];
  }
}

class _DemoMarketPrice {
  final String cropName;
  final double pricePerKg;
  final String emoji;
  final DateTime recordedDate;

  const _DemoMarketPrice({
    required this.cropName,
    required this.pricePerKg,
    required this.emoji,
    required this.recordedDate,
  });
}

class _MiniPriceChip extends StatelessWidget {
  final String cropName;
  final double pricePerKg;
  final String emoji;

  const _MiniPriceChip({
    required this.cropName,
    required this.pricePerKg,
    required this.emoji,
  });

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
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cropName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                'LKR ${pricePerKg.toStringAsFixed(0)}/kg',
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
}

class _AddProductPlaceholder extends StatelessWidget {
  const _AddProductPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: const Center(
        child: Text('Add Product Form - Coming Soon'),
      ),
    );
  }
}

/// Alias for backward compatibility
typedef Dashboard = DashboardScreen;
