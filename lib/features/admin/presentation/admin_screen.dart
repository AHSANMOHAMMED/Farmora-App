import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xff1a3a2a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Admin header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xff1f7a4d),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.displayName ?? 'Admin'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Farmora Admin Dashboard',
                        style: TextStyle(color: Color(0xffd8f1df)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats cards
          Row(
            children: [
              Expanded(
                child: _AdminStatCard(
                  title: 'Total Users',
                  value: '15',
                  icon: Icons.people_rounded,
                  color: const Color(0xff3478c5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AdminStatCard(
                  title: 'Products',
                  value: '24',
                  icon: Icons.eco_rounded,
                  color: const Color(0xff1f7a4d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AdminStatCard(
                  title: 'Orders',
                  value: '42',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xffe67e22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AdminStatCard(
                  title: 'Revenue',
                  value: 'LKR 850K',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xff9b59b6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          _AdminActionTile(
            icon: Icons.people_alt_rounded,
            title: 'Manage Users',
            subtitle: 'View and manage all users',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _ManageUsersScreen()),
            ),
          ),
          _AdminActionTile(
            icon: Icons.eco_rounded,
            title: 'Manage Products',
            subtitle: 'View all listings',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _ManageProductsScreen()),
            ),
          ),
          _AdminActionTile(
            icon: Icons.receipt_long_rounded,
            title: 'View Orders',
            subtitle: 'All orders and their status',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _ManageOrdersScreen()),
            ),
          ),
          _AdminActionTile(
            icon: Icons.analytics_rounded,
            title: 'Analytics',
            subtitle: 'Platform performance metrics',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analytics coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xffe8f5e9),
          child: Icon(icon, color: const Color(0xff1f7a4d)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// --- Manage Users Screen ---
class _ManageUsersScreen extends StatelessWidget {
  const _ManageUsersScreen();

  @override
  Widget build(BuildContext context) {
    final demoUsers = [
      _DemoUser(name: 'Kamal Perera', role: 'Farmer', location: 'Nuwara Eliya', status: 'Active'),
      _DemoUser(name: 'Nimal Silva', role: 'Farmer', location: 'Kandy', status: 'Active'),
      _DemoUser(name: 'Sunil Fernando', role: 'Farmer', location: 'Badulla', status: 'Active'),
      _DemoUser(name: 'Hotel Lanka', role: 'Buyer', location: 'Colombo', status: 'Active'),
      _DemoUser(name: 'Fresh Mart', role: 'Buyer', location: 'Kurunegala', status: 'Active'),
      _DemoUser(name: 'City Supermarket', role: 'Buyer', location: 'Gampaha', status: 'Active'),
      _DemoUser(name: 'Ravi Transport', role: 'Transporter', location: 'Colombo', status: 'Active'),
      _DemoUser(name: 'Lanka Logistics', role: 'Transporter', location: 'Kandy', status: 'Suspended'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: demoUsers.length,
        itemBuilder: (context, index) {
          final user = demoUsers[index];
          final roleColor = user.role == 'Farmer'
              ? const Color(0xff1f7a4d)
              : user.role == 'Buyer'
                  ? const Color(0xff3478c5)
                  : const Color(0xffe67e22);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: roleColor.withOpacity(0.1),
                child: Icon(
                  user.role == 'Farmer'
                      ? Icons.agriculture_rounded
                      : user.role == 'Buyer'
                          ? Icons.shopping_basket_rounded
                          : Icons.local_shipping_rounded,
                  color: roleColor,
                ),
              ),
              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${user.role} · ${user.location}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.status == 'Active' ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.status,
                  style: TextStyle(
                    fontSize: 12,
                    color: user.status == 'Active' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Manage Products Screen ---
class _ManageProductsScreen extends StatelessWidget {
  const _ManageProductsScreen();

  @override
  Widget build(BuildContext context) {
    final demoProducts = [
      _DemoProduct(name: 'Organic Tomatoes', farmer: 'Kamal Perera', price: 'LKR 420/kg', status: 'Active'),
      _DemoProduct(name: 'Cavendish Bananas', farmer: 'Nimal Silva', price: 'LKR 280/kg', status: 'Active'),
      _DemoProduct(name: 'Gotukola Bunches', farmer: 'Sunil Fernando', price: 'LKR 90/bunch', status: 'Active'),
      _DemoProduct(name: 'Green Chilli', farmer: 'Kamal Perera', price: 'LKR 520/kg', status: 'Active'),
      _DemoProduct(name: 'Fresh Carrots', farmer: 'Nimal Silva', price: 'LKR 340/kg', status: 'Limited'),
      _DemoProduct(name: 'Cabbage Heads', farmer: 'Sunil Fernando', price: 'LKR 150/kg', status: 'Active'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: demoProducts.length,
        itemBuilder: (context, index) {
          final p = demoProducts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xffe8f5e9),
                child: const Icon(Icons.eco_rounded, color: Color(0xff1f7a4d)),
              ),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${p.farmer} · ${p.price}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.status == 'Active' ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  p.status,
                  style: TextStyle(
                    fontSize: 12,
                    color: p.status == 'Active' ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Manage Orders Screen ---
class _ManageOrdersScreen extends StatelessWidget {
  const _ManageOrdersScreen();

  @override
  Widget build(BuildContext context) {
    final demoOrders = [
      _DemoOrder(id: '#ORD-001', buyer: 'Hotel Lanka', product: 'Organic Tomatoes', amount: 'LKR 8,400', status: 'In transit'),
      _DemoOrder(id: '#ORD-002', buyer: 'Fresh Mart', product: 'Cavendish Bananas', amount: 'LKR 4,200', status: 'Delivered'),
      _DemoOrder(id: '#ORD-003', buyer: 'City Supermarket', product: 'Gotukola Bunches', amount: 'LKR 7,200', status: 'Pending'),
      _DemoOrder(id: '#ORD-004', buyer: 'Hotel Lanka', product: 'Green Chilli', amount: 'LKR 10,400', status: 'Confirmed'),
      _DemoOrder(id: '#ORD-005', buyer: 'Fresh Mart', product: 'Fresh Carrots', amount: 'LKR 5,100', status: 'Delivered'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Orders')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: demoOrders.length,
        itemBuilder: (context, index) {
          final o = demoOrders[index];
          final statusColor = o.status == 'Delivered'
              ? Colors.green
              : o.status == 'In transit'
                  ? Colors.blue
                  : o.status == 'Pending'
                      ? Colors.orange
                      : Colors.teal;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.1),
                child: Icon(Icons.receipt_long_rounded, color: statusColor),
              ),
              title: Text(
                '${o.id} - ${o.product}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${o.buyer} · ${o.amount}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  o.status,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Demo data classes ---
class _DemoUser {
  final String name;
  final String role;
  final String location;
  final String status;

  const _DemoUser({
    required this.name,
    required this.role,
    required this.location,
    required this.status,
  });
}

class _DemoProduct {
  final String name;
  final String farmer;
  final String price;
  final String status;

  const _DemoProduct({
    required this.name,
    required this.farmer,
    required this.price,
    required this.status,
  });
}

class _DemoOrder {
  final String id;
  final String buyer;
  final String product;
  final String amount;
  final String status;

  const _DemoOrder({
    required this.id,
    required this.buyer,
    required this.product,
    required this.amount,
    required this.status,
  });
}
