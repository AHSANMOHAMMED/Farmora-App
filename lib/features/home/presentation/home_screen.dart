import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import 'dashboard_screen.dart';
import '../../farmer/presentation/earnings_screen.dart';
import '../../farmer/presentation/farmer_products_screen.dart';
import '../../farmer/presentation/farmer_orders_screen.dart';
import '../../buyer/presentation/buyer_products_screen.dart';
import '../../buyer/presentation/buyer_orders_screen.dart';
import '../../transporter/presentation/available_jobs_screen.dart';
import '../../transporter/presentation/transporter_dashboard_screen.dart';
import '../../transporter/presentation/delivery_history_screen.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../admin/presentation/user_management_screen.dart';
import '../../admin/presentation/logistics_management_screen.dart';
import '../../admin/presentation/system_settings_screen.dart';

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

    // Initialize Firestore sync when user is authenticated
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && state.currentUserId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.initFromFirestore(firebaseUser.uid);
      });
    }

    List<Widget> screens;
    List<_NavItem> navItems;

    if (role == Role.farmer) {
      // Stitch bottom nav: Home, Products, Orders, Earnings, Profile
      screens = const [
        DashboardScreen(),
        FarmerProductsScreen(),
        FarmerOrdersScreen(),
        EarningsScreen(),
        ProfileScreen(),
      ];
      navItems = const [
        _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
        // Stitch uses potted_plant icon for Products
        _NavItem(label: 'Products', icon: Icons.local_florist_outlined, activeIcon: Icons.local_florist_rounded),
        _NavItem(label: 'Orders', icon: Icons.shopping_basket_outlined, activeIcon: Icons.shopping_basket_rounded),
        // Stitch uses payments icon for Earnings
        _NavItem(label: 'Earnings', icon: Icons.payments_outlined, activeIcon: Icons.payments_rounded),
        _NavItem(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
      ];
    } else if (role == Role.transporter) {
      screens = const [
        TransporterDashboardScreen(),
        AvailableJobsScreen(),
        DeliveryHistoryScreen(),
        ProfileScreen(),
      ];
      navItems = const [
        _NavItem(label: 'Overview', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
        _NavItem(label: 'Jobs', icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping_rounded),
        _NavItem(label: 'Orders', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded),
        _NavItem(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
      ];
    } else if (role == Role.admin) {
      screens = const [
        AdminDashboardScreen(),
        UserManagementScreen(),
        LogisticsManagementScreen(),
        SystemSettingsScreen(),
      ];
      navItems = const [
        _NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded),
        _NavItem(label: 'Users', icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded),
        _NavItem(label: 'Logistics', icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping_rounded),
        _NavItem(label: 'Settings', icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded),
      ];
    } else {
      screens = const [
        DashboardScreen(),
        BuyerProductsScreen(),
        BuyerOrdersScreen(),
        ProfileScreen(),
      ];
      navItems = const [
        _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
        _NavItem(label: 'Products', icon: Icons.local_florist_outlined, activeIcon: Icons.local_florist_rounded),
        _NavItem(label: 'Orders', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded),
        _NavItem(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
      ];
    }

    return Scaffold(
      body: IndexedStack(
        index: tabIndex,
        children: screens,
      ),
      // Stitch: fixed bottom-0 w-full bg-surface/80 backdrop-blur shadow-[0_-1px_8px] h-20
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.92),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: NavigationBar(
          height: 72,
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Stitch: selected = text-primary font-bold, unselected = text-on-surface-variant
          indicatorColor: AppColors.primaryContainer.withOpacity(0.15),
          selectedIndex: tabIndex,
          onDestinationSelected: (i) => setState(() => tabIndex = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: navItems.asMap().entries.map(
            (e) {
              final isSelected = tabIndex == e.key;
              final item = e.value;
              return NavigationDestination(
                icon: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
                label: item.label,
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem({required this.label, required this.icon, required this.activeIcon});
}

/// Alias for backward compatibility
typedef Home = HomeScreen;
