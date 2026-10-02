import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../models/user_role.dart';
import '../../../../providers/farmora_state.dart';
import '../../../farmer/presentation/add_product_screen.dart';
import '../../../farmer/presentation/farm_workspace_screen.dart';
import '../../../inputs/presentation/input_catalog_screen.dart';
import '../../../shop/presentation/shop_screens.dart';
import '../../../community/presentation/community_screens.dart';
import '../../../farmer/presentation/crop_doctor_screen.dart';
import '../../../farmer/presentation/farmer_orders_screen.dart';
import '../../../farmer/presentation/farmer_offers_screen.dart';
import '../../../farmer/presentation/earnings_screen.dart';
import '../../../buyer/presentation/buyer_products_screen.dart';
import '../../../buyer/presentation/buyer_orders_screen.dart';
import '../../../transporter/presentation/available_jobs_screen.dart';
import '../../../transporter/presentation/delivery_history_screen.dart';
import '../../../profile/presentation/edit_profile_screen.dart';
import '../../../market/presentation/market_price_board_screen.dart';
import '../../../auth/presentation/session_actions.dart';
import '../../../carbon/presentation/carbon_screen.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../transporter/presentation/nearby_transporters_screen.dart';
import '../../../buyer/presentation/buyer_market_screen.dart';

class QuickActionsDrawer extends StatelessWidget {
  const QuickActionsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final role = state.role;
    final l10n = context.l10n;
    
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  const Icon(Icons.apps_rounded, color: AppColors.primary, size: 26),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Role Actions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (role == Role.farmer) ...[
                      _ActionTile(
                        icon: Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                        title: 'Add Produce',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddProductScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.agriculture_outlined,
                        color: const Color(0xFF33691E),
                        title: 'My Farm Workspace',
                        subtitle: 'Weather, crop management, finances & labor',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmWorkspaceScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.storefront_outlined,
                        color: const Color(0xFF4E342E),
                        title: l10n.inpTitle,
                        subtitle: l10n.inpSubtitle,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InputCatalogScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.store_mall_directory_outlined,
                        color: const Color(0xFF00695C),
                        title: l10n.shopMyStore,
                        subtitle: l10n.shopStoreSubtitle,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyFarmStoreScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.eco_outlined,
                        color: const Color(0xFF2E7D32),
                        title: l10n.co2Title,
                        subtitle: l10n.co2Subtitle,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CarbonScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.biotech_outlined,
                        color: const Color(0xFFAD1457),
                        title: l10n.cdTitle,
                        subtitle: l10n.cdSubtitle,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CropDoctorScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.support_agent_outlined,
                        color: const Color(0xFF283593),
                        title: l10n.conAskExpert,
                        subtitle: l10n.conAskSubtitle,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AskExpertScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.forum_outlined,
                        color: const Color(0xFF6D4C41),
                        title: l10n.comTitle,
                        subtitle: l10n.comSubtitle,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityFeedScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.receipt_long_outlined,
                        color: const Color(0xFFE65100),
                        title: 'Manage Orders',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmerOrdersScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.local_offer_outlined,
                        color: const Color(0xFF6A1B9A),
                        title: 'Price Offers',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmerOffersScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.payments_outlined,
                        color: AppColors.primary,
                        title: 'View Earnings',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EarningsScreen()));
                        },
                      ),
                    ] else if (role == Role.buyer) ...[
                      _ActionTile(
                        icon: Icons.favorite_border_rounded,
                        color: const Color(0xFFC62828),
                        title: l10n.shopWishlist,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WishlistScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.autorenew_rounded,
                        color: const Color(0xFF00695C),
                        title: l10n.shopMySubscriptions,
                        subtitle: l10n.shopBoxesSubtitle,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MySubscriptionsScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.storefront_outlined,
                        color: AppColors.primary,
                        title: 'Browse Produce',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BuyerProductsScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.shopping_bag_outlined,
                        color: const Color(0xFF1565C0),
                        title: 'My Orders',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BuyerOrdersScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.local_shipping_outlined,
                        color: const Color(0xFF0277BD),
                        title: 'Live Delivery Tracking',
                        subtitle: 'Track your shipments & driver route',
                        onTap: () {
                          Navigator.of(context).pop();
                          final activeOrders = state.orders.where((o) =>
                              o.status == 'in_transit' ||
                              o.status == 'accepted' ||
                              o.status == 'confirmed' ||
                              o.status == 'pending').toList();
                          if (activeOrders.isNotEmpty) {
                            AppNavigator.openLogisticsTracking(context, activeOrders.first);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No active in-transit deliveries. Opening My Orders.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BuyerOrdersScreen()));
                          }
                        },
                      ),
                      _ActionTile(
                        icon: Icons.near_me_rounded,
                        color: const Color(0xFF2E7D32),
                        title: 'Nearby Transporters',
                        subtitle: 'Find verified local logistics providers',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearbyTransportersScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.campaign_outlined,
                        color: const Color(0xFFE65100),
                        title: 'Market & Produce Requests',
                        subtitle: 'Request bulk produce & transport quotes',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BuyerMarketScreen()));
                        },
                      ),
                    ] else if (role == Role.transporter) ...[
                      _ActionTile(
                        icon: Icons.local_shipping_outlined,
                        color: AppColors.primary,
                        title: 'Available Jobs',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AvailableJobsScreen()));
                        },
                      ),
                      _ActionTile(
                        icon: Icons.history_rounded,
                        color: const Color(0xFF1565C0),
                        title: 'Delivery History',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeliveryHistoryScreen()));
                        },
                      ),
                    ],
                    const Divider(height: 24),
                    const Text(
                      'Common Settings & Account',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.person_outline_rounded,
                      color: AppColors.onSurface,
                      title: 'Edit Profile & Documents',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      },
                    ),
                    _ActionTile(
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFFC2185B),
                      title: 'Market Price Index',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MarketPriceBoardScreen()));
                      },
                    ),
                    _ActionTile(
                      icon: Icons.logout_rounded,
                      color: AppColors.error,
                      title: 'Sign Out',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await confirmAndSignOut(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
