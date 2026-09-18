import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/product_tile.dart';
import '../../../core/widgets/order_card.dart';
import '../../buyer/presentation/buyer_products_screen.dart';
import '../../buyer/presentation/buyer_offers_screen.dart';
import '../../farmer/presentation/add_product_screen.dart';
import '../../farmer/presentation/farmer_offers_screen.dart';
import '../../transporter/presentation/available_jobs_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final role = state.role;
    final isBuyer = role == Role.buyer;
    final pendingCount = state.pendingOrders.length;
    final earningsLabel = 'LKR ${state.totalEarnings.toStringAsFixed(0)}';
    final name = state.displayName.isNotEmpty ? state.displayName : role.label;
    final categories = <String>{
      ...state.products.map((p) => p.category).where((c) => c.isNotEmpty),
      'Vegetables',
      'Fruits',
      'Spices',
      'Grains',
      'Herbs',
    }.toList()
      ..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xffdcefe2),
              backgroundImage:
                  state.photoUrl.isNotEmpty ? NetworkImage(state.photoUrl) : null,
              child: state.photoUrl.isEmpty
                  ? Icon(role.icon, color: const Color(0xff1f7a4d))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greeting()}, $name',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    state.district.isNotEmpty
                        ? '${state.district}, Sri Lanka'
                        : 'Your Farmora network in Sri Lanka.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (isBuyer)
          SearchBar(
            hintText: 'Search fresh produce',
            leading: const Icon(Icons.search_rounded),
            onSubmitted: (q) {
              state.setSearchQuery(q);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BuyerProductsScreen()),
              );
            },
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
                    Text(
                      isBuyer
                          ? 'Fresh produce from Sri Lankan farms.'
                          : role == Role.farmer
                              ? 'List harvest from ${state.district.isNotEmpty ? state.district : 'your district'}.'
                              : 'Deliver across Sri Lankan districts.',
                      style: const TextStyle(color: Color(0xffd8f1df)),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...categories.take(6).map(
                    (cat) => ActionChip(
                      avatar: const Icon(Icons.eco, size: 18),
                      label: Text(cat),
                      onPressed: () {
                        state.setSelectedCategory(cat);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const BuyerProductsScreen()),
                        );
                      },
                    ),
                  ),
              ActionChip(
                avatar: const Icon(Icons.local_offer_outlined, size: 18),
                label: const Text('My Offers'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BuyerOffersScreen()),
                ),
              ),
            ],
          ),
        if (!isBuyer)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    if (role == Role.farmer) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const FarmerOffersScreen()),
                      );
                    }
                  },
                  child: StatCard(
                    label: 'Offers',
                    value: role == Role.farmer ? 'Open' : '${state.jobs.length}',
                    icon: Icons.local_offer_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: role == Role.farmer ? 'Pending orders' : 'Jobs',
                  value: '$pendingCount',
                  icon: Icons.trending_up_rounded,
                ),
              ),
              if (role == Role.farmer) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Earnings',
                    value: earningsLabel,
                    icon: Icons.payments_outlined,
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: 24),
        Text(
          isBuyer ? 'Picked for you' : 'Recent orders',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 12),
        if (isBuyer) ...[
          if (state.products.isEmpty)
            const Text('No products listed yet. Check back soon.',
                style: TextStyle(color: Colors.black54))
          else
            ...state.products.take(4).map((p) => ProductTile(p)),
        ],
        if (!isBuyer) ...[
          if (state.orders.isEmpty)
            const Text('No recent orders yet.',
                style: TextStyle(color: Colors.black54))
          else
            ...state.orders.take(3).map(
                  (o) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OrderCard(
                      title: o.productName.isNotEmpty ? o.productName : o.title,
                      detail: o.detail.isNotEmpty
                          ? o.detail
                          : '${o.quantity} · ${o.displayTotal}',
                      status: o.status,
                      color: o.color,
                    ),
                  ),
                ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Alias for backward compatibility
typedef Dashboard = DashboardScreen;
