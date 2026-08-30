import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/product_tile.dart';
import '../../../core/widgets/order_card.dart';
import '../../buyer/presentation/buyer_products_screen.dart';
import '../../farmer/presentation/add_product_screen.dart';
import '../../transporter/presentation/available_jobs_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final role = state.role;
    final isBuyer = role == Role.buyer;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xffdcefe2),
              child: Icon(role.icon, color: const Color(0xff1f7a4d)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  Text(
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
        if (isBuyer)
          const SearchBar(
            hintText: 'Search fresh produce',
            leading: Icon(Icons.search_rounded),
          ),
        if (isBuyer) const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xff1f7a4d),
            borderRadius: BorderRadius.circular(16),
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
                    const Text(
                      'Support local farmers today.',
                      style: TextStyle(color: Color(0xffd8f1df)),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        final destination = isBuyer
                            ? const BuyerProductsScreen()
                            : role == Role.farmer
                                ? const AddProductScreen()
                                : const AvailableJobsScreen();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => destination),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xff1f7a4d),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        isBuyer
                            ? 'Shop now'
                            : role == Role.farmer
                                ? 'Add product'
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
        Text(
          isBuyer ? 'Explore categories' : 'Your overview',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 12),
        if (isBuyer)
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(Icons.grass, size: 18),
                label: Text('Vegetables'),
              ),
              Chip(
                avatar: Icon(Icons.apple, size: 18),
                label: Text('Fruits'),
              ),
              Chip(
                avatar: Icon(Icons.local_florist, size: 18),
                label: Text('Herbs'),
              ),
            ],
          ),
        if (!isBuyer)
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Active products',
                  value: role == Role.farmer ? '${state.products.length}' : '8',
                  icon: Icons.insights_rounded,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: StatCard(
                  label: 'Pending orders',
                  value: '4',
                  icon: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),
        Text(
          isBuyer ? 'Picked for you' : 'Recent orders',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 12),
        if (isBuyer) ...state.products.take(2).map((p) => ProductTile(p)),
        if (!isBuyer)
          const OrderCard(
            title: 'Organic Tomatoes',
            detail: '20 kg · Today',
            status: 'In transit',
            color: Color(0xff3478c5),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Alias for backward compatibility
typedef Dashboard = DashboardScreen;
