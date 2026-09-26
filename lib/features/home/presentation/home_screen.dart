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
import '../../admin/presentation/platform_analytics_screen.dart';
import '../../admin/presentation/dispute_resolution_screen.dart';
import '../../admin/presentation/review_management_screen.dart';
import '../../admin/presentation/market_price_management_screen.dart';
import '../../admin/presentation/market_price_review_screen.dart';
import '../../admin/presentation/settlement_management_screen.dart';
import '../../admin/presentation/broadcast_advisory_screen.dart';
import '../../admin/presentation/audit_log_screen.dart';
import '../../admin/presentation/server_maintenance_screen.dart';
import '../../../models/review_model.dart';
import '../../../models/verification_model.dart';
import '../../../models/dispute_model.dart';
import '../../buyer/presentation/buyer_offers_screen.dart';
import '../../buyer/presentation/buyer_market_screen.dart';
import 'widgets/awaiting_verification_view.dart';
import 'widgets/platform_gate_views.dart';
import '../../auth/presentation/session_actions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int tabIndex = 0;
  bool _isSidebarCollapsed = false;

  /// Installed app version (package_info_plus); null until read / on error.
  String? _appVersion;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
      final pendingVerifications = state.verificationDocs
          .where((d) => d.status == VerificationStatus.pending)
          .length;
      final pendingDisputes = state.adminStats.openDisputes > 0
          ? state.adminStats.openDisputes
          : state.disputes
              .where((d) =>
                  d.status == DisputeStatus.open ||
                  d.status == DisputeStatus.underReview)
              .length;
      final pendingReviews =
          state.reviews.where((r) => r.status == ReviewStatus.pending).length;

      screens = const [
        // Platform
        AdminOverviewScreen(),
        PlatformAnalyticsScreen(),
        // Operations
        VerificationReviewScreen(),
        UserManagementScreen(),
        DisputeResolutionScreen(),
        ReviewManagementScreen(),
        // Market & Fleet
        MarketPriceManagementScreen(),
        MarketPriceReviewScreen(),
        LogisticsManagementScreen(),
        // Finance & Audit
        SettlementManagementScreen(),
        BroadcastAdvisoryScreen(),
        AuditLogScreen(),
        // System
        ServerMaintenanceScreen(),
        SystemSettingsScreen(),
      ];
      navItems = [
        // Platform
        _NavItem(
          label: l10n.adminDashTabOverview,
          subtitle: 'Platform KPIs & GMV',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          section: 'Platform',
          accentColor: const Color(0xFF00C853),
        ),
        _NavItem(
          label: l10n.adminDashTabAnalytics,
          subtitle: 'Regional & Categories',
          icon: Icons.insights_outlined,
          activeIcon: Icons.insights_rounded,
          accentColor: const Color(0xFF7C4DFF),
        ),
        // Operations
        _NavItem(
          label: l10n.homeNavVerify,
          subtitle: 'KYC & Farmer Docs',
          icon: Icons.verified_user_outlined,
          activeIcon: Icons.verified_user_rounded,
          section: 'Operations',
          badgeCount: pendingVerifications,
          badgeColor: const Color(0xFFFF6D00),
          accentColor: const Color(0xFFFF9100),
        ),
        _NavItem(
          label: l10n.homeNavUsers,
          subtitle: 'Accounts & Roles',
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          accentColor: const Color(0xFF00B0FF),
        ),
        _NavItem(
          label: l10n.adminDashTabDisputes,
          subtitle: 'Arbitration & Claims',
          icon: Icons.gavel_outlined,
          activeIcon: Icons.gavel_rounded,
          badgeCount: pendingDisputes,
          badgeColor: AppColors.error,
          accentColor: const Color(0xFFFF5252),
        ),
        _NavItem(
          label: l10n.adminDashTabReviews,
          subtitle: 'Feedback Moderation',
          icon: Icons.rate_review_outlined,
          activeIcon: Icons.rate_review_rounded,
          badgeCount: pendingReviews,
          badgeColor: const Color(0xFF0288D1),
          accentColor: const Color(0xFF448AFF),
        ),
        // Market & Fleet
        _NavItem(
          label: l10n.adminDashTabMarket,
          subtitle: 'National Price Board',
          icon: Icons.trending_up_rounded,
          activeIcon: Icons.trending_up_rounded,
          section: 'Market & Fleet',
          accentColor: const Color(0xFF00BFA5),
        ),
        const _NavItem(
          label: 'Price Reports',
          subtitle: 'Field Submissions',
          icon: Icons.fact_check_outlined,
          activeIcon: Icons.fact_check_rounded,
          accentColor: Color(0xFFFFAB00),
        ),
        _NavItem(
          label: l10n.homeNavLogistics,
          subtitle: 'Fleet & Dispatch',
          icon: Icons.local_shipping_outlined,
          activeIcon: Icons.local_shipping_rounded,
          accentColor: const Color(0xFF2979FF),
        ),
        // Finance & Audit
        _NavItem(
          label: l10n.adminDashTabTreasury,
          subtitle: 'Escrow & Settlements',
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
          section: 'Finance & Audit',
          accentColor: const Color(0xFF00E676),
        ),
        _NavItem(
          label: l10n.adminDashTabAdvisories,
          subtitle: 'Emergency Broadcasts',
          icon: Icons.campaign_outlined,
          activeIcon: Icons.campaign_rounded,
          accentColor: const Color(0xFFFF6D00),
        ),
        _NavItem(
          label: l10n.adminDashTabAudit,
          subtitle: 'Security Event Logs',
          icon: Icons.shield_outlined,
          activeIcon: Icons.shield_rounded,
          accentColor: const Color(0xFF607D8B),
        ),
        // System
        _NavItem(
          label: l10n.adminDashTabServer,
          subtitle: 'Cloud Functions & Uptime',
          icon: Icons.cloud_sync_outlined,
          activeIcon: Icons.cloud_sync_rounded,
          section: 'System Control',
          accentColor: const Color(0xFFAA00FF),
        ),
        _NavItem(
          label: l10n.homeNavSettings,
          subtitle: 'Platform Parameters',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          accentColor: const Color(0xFF455A64),
        ),
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

        // On mobile, if there are more than 5 tabs (e.g. Admin with 14 operations),
        // show primary 5 on bottom bar and provide full sidebar in the drawer.
        final List<_NavItem> mobileNavItems;
        final int mobileSelectedIndex;
        final ValueChanged<int> onMobileSelect;

        if (navItems.length > 5) {
          mobileNavItems = [
            navItems[0], // Overview
            navItems[1], // Analytics
            navItems[2], // Verifications
            navItems[3], // Users
            navItems.last, // System Settings
          ];
          if (safeTabIndex == navItems.length - 1) {
            mobileSelectedIndex = 4;
          } else if (safeTabIndex < 4) {
            mobileSelectedIndex = safeTabIndex;
          } else {
            mobileSelectedIndex = 0;
          }
          onMobileSelect = (i) {
            if (i == 4) {
              setState(() => tabIndex = navItems.length - 1);
            } else {
              setState(() => tabIndex = i);
            }
          };
        } else {
          mobileNavItems = navItems;
          mobileSelectedIndex = safeTabIndex;
          onMobileSelect = (i) => setState(() => tabIndex = i);
        }

        return Scaffold(
          drawer: role == Role.admin
              ? Drawer(
                  child: _buildSidebar(
                    context: context,
                    state: state,
                    role: role,
                    navItems: navItems,
                    selectedIndex: safeTabIndex,
                    isCollapsed: false,
                    onToggleCollapse: () => Navigator.of(context).pop(),
                    onSelectTab: (index) {
                      setState(() => tabIndex = index);
                      Navigator.of(context).pop();
                    },
                  ),
                )
              : null,
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
              selectedIndex: mobileSelectedIndex,
              onDestinationSelected: onMobileSelect,
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
              destinations: mobileNavItems.asMap().entries.map(
                (e) {
                  final isSelected = mobileSelectedIndex == e.key;
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
    final isAdmin = role == Role.admin;
    final double sidebarWidth = isCollapsed ? 76.0 : (isAdmin ? 282.0 : 256.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Logo + App title + Role badge + Collapse toggle
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 12.0 : 16.0,
                vertical: 16.0,
              ),
              child: isCollapsed
                  ? Column(
                      children: [
                        _AnimatedBrandBadge(
                          animation: _pulseAnimation,
                          role: role,
                        ),
                        const SizedBox(height: 14),
                        IconButton(
                          icon: const Icon(Icons.menu_rounded,
                              size: 20, color: AppColors.outline),
                          tooltip: 'Expand navigation',
                          splashRadius: 18,
                          onPressed: onToggleCollapse,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _AnimatedBrandBadge(
                          animation: _pulseAnimation,
                          role: role,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isAdmin ? 'Farmora Console' : 'Farmora',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              isAdmin
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00C853)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color: const Color(0xFF00C853)
                                                  .withValues(alpha: 0.25),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: const Text(
                                            'SUPER ADMIN',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF007E2B),
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        _LivePulseDot(
                                          animation: _pulseAnimation,
                                          color: const Color(0xFF00E676),
                                          size: 6.5,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF00C853),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container(
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
            const SizedBox(height: 6),

            // Navigation items list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                itemCount: navItems.length,
                itemBuilder: (context, i) {
                  final item = navItems[i];
                  final isSelected = selectedIndex == i;
                  final showSectionHeader =
                      item.section != null && !isCollapsed;
                  final itemAccent = item.accentColor ?? AppColors.primary;

                  Widget tile;
                  if (isCollapsed) {
                    Widget iconWidget = Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? itemAccent.withValues(alpha: 0.16)
                            : itemAccent.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? itemAccent.withValues(alpha: 0.35)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        size: 20,
                        color: isSelected
                            ? itemAccent
                            : AppColors.onSurfaceVariant,
                      ),
                    );

                    if (item.badgeCount > 0) {
                      iconWidget = Badge.count(
                        count: item.badgeCount,
                        backgroundColor: item.badgeColor ?? itemAccent,
                        textColor: Colors.white,
                        child: iconWidget,
                      );
                    }

                    tile = Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Tooltip(
                        message: item.badgeCount > 0
                            ? '${item.label} (${item.badgeCount})'
                            : item.label,
                        preferBelow: false,
                        child: InkWell(
                          onTap: () => onSelectTab(i),
                          borderRadius: BorderRadius.circular(10),
                          child: Center(child: iconWidget),
                        ),
                      ),
                    );
                  } else {
                    tile = Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: InkWell(
                        onTap: () => onSelectTab(i),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? itemAccent.withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? itemAccent.withValues(alpha: 0.20)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Neon Indicator Pill
                              if (isSelected)
                                Container(
                                  width: 3.5,
                                  height: 24,
                                  margin: const EdgeInsets.only(right: 7),
                                  decoration: BoxDecoration(
                                    color: itemAccent,
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            itemAccent.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              // Ambient Icon Box
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? itemAccent.withValues(alpha: 0.16)
                                      : itemAccent.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(8.5),
                                  border: Border.all(
                                    color: isSelected
                                        ? itemAccent.withValues(alpha: 0.35)
                                        : itemAccent.withValues(alpha: 0.12),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  size: 18,
                                  color: isSelected
                                      ? itemAccent
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Title and Subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? itemAccent
                                            : AppColors.textPrimary,
                                        letterSpacing: -0.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.subtitle != null) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        item.subtitle!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                          color: isSelected
                                              ? itemAccent
                                                  .withValues(alpha: 0.85)
                                              : AppColors.textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Badge with animated breathing glow
                              if (item.badgeCount > 0) ...[
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, _) {
                                    final bColor =
                                        item.badgeColor ?? itemAccent;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bColor,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: bColor.withValues(
                                              alpha: 0.35 +
                                                  (_pulseAnimation.value *
                                                      0.35),
                                            ),
                                            blurRadius: 4 +
                                                (_pulseAnimation.value * 4),
                                            spreadRadius:
                                                _pulseAnimation.value * 1.2,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        item.badgeCount > 99
                                            ? '99+'
                                            : '${item.badgeCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (showSectionHeader) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (i > 0) const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                          child: Text(
                            item.section!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.outline.withValues(alpha: 0.8),
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        tile,
                      ],
                    );
                  }
                  return tile;
                },
              ),
            ),

            // Live status banner for admin
            if (isAdmin && !isCollapsed) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: state.maintenanceMode
                        ? [
                            AppColors.errorContainer.withValues(alpha: 0.45),
                            AppColors.errorContainer.withValues(alpha: 0.20),
                          ]
                        : const [
                            Color(0xFFF0FDF4),
                            Color(0xFFE8F5E9),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: state.maintenanceMode
                        ? AppColors.error.withValues(alpha: 0.3)
                        : const Color(0xFF00C853).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    _LivePulseDot(
                      animation: _pulseAnimation,
                      color: state.maintenanceMode
                          ? AppColors.error
                          : const Color(0xFF00C853),
                      size: 6.5,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.maintenanceMode
                                ? 'Maintenance Active'
                                : 'All Systems Operational',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: state.maintenanceMode
                                  ? AppColors.error
                                  : const Color(0xFF007E2B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            state.maintenanceMode
                                ? 'Public traffic redirected'
                                : '99.9% Uptime • Real-Time Sync',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: state.maintenanceMode
                                  ? AppColors.error.withValues(alpha: 0.8)
                                  : const Color(0xFF2E7D32),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Footer: User card & Quick switch
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.outlineVariant.withValues(alpha: 0.25),
            ),
            Padding(
              padding: EdgeInsets.all(isCollapsed ? 8.0 : 10.0),
              child: isCollapsed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
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
                              if (profileIdx != -1) {
                                onSelectTab(profileIdx);
                              } else if (isAdmin) {
                                confirmAndSignOut(context);
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isAdmin
                                      ? const [
                                          Color(0xFF00C853),
                                          Color(0xFF00B0FF),
                                          Color(0xFF7C4DFF),
                                        ]
                                      : const [
                                          AppColors.primary,
                                          Color(0xFF66BB6A),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 17,
                                backgroundColor: Colors.white,
                                child: Text(
                                  (state.displayName.isNotEmpty
                                          ? state.displayName[0]
                                          : (state.phone.isNotEmpty
                                              ? state.phone[0]
                                              : (isAdmin ? 'A' : 'U')))
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          tooltip: context.l10n.signOut,
                          splashRadius: 18,
                          onPressed: () => confirmAndSignOut(context),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            final profileIdx = navItems.indexWhere((item) =>
                                item.icon == Icons.person_outline_rounded ||
                                item.icon == Icons.settings_outlined);
                            if (profileIdx != -1) {
                              onSelectTab(profileIdx);
                            } else if (isAdmin) {
                              confirmAndSignOut(context);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: isAdmin
                                              ? const [
                                                  Color(0xFF00C853),
                                                  Color(0xFF00B0FF),
                                                  Color(0xFF7C4DFF),
                                                ]
                                              : const [
                                                  AppColors.primary,
                                                  Color(0xFF66BB6A),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.white,
                                        child: Text(
                                          (state.displayName.isNotEmpty
                                                  ? state.displayName[0]
                                                  : (state.phone.isNotEmpty
                                                      ? state.phone[0]
                                                      : (isAdmin ? 'A' : 'U')))
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00C853),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        state.displayName.isNotEmpty
                                            ? state.displayName
                                            : (state.phone.isNotEmpty
                                                ? state.phone
                                                : (isAdmin
                                                    ? 'Administrator'
                                                    : 'Farmora User')),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        state.phone.isNotEmpty
                                            ? state.phone
                                            : (isAdmin
                                                ? 'Platform Operator'
                                                : role.name),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    size: 19,
                                    color: AppColors.error,
                                  ),
                                  tooltip: context.l10n.signOut,
                                  splashRadius: 18,
                                  onPressed: () => confirmAndSignOut(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => confirmAndSignOut(context),
                              icon: const Icon(
                                Icons.logout_rounded,
                                size: 16,
                                color: AppColors.error,
                              ),
                              label: Text(
                                context.l10n.signOut,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppColors.error.withValues(alpha: 0.35),
                                  width: 0.9,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Realistic animated pulsing live indicator dot with outward radiating aura.
class _LivePulseDot extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double size;

  const _LivePulseDot({
    required this.animation,
    this.color = const Color(0xFF00E676),
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizedBox(
          width: size * 2.2,
          height: size * 2.2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radiating expanding wave
              Container(
                width: size * (1.2 + (animation.value * 0.9)),
                height: size * (1.2 + (animation.value * 0.9)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(
                    alpha: (0.35 * (1.0 - animation.value * 0.65))
                        .clamp(0.0, 1.0),
                  ),
                ),
              ),
              // Inner glowing core
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.8),
                      blurRadius: 4 + (animation.value * 3),
                      spreadRadius: animation.value * 1.2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Realistic 3D depth brand badge with ambient glow and top specular highlight.
class _AnimatedBrandBadge extends StatelessWidget {
  final Animation<double> animation;
  final Role role;

  const _AnimatedBrandBadge({
    required this.animation,
    this.role = Role.farmer,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == Role.admin;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final glowSpread = animation.value * 1.5;
        final glowAlpha = 0.22 + (animation.value * 0.15);

        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAdmin
                  ? const [
                      Color(0xFF003815),
                      Color(0xFF007E2B),
                      Color(0xFF00C853),
                    ]
                  : const [
                      AppColors.splashGradientStart,
                      AppColors.primary,
                      AppColors.splashGradientEnd,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: (isAdmin
                        ? const Color(0xFF00C853)
                        : AppColors.primary)
                    .withValues(alpha: glowAlpha),
                blurRadius: 6 + glowSpread * 2,
                spreadRadius: glowSpread,
                offset: const Offset(0, 1),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Specular gloss highlight on top half
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 17,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Icon(
                isAdmin
                    ? Icons.admin_panel_settings_rounded
                    : Icons.agriculture_rounded,
                color: Colors.white,
                size: isAdmin ? 22 : 20,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String? section;
  final int badgeCount;
  final Color? badgeColor;
  final Color? accentColor;
  final String? subtitle;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.section,
    this.badgeCount = 0,
    this.badgeColor,
    this.accentColor,
    this.subtitle,
  });
}

/// Alias for backward compatibility
typedef Home = HomeScreen;
