import 'package:flutter/material.dart';

import '../../features/buyer/presentation/buyer_order_detail_screen.dart';
import '../../features/buyer/presentation/product_detail_screen.dart';
import '../../features/farmer/presentation/logistics_tracking_screen.dart';
import '../../features/farmer/presentation/order_detail_screen.dart';
import '../../features/messaging/presentation/conversations_screen.dart';
import '../../features/transporter/presentation/collection_job_details_screen.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/user_role.dart';

/// Centralised navigation helpers for Farmora.
///
/// Previously every feature screen hand-rolled its own
/// `Navigator.of(context).push(MaterialPageRoute(builder: ...))` call, with
/// detail-screen imports scattered across dozens of call sites in farmer,
/// buyer, transporter and admin code (and inconsistent push styles —
/// `Navigator.push(context, ...)` vs `Navigator.of(context).push(...)`).
/// All cross-screen deep navigation now funnels through these helpers so
/// that:
///   * routes are pushed consistently (same transition, same navigator),
///   * each destination screen's import lives in exactly one place,
///   * role-specific routing decisions (e.g. which order-detail screen to
///     open) are made in one auditable spot, and
///   * future work (named routes / go_router / web deep links) only needs to
///     change this file instead of every feature screen.
class AppNavigator {
  AppNavigator._();

  /// Pushes [screen] onto the nearest Navigator.
  static Future<T?> push<T>(BuildContext context, Widget screen) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute<T>(builder: (_) => screen));
  }

  // ---------------------------------------------------------------------------
  // Product detail
  // ---------------------------------------------------------------------------

  /// Opens the product detail page (buyer-facing catalogue view).
  static Future<void> openProductDetail(BuildContext context, Product product) {
    return push(context, ProductDetailScreen(product: product));
  }

  // ---------------------------------------------------------------------------
  // Order detail (role-aware)
  // ---------------------------------------------------------------------------

  /// Opens the order detail screen matching the signed-in user's [role].
  /// Returns false when this role has no order detail screen (transporter,
  /// admin), mirroring the old `openOrderDetail` helper's contract.
  static bool openOrderDetail(
    BuildContext context,
    FarmoraOrder order,
    Role role,
  ) {
    final Widget? screen = switch (role) {
      Role.farmer => OrderDetailScreen(order: order),
      Role.buyer => BuyerOrderDetailScreen(order: order),
      _ => null,
    };
    if (screen == null) return false;
    push(context, screen);
    return true;
  }

  /// Opens the buyer-side order detail screen directly (callers already know
  /// they are in the buyer flow).
  static Future<void> openBuyerOrderDetail(
    BuildContext context,
    FarmoraOrder order,
  ) {
    return push(context, BuyerOrderDetailScreen(order: order));
  }

  /// Opens the farmer-side order detail screen directly.
  static Future<void> openFarmerOrderDetail(
    BuildContext context,
    FarmoraOrder order,
  ) {
    return push(context, OrderDetailScreen(order: order));
  }

  // ---------------------------------------------------------------------------
  // Logistics / tracking
  // ---------------------------------------------------------------------------

  /// Opens live logistics tracking for a farmer's [order].
  static Future<void> openLogisticsTracking(
    BuildContext context,
    FarmoraOrder order,
  ) {
    return push(context, LogisticsTrackingScreen(order: order));
  }

  /// Opens the messaging conversation thread bound to an order.
  static Future<void> openConversations(
    BuildContext context, {
    required String orderId,
  }) {
    return push(context, ConversationsScreen(orderId: orderId));
  }

  // ---------------------------------------------------------------------------
  // Transporter collection-job detail
  // ---------------------------------------------------------------------------

  /// Opens the collection job detail screen for [jobId]. Used by the jobs
  /// list, available-jobs list, dashboard cards and notification taps.
  static Future<void> openCollectionJobDetail(
    BuildContext context,
    String jobId,
  ) {
    return push(context, CollectionJobDetailsScreen(jobId: jobId));
  }
}
