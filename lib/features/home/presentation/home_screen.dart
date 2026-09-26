import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import 'dashboard_screen.dart';
import '../../farmer/presentation/earnings_screen.dart';
import '../../farmer/presentation/farmer_products_screen.dart';
import '../../farmer/presentation/farmer_orders_screen.dart';
import '../../farmer/presentation/farmer_jobs_screen.dart';
import '../../buyer/presentation/buyer_products_screen.dart';
import '../../buyer/presentation/buyer_orders_screen.dart';
import '../../transporter/presentation/logistics_available_jobs_screen.dart';
import '../../transporter/presentation/logistics_dashboard_screen.dart';
import '../../transporter/presentation/my_jobs_screen.dart';
import '../../transporter/presentation/transporter_notifications_screen.dart';
import '../../transporter/presentation/transporter_profile_screen.dart';
import '../../transporter/application/transporter_controller.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../admin/presentation/verification_review_screen.dart';
import '../../admin/presentation/user_management_screen.dart';
import '../../admin/presentation/logistics_management_screen.dart';
import '../../admin/presentation/system_settings_screen.dart';
import '../../buyer/presentation/buyer_offers_screen.dart';
import '../../buyer/presentation/buyer_market_screen.dart';
import 'widgets/awaiting_verification_view.dart';
import 'widgets/platform_gate_views.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tabIndex = 0;

  /// Installed app version (package_info_plus); null until read / on error.
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (e) {
      // Unknown version: the update gate stays open.
      debugPrint('App version unavailable: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final role = state.role;
    final transporterState = context.read<TransporterController>();

    // Initialize Firestore sync when user is authenticated
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && state.currentUserId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.initFromFirestore(firebaseUser.uid);
      });
    }

    if (firebaseUser != null &&
        role == Role.transporter &&
        transporterState.providerId != firebaseUser.uid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) transporterState.bindProvider(firebaseUser.uid);
      });
    }

    if (firebaseUser != null && !state.profileLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Platform gates (admins are exempt so they can switch them off).
    if (role != Role.admin) {
      if (state.maintenanceMode) return const MaintenanceView();
      final version = _appVersion;
      if (version != null && isVersionLower(version, state.minAppVersion)) {
        return UpdateRequiredView(
          currentVersion: version,
          minimumVersion: state.minAppVersion,
        );
      }
    }

    List<Widget> screens;
    List<_NavItem> navItems;

    final l10n = context.l10n;

    // Farmers and transporters trade only once verified; buyers are not
    // gated (they can still submit documents from their profile).
    final isUnverified = (role == Role.farmer || role == Role.transporter) &&
        !state.isVerified;
    if (isUnverified) {
      screens = [
        const AwaitingVerificationView(),
        role == Role.transporter
            ? const TransporterProfileScreen()
            : const ProfileScreen(),
      ];
      navItems = [
        const _NavItem(
          label: 'Verification',
          icon: Icons.hourglass_top_outlined,
          activeIcon: Icons.hourglass_top_rounded,
        ),
        _NavItem(
          label: l10n.profile,
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
        ),
      ];
    } else if (role == Role.farmer) {
      // Stitch bottom nav: Home, Products, Orders, Earnings, Profile
      screens = const [
        DashboardScreen(),
        FarmerProductsScreen(),
        FarmerOrdersScreen(),
        FarmerJobsScreen(),
        EarningsScreen(),
        ProfileScreen(),
      ];
      navItems = [
        _NavItem(
            label: l10n.homeNavHome,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded),
        _NavItem(
            label: l10n.homeNavProducts,
            icon: Icons.local_florist_outlined,
            activeIcon: Icons.local_florist_rounded),
        _NavItem(
            label: l10n.homeNavOrders,
            icon: Icons.shopping_basket_outlined,
            activeIcon: Icons.shopping_basket_rounded),
        _NavItem(
            label: l10n.homeNavDeliveries,
            icon: Icons.local_shipping_outlined,
            activeIcon: Icons.local_shipping_rounded),
        _NavItem(
            label: l10n.homeNavEarnings,
            icon: Icons.payments_outlined,
            activeIcon: Icons.payments_rounded),
        _NavItem(
            label: l10n.homeNavProfile,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded),
      ];
    } else if (role == Role.transporter) {
      screens = [
        LogisticsDashboardScreen(
          onBrowseJobs: () => setState(() => tabIndex = 1),
          onViewMyJobs: () => setState(() => tabIndex = 2),
          onOpenNotifications: () => setState(() => tabIndex = 3),
        ),
        const LogisticsAvailableJobsScreen(),
        const MyJobsScreen(),
        const TransporterNotificationsScreen(),
        const TransporterProfileScreen(),
      ];
      navItems = [
        _NavItem(
            label: l10n.homeNavHome,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded),
        _NavItem(
            label: l10n.homeNavJobs,
            icon: Icons.local_shipping_outlined,
            activeIcon: Icons.local_shipping_rounded),
        _NavItem(
            label: l10n.homeNavOrders,
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded),
        _NavItem(
            label: l10n.homeNavAlerts,
            icon: Icons.notifications_none_rounded,
            activeIcon: Icons.notifications_rounded),
        _NavItem(
            label: l10n.homeNavProfile,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded),
      ];
    } else if (role == Role.admin) {
      screens = const [
        AdminDashboardScreen(),
        VerificationReviewScreen(),
        UserManagementScreen(),
        LogisticsManagementScreen(),
        SystemSettingsScreen(),
      ];
      navItems = [
        _NavItem(
            label: l10n.homeNavDashboard,
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded),
        _NavItem(
            label: l10n.homeNavVerify,
            icon: Icons.verified_user_outlined,
            activeIcon: Icons.verified_user_rounded),
        _NavItem(
            label: l10n.homeNavUsers,
            icon: Icons.people_outline_rounded,
            activeIcon: Icons.people_rounded),
        _NavItem(
            label: l10n.homeNavLogistics,
            icon: Icons.local_shipping_outlined,
            activeIcon: Icons.local_shipping_rounded),
        _NavItem(
            label: l10n.homeNavSettings,
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded),
      ];
    } else {
      screens = const [
        DashboardScreen(),
        BuyerProductsScreen(),
        BuyerOffersScreen(),
        BuyerMarketScreen(),
        BuyerOrdersScreen(),
        ProfileScreen(),
      ];
      navItems = [
        _NavItem(
            label: l10n.homeNavHome,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded),
        _NavItem(
            label: l10n.homeNavProducts,
            icon: Icons.local_florist_outlined,
            activeIcon: Icons.local_florist_rounded),
        _NavItem(
            label: l10n.homeNavOffers,
            icon: Icons.local_offer_outlined,
            activeIcon: Icons.local_offer_rounded),
        const _NavItem(
            label: 'Requests',
            icon: Icons.campaign_outlined,
            activeIcon: Icons.campaign_rounded),
        _NavItem(
            label: l10n.homeNavOrders,
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded),
        _NavItem(
            label: l10n.homeNavProfile,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded),
      ];
    }

    final safeTabIndex = tabIndex >= screens.length ? 0 : tabIndex;
    return Scaffold(
      body: IndexedStack(
        index: safeTabIndex,
        children: screens,
      ),
      // Stitch: fixed bottom-0 w-full bg-surface/80 backdrop-blur shadow-[0_-1px_8px] h-20
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.92),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
          indicatorColor: AppColors.primaryContainer.withValues(alpha: 0.15),
          selectedIndex: safeTabIndex,
          onDestinationSelected: (i) => setState(() => tabIndex = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          // Small labels so Tamil/Sinhala fit six tabs on a 360px phone.
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              height: 1.1,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
          ),
          destinations: navItems.asMap().entries.map(
            (e) {
              final isSelected = safeTabIndex == e.key;
              final item = e.value;
              return NavigationDestination(
                icon: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                label: item.label,
                tooltip: item.label,
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
  const _NavItem(
      {required this.label, required this.icon, required this.activeIcon});
}

/// Alias for backward compatibility
typedef Home = HomeScreen;
