import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/main.dart';

void main() {
  testWidgets('Farmer UI renders Earnings, Products, and Orders with full Stitch design', (tester) async {
    await tester.pumpWidget(const FarmoraApp());

    // 1. Welcome screen role selection
    expect(find.text('Continue to Farmora'), findsOneWidget);
    await tester.tap(find.text('Continue to Farmora'));
    await tester.pumpAndSettle();

    // 2. Earnings Screen (Default Farmer view)
    expect(find.text('Earnings'), findsWidgets);
    expect(find.text('TOTAL EARNINGS'), findsOneWidget);
    expect(find.text('Monthly Earnings'), findsOneWidget);
    expect(find.text('Earnings History'), findsOneWidget);
    expect(find.text('View All Transactions'), findsOneWidget);

    // 3. Switch to Products Tab
    await tester.tap(find.byIcon(Icons.eco_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Products'), findsWidgets);
    expect(find.text('Heirloom Tomatoes'), findsOneWidget);
    expect(find.text('Dinosaur Kale'), findsOneWidget);
    expect(find.text('Nantes Carrots'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // 4. Open Add Product Screen
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('Basic Details'), findsOneWidget);
    expect(find.text('Inventory & Pricing'), findsOneWidget);
    expect(find.text('Publish Product'), findsOneWidget);

    // Back to Products
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // 5. Switch to Orders Tab
    await tester.tap(find.byIcon(Icons.shopping_basket_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Orders'), findsWidgets);
    expect(find.textContaining('Pending'), findsWidgets);
    expect(find.textContaining('Cherry Tomatoes'), findsOneWidget);

    // 6. Tap Order to open Order Detail
    await tester.tap(find.text('Cherry Tomatoes'));
    await tester.pumpAndSettle();

    expect(find.text('Order Detail'), findsOneWidget);
    expect(find.text('Order Summary'), findsOneWidget);
    expect(find.text('Accept Order'), findsOneWidget);
  });

  test('FarmerState accurately computes earnings and processes orders', () {
    final state = FarmoraState();
    state.signIn(Role.farmer);

    final initialEarnings = state.totalEarnings;
    final pendingCount = state.pendingOrders.length;

    // Accept an order
    final orderToAccept = state.pendingOrders.first;
    state.acceptOrder(orderToAccept.id);

    expect(state.pendingOrders.length, pendingCount - 1);
    expect(state.totalEarnings, initialEarnings + orderToAccept.totalAmountNumber);
    expect(state.transactions.first.orderNumber, orderToAccept.orderNumber);
  });
}
