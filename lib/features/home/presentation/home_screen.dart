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
  bool _isSidebarCollapsed = false;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                _buildSidebar(
                  context: context,
                  state: state,
                  role: role,
                  navItems: navItems,
                  selectedIndex: safeTabIndex,
                  isCollapsed: _isSidebarCollapsed,
                  onToggleCollapse: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                  onSelectTab: (index) {
                    setState(() {
                      tabIndex = index;
                    });
                  },
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.outlineVariant.withValues(alpha: 0.35),
                ),
                Expanded(
                  child: IndexedStack(
                    index: safeTabIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          );
        }

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
      },
    );
  }

  Widget _buildSidebar({
    required BuildContext context,
    required FarmoraState state,
    required Role role,
    required List<_NavItem> navItems,
    required int selectedIndex,
    required bool isCollapsed,
    required VoidCallback onToggleCollapse,
    required ValueChanged<int> onSelectTab,
  }) {
    final double sidebarWidth = isCollapsed ? 76.0 : 256.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Logo + App title + Role badge + Collapse toggle
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 12.0 : 16.0,
                vertical: 18.0,
              ),
              child: isCollapsed
                  ? Column(
                      children: [
                        _buildBrandIcon(),
                        const SizedBox(height: 12),
                        IconButton(
                          icon: const Icon(Icons.menu_rounded,
                              size: 20, color: AppColors.outline),
                          tooltip: 'Expand sidebar',
                          splashRadius: 18,
                          onPressed: onToggleCollapse,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildBrandIcon(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Farmora',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      role.name.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (state.isVerified) ...[
                                      const SizedBox(width: 3),
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 11,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu_open_rounded,
                              size: 20, color: AppColors.outline),
                          tooltip: 'Collapse sidebar',
                          splashRadius: 18,
                          onPressed: onToggleCollapse,
                        ),
                      ],
                    ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.outlineVariant.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 8),

            // Navigation items list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                itemCount: navItems.length,
                itemBuilder: (context, i) {
                  final item = navItems[i];
                  final isSelected = selectedIndex == i;

                  if (isCollapsed) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Tooltip(
                        message: item.label,
                        preferBelow: false,
                        child: InkWell(
                          onTap: () => onSelectTab(i),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: 22,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: InkWell(
                      onTap: () => onSelectTab(i),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 20,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer: User card & Quick switch
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.outlineVariant.withValues(alpha: 0.25),
            ),
            Padding(
              padding: EdgeInsets.all(isCollapsed ? 8.0 : 12.0),
              child: isCollapsed
                  ? Tooltip(
                      message: state.displayName.isNotEmpty
                          ? state.displayName
                          : (state.phone.isNotEmpty
                              ? state.phone
                              : role.name),
                      child: InkWell(
                        onTap: () {
                          final profileIdx = navItems.indexWhere((item) =>
                              item.icon == Icons.person_outline_rounded ||
                              item.icon == Icons.settings_outlined);
                          if (profileIdx != -1) onSelectTab(profileIdx);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            (state.displayName.isNotEmpty
                                    ? state.displayName[0]
                                    : (state.phone.isNotEmpty
                                        ? state.phone[0]
                                        : 'U'))
                                .toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: () {
                        final profileIdx = navItems.indexWhere((item) =>
                            item.icon == Icons.person_outline_rounded ||
                            item.icon == Icons.settings_outlined);
                        if (profileIdx != -1) onSelectTab(profileIdx);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.15),
                              child: Text(
                                (state.displayName.isNotEmpty
                                        ? state.displayName[0]
                                        : (state.phone.isNotEmpty
                                            ? state.phone[0]
                                            : 'U'))
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    state.displayName.isNotEmpty
                                        ? state.displayName
                                        : (state.phone.isNotEmpty
                                            ? state.phone
                                            : 'Farmora User'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    state.phone.isNotEmpty
                                        ? state.phone
                                        : role.name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.outline,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBrandIcon() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.splashGradientStart,
            AppColors.splashGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.agriculture_rounded,
        color: Colors.white,
        size: 20,
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
