import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import 'dashboard_screen.dart';
import '../../buyer/presentation/products_screen.dart';
import '../../transporter/presentation/available_jobs_screen.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final role = state.role;

    final screens = role == Role.transporter
        ? const [
            DashboardScreen(),
            AvailableJobsScreen(),
            OrdersScreen(),
            ProfileScreen(),
          ]
        : const [
            DashboardScreen(),
            ProductsScreen(),
            OrdersScreen(),
            ProfileScreen(),
          ];

    final navLabels = role == Role.transporter
        ? ['Overview', 'Jobs', 'Orders', 'Profile']
        : ['Home', 'Products', 'Orders', 'Profile'];

    const navIcons = [
      Icons.home_rounded,
      Icons.eco_rounded,
      Icons.receipt_long_rounded,
      Icons.person_rounded,
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: tabIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) => setState(() => tabIndex = i),
        destinations: navLabels
            .asMap()
            .entries
            .map(
              (e) => NavigationDestination(
                icon: Icon(navIcons[e.key]),
                label: e.value,
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Alias for backward compatibility
typedef Home = HomeScreen;
