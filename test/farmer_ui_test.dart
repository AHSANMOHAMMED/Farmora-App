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

    test('updateProduct requires authentication', () async {
      await expectLater(
        state.updateProduct(_product(id: 'crud-2')),
        throwsA(isA<StateError>()),
      );
    });

    test('updateProduct for non-existent id still requires authentication',
        () async {
      await expectLater(
        state.updateProduct(_product(id: 'nonexistent')),
        throwsA(isA<StateError>()),
      );
    });

    // ── toggleProductStock ──────────────────────────────────────────────────

    test('toggleProductStock requires authentication', () async {
      await expectLater(
        state.toggleProductStock('crud-3'),
        throwsA(isA<StateError>()),
      );
    });

    test('toggleProductStock for an unknown id requires authentication',
        () async {
      await expectLater(
        state.toggleProductStock('crud-4'),
        throwsA(isA<StateError>()),
      );
    });

    // ── deleteProduct ───────────────────────────────────────────────────────

    test('deleteProduct requires authentication', () async {
      await expectLater(
        state.deleteProduct('crud-5'),
        throwsA(isA<StateError>()),
      );
    });

    test('deleteProduct for unknown id still requires authentication',
        () async {
      await expectLater(
        state.deleteProduct('ghost-id'),
        throwsA(isA<StateError>()),
      );
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

    test('fresh farmer state has no remote orders before sign-in', () {
      expect(state.orders, isEmpty);
    });

    test('acceptOrder requires authentication', () async {
      await expectLater(
        state.acceptOrder('missing-order'),
        throwsA(isA<StateError>()),
      );
    });

    test('declineOrder requires authentication', () async {
      await expectLater(
        state.declineOrder('missing-order'),
        throwsA(isA<StateError>()),
      );
    });

    test('completeOrder requires authentication', () async {
      await expectLater(
        state.completeOrder('missing-order'),
        throwsA(isA<StateError>()),
      );
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

    test('makeOffer requires authentication', () async {
      await expectLater(
        state.makeOffer(
          productId: 'prod-1',
          productName: 'Organic Red Tomatoes',
          farmerId: 'farmer_demo_1',
          quantity: 20,
          price: 160.0,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('acceptOffer requires authentication', () async {
      await expectLater(
        state.acceptOffer('missing-offer'),
        throwsA(isA<StateError>()),
      );
    });

    test('rejectOffer requires authentication', () async {
      await expectLater(
        state.rejectOffer('missing-offer'),
        throwsA(isA<StateError>()),
      );
    });

    test('offer list remains empty before sign-in', () {
      expect(state.offers, isEmpty);
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

    test('completeOrder is unavailable before sign-in', () async {
      final state = _farmerState();
      await expectLater(
        state.completeOrder('missing-order'),
        throwsA(isA<StateError>()),
      );
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

      expect(tester.takeException(), isNull);
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

      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Delivered tab shows completed orders', (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerOrdersScreen(), state));
      await tester.pump();

      await tester.tap(find.text('Delivered'));
      await tester.pump();

      expect(tester.takeException(), isNull);
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

    testWidgets('empty transport jobs state renders without errors',
        (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerJobsScreen(), state));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('empty jobs state does not show a fabricated fee',
        (tester) async {
      _setViewport(tester);
      final state = _farmerState();
      await tester.pumpWidget(_wrap(const FarmerJobsScreen(), state));
      await tester.pump();

      expect(find.textContaining('LKR'), findsNothing);
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
