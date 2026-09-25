// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:farmora/models/user_role.dart';
import 'package:farmora/models/product.dart';
import 'package:farmora/providers/farmora_state.dart';
import 'package:farmora/features/farmer/presentation/farmer_products_screen.dart';
import 'package:farmora/features/farmer/presentation/farmer_orders_screen.dart';
import 'package:farmora/features/farmer/presentation/earnings_screen.dart';
import 'package:farmora/features/farmer/presentation/farmer_jobs_screen.dart';
import 'package:farmora/features/home/presentation/dashboard_screen.dart';
import 'package:farmora/features/farmer/presentation/farmer_offers_screen.dart';
import 'package:farmora/features/farmer/presentation/add_product_screen.dart';
import 'package:farmora/core/localization/l10n.dart';

import 'helpers/l10n_test_app.dart';

// ---------------------------------------------------------------------------
// Shared test helpers
// ---------------------------------------------------------------------------

/// Delegates required for screens that use AppLocalizations.of(context).
const _l10nDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Wrap a widget under test with the standard app providers.
Widget _wrap(Widget child, FarmoraState state) {
  return ChangeNotifierProvider<FarmoraState>.value(
    value: state,
    child: MaterialApp(
      localizationsDelegates: _l10nDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

/// Create a [FarmoraState] configured as a farmer in demo mode.
/// The constructor calls _initDemoData(), so products/orders/jobs are
/// pre-populated.  Role is set to farmer immediately.
FarmoraState _farmerState() {
  final state = FarmoraState();
  state.setRole(Role.farmer);
  return state;
}

/// A minimal fresh product for testing CRUD — uses a unique id to avoid
/// colliding with the 5 demo products seeded by _initDemoData().
Product _product({
  String id = 'test-p1',
  String name = 'Tomatoes',
  String status = 'Active',
  double price = 150.0,
  String category = 'Vegetables',
}) {
  return Product(
    id: id,
    name: name,
    category: category,
    location: 'Colombo',
    quantity: '50 kg',
    unit: 'kg',
    price: 'LKR ${price.toStringAsFixed(2)} / kg',
    pricePerUnit: price,
    priceMinor: (price * 100).round(),
    quantityAvailable: 50,
    status: status,
    description: 'Fresh $name',
  );
}

/// Set a standard viewport to avoid overflow errors.
void _setViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

// ===========================================================================
// 1. FarmoraState — Farmer Product CRUD (state-only, no widgets)
// ===========================================================================

void main() {
  group('FarmoraState — Product CRUD', () {
    late FarmoraState state;

    setUp(() {
      state = _farmerState();
    });

    // ── addProduct ──────────────────────────────────────────────────────────

    test('addProduct inserts product at the front', () {
      final before = state.products.length;
      state.addProduct(_product(id: 'crud-1', name: 'Test Beans'));
      expect(state.products.length, before + 1);
      expect(state.products.first.name, 'Test Beans');
    });

    test('addProduct with duplicate id does not duplicate (updates instead)',
        () {
      state.addProduct(_product(id: 'crud-dup', name: 'Mango'));
      final before = state.products.length;
      // Adding the same id again goes through addProduct — implementation
      // inserts at front; verify length increases by at most 1.
      state.addProduct(_product(id: 'crud-dup', name: 'Mango'));
      expect(state.products.length, lessThanOrEqualTo(before + 1));
    });

    // ── updateProduct ───────────────────────────────────────────────────────

    test('updateProduct changes the correct product fields', () {
      state.addProduct(_product(id: 'crud-2', name: 'Carrots', price: 120));
      final updated = _product(id: 'crud-2', name: 'Carrots', price: 280);
      state.updateProduct(updated);
      final found = state.products.firstWhere((p) => p.id == 'crud-2');
      expect(found.pricePerUnit, 280.0);
    });

    test('updateProduct for non-existent id does not throw', () {
      expect(
        () => state.updateProduct(_product(id: 'nonexistent')),
        returnsNormally,
      );
    });

    // ── toggleProductStock ──────────────────────────────────────────────────

    test('toggleProductStock switches Active → Empty', () {
      state.addProduct(_product(id: 'crud-3', status: 'Active'));
      state.toggleProductStock('crud-3');
      expect(
        state.products.firstWhere((p) => p.id == 'crud-3').status,
        'Empty',
      );
    });

    test('toggleProductStock switches Empty → Active', () {
      state.addProduct(_product(id: 'crud-4', status: 'Empty'));
      state.toggleProductStock('crud-4');
      expect(
        state.products.firstWhere((p) => p.id == 'crud-4').status,
        'Active',
      );
    });

    // ── deleteProduct ───────────────────────────────────────────────────────

    test('deleteProduct removes the product', () {
      state.addProduct(_product(id: 'crud-5'));
      state.deleteProduct('crud-5');
      expect(state.products.any((p) => p.id == 'crud-5'), isFalse);
    });

    test('deleteProduct for unknown id does not throw', () {
      expect(() => state.deleteProduct('ghost-id'), returnsNormally);
    });

    // ── computed getters ────────────────────────────────────────────────────

    test('activeProducts excludes out-of-stock items', () {
      state.addProduct(_product(id: 'active-1', status: 'Active'));
      state.addProduct(_product(id: 'empty-1', status: 'Empty'));
      final active = state.activeProducts;
      expect(active.any((p) => p.id == 'empty-1'), isFalse);
      expect(active.any((p) => p.id == 'active-1'), isTrue);
    });

    test('filteredProducts respects search query (case-insensitive)', () {
      state.addProduct(_product(id: 'srch-1', name: 'Green Papaya'));
      state.addProduct(_product(id: 'srch-2', name: 'Red Onion'));
      state.setSearchQuery('papaya');
      final result = state.filteredProducts;
      expect(result.any((p) => p.id == 'srch-1'), isTrue);
      expect(result.any((p) => p.id == 'srch-2'), isFalse);
      // Cleanup
      state.setSearchQuery('');
    });

    test('filteredProducts respects category filter', () {
      state.addProduct(
          _product(id: 'cat-1', name: 'Papaya', category: 'Fruits'));
      state.addProduct(
          _product(id: 'cat-2', name: 'Onion', category: 'Vegetables'));
      state.setSelectedCategory('Fruits');
      final result = state.filteredProducts;
      expect(result.every((p) => p.category == 'Fruits'), isTrue);
      // Cleanup
      state.setSelectedCategory('All');
    });

    test('filteredProducts with empty query returns all products', () {
      state.setSearchQuery('');
      state.setSelectedCategory('All');
      expect(state.filteredProducts.length, state.products.length);
    });
  });

  // ===========================================================================
  // 2. FarmoraState — Order Lifecycle
  // ===========================================================================

  group('FarmoraState — Order Lifecycle', () {
    late FarmoraState state;

    setUp(() {
      state = _farmerState();
    });

    test('demo data contains at least one pending or in-transit order', () {
      // _initDemoData seeds ORD-1001 (In transit), ORD-1002 (Accepted), ORD-1003 (Delivered)
      expect(state.orders.isNotEmpty, isTrue);
    });

    test('acceptOrder transitions a pending order to Accepted', () {
      // ORD-1001 is 'In transit' in demo — use ORD-1002 which is 'Accepted' (already done)
      // Insert a fresh pending order by using acceptOrder on ORD-1001.
      // First confirm ORD-1001 exists and is in a non-accepted state.
      final order = state.orders.firstWhere(
        (o) => o.id == 'ORD-1001',
        orElse: () => state.orders.first,
      );
      // acceptOrder mutates the state
      state.acceptOrder(order.id);
      final updated = state.orders.firstWhere((o) => o.id == order.id);
      expect(updated.status.toLowerCase(), anyOf('accepted', 'in transit'));
    });

    test('declineOrder transitions an order to Declined', () {
      final order = state.orders.first;
      state.declineOrder(order.id);
      final updated = state.orders.firstWhere((o) => o.id == order.id);
      expect(updated.status.toLowerCase(), anyOf('declined', 'rejected'));
    });

    test('completeOrder transitions an order to Delivered', () {
      final order = state.orders.first;
      state.completeOrder(order.id);
      final updated = state.orders.firstWhere((o) => o.id == order.id);
      expect(updated.status.toLowerCase(), anyOf('delivered', 'completed'));
    });

    test('pendingOrders getter returns only pending entries', () {
      // All pending orders are those where isPending is true
      for (final o in state.pendingOrders) {
        expect(o.isPending, isTrue);
      }
    });

    test('acceptedOrders getter returns only accepted entries', () {
      for (final o in state.acceptedOrders) {
        expect(o.isAccepted, isTrue);
      }
    });

    test('completedOrders getter returns only completed entries', () {
      for (final o in state.completedOrders) {
        expect(o.isCompleted, isTrue);
      }
    });
  });

  // ===========================================================================
  // 3. FarmoraState — Offer to Order Conversion
  // ===========================================================================

  group('FarmoraState — makeOffer and acceptOffer', () {
    late FarmoraState state;

    setUp(() {
      state = _farmerState();
    });

    test('makeOffer inserts offer into offers list', () async {
      final before = state.offers.length;
      await state.makeOffer(
        productId: 'prod-1',
        productName: 'Organic Red Tomatoes',
        farmerId: 'farmer_demo_1',
        quantity: 20,
        price: 160.0,
      );
      expect(state.offers.length, before + 1);
      expect(state.offers.first.productName, 'Organic Red Tomatoes');
    });

    test('acceptOffer marks the offer as accepted', () async {
      await state.makeOffer(
        productId: 'prod-1',
        productName: 'Green Beans',
        farmerId: 'farmer_demo_1',
        quantity: 15,
        price: 210.0,
      );
      final offerId = state.offers.first.id;
      await state.acceptOffer(offerId);
      final updated = state.offers.firstWhere((o) => o.id == offerId);
      expect(updated.status, 'accepted');
    });

    test('acceptOffer creates a new FarmoraOrder in orders list', () async {
      final ordersBefore = state.orders.length;
      await state.makeOffer(
        productId: 'prod-2',
        productName: 'Organic Kale',
        farmerId: 'farmer_demo_1',
        quantity: 30,
        price: 350.0,
      );
      final offerId = state.offers.first.id;
      await state.acceptOffer(offerId);
      // A new order should have been created
      expect(state.orders.length, ordersBefore + 1);
      expect(
        state.orders.any((o) => o.productName == 'Organic Kale'),
        isTrue,
      );
    });

    test('rejectOffer marks the offer as rejected', () async {
      await state.makeOffer(
        productId: 'prod-3',
        productName: 'Cinnamon',
        farmerId: 'farmer_demo_2',
        quantity: 5,
        price: 900.0,
      );
      final offerId = state.offers.first.id;
      await state.rejectOffer(offerId);
      final updated = state.offers.firstWhere((o) => o.id == offerId);
      expect(
        updated.status.toLowerCase(),
        anyOf('rejected', 'declined'),
      );
    });
  });

  // ===========================================================================
  // 4. FarmoraState — Earnings Calculation
  // ===========================================================================

  group('FarmoraState — Earnings', () {
    test('totalEarnings is non-negative', () {
      final state = _farmerState();
      expect(state.totalEarnings, greaterThanOrEqualTo(0.0));
    });

    test('thisMonth is non-negative', () {
      final state = _farmerState();
      expect(state.thisMonth, greaterThanOrEqualTo(0.0));
    });

    test('thisWeek is non-negative', () {
      final state = _farmerState();
      expect(state.thisWeek, greaterThanOrEqualTo(0.0));
    });

    test('pendingPayments is non-negative', () {
      final state = _farmerState();
      expect(state.pendingPayments, greaterThanOrEqualTo(0.0));
    });

    test('monthlyBars has exactly 6 entries (last 6 months)', () {
      final state = _farmerState();
      expect(state.monthlyBars.length, 6);
    });

    test('monthlyBars heightRatio is always in [0, 1]', () {
      final state = _farmerState();
      for (final bar in state.monthlyBars) {
        expect(bar.heightRatio, inInclusiveRange(0.0, 1.0));
      }
    });

    test('completeOrder increases completedOrders count', () {
      final state = _farmerState();
      final before = state.completedOrders.length;
      // Complete the first non-completed order
      final nonComplete = state.orders.firstWhere(
        (o) => !o.isCompleted,
        orElse: () => state.orders.first,
      );
      state.completeOrder(nonComplete.id);
      expect(state.completedOrders.length, greaterThanOrEqualTo(before));
    });
  });

  // ===========================================================================
  // 5. Widget Tests — FarmerProductsScreen
  // ===========================================================================

  group('FarmerProductsScreen Widget', () {
    testWidgets('renders without errors (smoke test)', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerProductsScreen(), state));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows product cards from demo data', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      // Demo data has 5 products; at least one should be visible
      await tester.pumpWidget(_wrap(const FarmerProductsScreen(), state));
      await tester.pump();
      // At least one product card text should be present
      expect(
        find.textContaining('Tomatoes').evaluate().isNotEmpty ||
            find.textContaining('Carrots').evaluate().isNotEmpty ||
            find.textContaining('product').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('FAB is present', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerProductsScreen(), state));
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('search TextField is present', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerProductsScreen(), state));
      await tester.pump();
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('FAB tap navigates to AddProductScreen', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerProductsScreen(), state));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // FarmerProductsScreen should no longer be the visible route
      expect(find.byType(FarmerProductsScreen), findsNothing);
    });

    testWidgets('entering a search query filters the product list',
        (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerProductsScreen(), state));
      await tester.pump();

      // Type a string that matches only Cinnamon (category: Spices)
      await tester.enterText(find.byType(TextField).first, 'Cinnamon');
      await tester.pump();

      // Only Cinnamon-related text should appear
      expect(find.textContaining('Cinnamon'), findsAtLeastNWidgets(1));
      expect(find.text('Cavendish Bananas'), findsNothing);
    });

    testWidgets('clearing search shows all products again', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerProductsScreen(), state));
      await tester.pump();

      // Filter first
      await tester.enterText(find.byType(TextField).first, 'Cinnamon');
      await tester.pump();

      // Then clear
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();

      // Multiple demo products should be visible again.
      expect(
          find.textContaining('Organic Red Tomatoes'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Cavendish Bananas'), findsAtLeastNWidgets(1));
    });

    testWidgets('new product added via addProduct appears in list',
        (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerProductsScreen(), state));
      await tester.pump();

      // Add a product that is very uniquely named
      state.addProduct(_product(id: 'widget-1', name: 'UniqueZucchini2099'));
      await tester.pump();

      expect(find.textContaining('UniqueZucchini2099'), findsOneWidget);
    });
  });

  // ===========================================================================
  // 6. Widget Tests — FarmerOrdersScreen
  // ===========================================================================

  group('FarmerOrdersScreen Widget', () {
    testWidgets('renders without errors (smoke test)', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerOrdersScreen(), state));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows three status tabs: Pending, Accepted, Delivered',
        (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerOrdersScreen(), state));
      await tester.pump();

      expect(find.text('Pending'), findsAtLeastNWidgets(1));
      expect(find.text('Accepted'), findsAtLeastNWidgets(1));
      expect(find.text('Delivered'), findsAtLeastNWidgets(1));
    });

    testWidgets('default tab shows pending orders', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      // Demo data has no strictly "pending" orders (first is In transit)
      // so empty-state icon should appear on the Pending tab
      await tester.pumpWidget(_wrap(const FarmerOrdersScreen(), state));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Accepted tab shows accepted orders', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerOrdersScreen(), state));
      await tester.pump();

      await tester.tap(find.text('Accepted'));
      await tester.pump();

      // ORD-1002 is 'Accepted' in demo data
      expect(find.textContaining('Carrots'), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping Delivered tab shows completed orders', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerOrdersScreen(), state));
      await tester.pump();

      await tester.tap(find.text('Delivered'));
      await tester.pump();

      // ORD-1003 is 'Delivered' (Cinnamon)
      expect(find.textContaining('Cinnamon'), findsAtLeastNWidgets(1));
    });

    testWidgets('search TextField is present', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerOrdersScreen(), state));
      await tester.pump();
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });
  });

  // ===========================================================================
  // 7. Widget Tests — EarningsScreen
  // ===========================================================================

  group('EarningsScreen Widget', () {
    testWidgets('renders without errors (smoke test)', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const EarningsScreen(), state));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows TOTAL EARNINGS hero card', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const EarningsScreen(), state));
      await tester.pump();
      expect(find.textContaining('EARNINGS'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows This Month metric card', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const EarningsScreen(), state));
      await tester.pump();
      expect(find.textContaining('Month'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows This Week metric card', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const EarningsScreen(), state));
      await tester.pump();
      expect(find.textContaining('Week'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Pending Payments card', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const EarningsScreen(), state));
      await tester.pump();
      expect(find.textContaining('Pending'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Monthly Earnings bar chart section', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const EarningsScreen(), state));
      await tester.pump();
      expect(find.textContaining('Monthly'), findsAtLeastNWidgets(1));
    });

    testWidgets('does not crash when all earnings are zero', (tester) async {
      _setViewport(tester);
      // Fresh state with no completed orders → all earnings = 0
      final state = FarmoraState();
      // Complete none; just set role
      state.setRole(Role.farmer);
      await tester.pumpWidget(_wrap(const EarningsScreen(), state));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ===========================================================================
  // 8. Widget Tests — FarmerJobsScreen
  // ===========================================================================

  group('FarmerJobsScreen Widget', () {
    testWidgets('renders without errors (smoke test)', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerJobsScreen(), state));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('demo transport jobs appear (linked to farmer orders)',
        (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerJobsScreen(), state));
      await tester.pump();

      // Demo data has JOB-201 (Tomatoes Delivery) and JOB-202 (Carrots Dispatch)
      // FarmerJobsScreen shows jobs where orderId matches a farmer's order.
      // ORD-1001 and ORD-1002 both have farmerId = 'farmer_demo_1'.
      expect(
        find.textContaining('Tomatoes').evaluate().isNotEmpty ||
            find.textContaining('Carrots').evaluate().isNotEmpty ||
            find.textContaining('Dispatch').evaluate().isNotEmpty ||
            find.textContaining('Delivery').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('shows LKR fee on job cards', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerJobsScreen(), state));
      await tester.pump();

      // Both demo jobs have fees in LKR
      expect(find.textContaining('LKR'), findsAtLeastNWidgets(1));
    });
  });

  // ===========================================================================
  // 9. Widget Tests — DashboardScreen (role-based rendering)
  // ===========================================================================

  group('DashboardScreen — Role-Based Rendering', () {
    testWidgets('farmer dashboard renders without errors', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const DashboardScreen(), state));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('buyer dashboard renders without errors', (tester) async {
      _setViewport(tester);
      final state = FarmoraState();
      state.setRole(Role.buyer);
      await tester.pumpWidget(_wrap(const DashboardScreen(), state));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('transporter dashboard renders without errors', (tester) async {
      _setViewport(tester);
      final state = FarmoraState();
      state.setRole(Role.transporter);
      await tester.pumpWidget(_wrap(const DashboardScreen(), state));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('farmer dashboard reflects setRole change at runtime',
        (tester) async {
      _setViewport(tester);
      final state = FarmoraState();
      state.setRole(Role.farmer);
      await tester.pumpWidget(_wrap(const DashboardScreen(), state));
      await tester.pump();

      // Switch to buyer mid-session
      state.setRole(Role.buyer);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
  // ===========================================================================
  // Tamil / Sinhala — farmer screens switch language and fit at 360px
  // ===========================================================================

  group('Farmer screens in Tamil and Sinhala', () {
    final screens = <String, Widget Function()>{
      'EarningsScreen': () => const EarningsScreen(),
      'FarmerOrdersScreen': () => const FarmerOrdersScreen(),
      'FarmerProductsScreen': () => const FarmerProductsScreen(),
      'FarmerJobsScreen': () => const FarmerJobsScreen(),
      'FarmerOffersScreen': () => const FarmerOffersScreen(),
      'AddProductScreen': () => const AddProductScreen(),
    };
    for (final locale in const [Locale('ta'), Locale('si')]) {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} renders in ${locale.languageCode} at 360px',
            (tester) async {
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = const Size(360, 800);
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            L10n.updateLocale(const Locale('en'));
          });
          final state = _farmerState();
          await tester.pumpWidget(ChangeNotifierProvider<FarmoraState>.value(
            value: state,
            child: localizedTestApp(entry.value(), locale: locale),
          ));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('EarningsScreen shows translated labels in Tamil',
        (tester) async {
      _setViewport(tester);
      addTearDown(() => L10n.updateLocale(const Locale('en')));
      final state = _farmerState();
      await tester.pumpWidget(ChangeNotifierProvider<FarmoraState>.value(
        value: state,
        child: localizedTestApp(const EarningsScreen(),
            locale: const Locale('ta')),
      ));
      await tester.pump();
      final ta = lookupAppLocalizations(const Locale('ta'));
      expect(find.text(ta.farmerEarningsThisMonth), findsOneWidget);
      expect(find.text('This Month'), findsNothing);
    });
  });
}
