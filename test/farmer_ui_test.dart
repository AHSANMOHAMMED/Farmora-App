import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmora/models/order.dart';
import 'package:farmora/providers/farmora_state.dart';
import 'package:farmora/features/farmer/presentation/farmer_orders_screen.dart';
import 'package:farmora/features/farmer/presentation/farmer_products_screen.dart';
import 'package:farmora/features/farmer/presentation/add_product_screen.dart';
import 'package:farmora/features/farmer/presentation/earnings_screen.dart';
import 'package:farmora/features/farmer/presentation/order_detail_screen.dart';

Widget createTestWidget(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => FarmoraState(),
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Farmer Screens UI Tests', () {
    testWidgets('1. FarmerOrdersScreen renders header, tabs, and order cards', (tester) async {
      await tester.pumpWidget(createTestWidget(const FarmerOrdersScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Orders'), findsWidgets);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      expect(find.text('Cherry Tomatoes'), findsOneWidget);
      expect(find.text('Romaine Lettuce'), findsOneWidget);
      expect(find.text('Local Fresh Market'), findsOneWidget);
      expect(find.text('Green Leaf Bistro'), findsOneWidget);
      expect(find.text(r'$125.00'), findsOneWidget);
      expect(find.text(r'$75.50'), findsOneWidget);
      expect(find.text('Decline'), findsNWidgets(2));
      expect(find.text('Accept'), findsNWidgets(2));
    });

    testWidgets('2. FarmerProductsScreen renders search, filter, and product list', (tester) async {
      await tester.pumpWidget(createTestWidget(const FarmerProductsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Products'), findsWidgets);
      expect(find.text('Search products...'), findsOneWidget);
      expect(find.text('Heirloom Tomatoes'), findsOneWidget);
      expect(find.text('Dinosaur Kale'), findsOneWidget);
      expect(find.text('Black Beauty Eggplant'), findsOneWidget);
      expect(find.text('Nantes Carrots'), findsOneWidget);
      expect(find.text('ACTIVE'), findsNWidgets(3));
      expect(find.text('EMPTY'), findsOneWidget);
    });

    testWidgets('3. AddProductScreen renders all 4 sections and publish button', (tester) async {
      await tester.pumpWidget(createTestWidget(const AddProductScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Add Product'), findsOneWidget);
      expect(find.text('Basic Details'), findsOneWidget);
      expect(find.text('Inventory & Pricing'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Product Images'), findsOneWidget);
      expect(find.text('Publish Product'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('4. EarningsScreen renders hero card, metrics, and transaction history', (tester) async {
      await tester.pumpWidget(createTestWidget(const EarningsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Earnings'), findsWidgets);
      expect(find.text('TOTAL EARNINGS'), findsOneWidget);
      expect(find.text(r'$4,580.00'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text(r'$1,200.00'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text(r'$350.00'), findsOneWidget);
      expect(find.text('Pending Payments'), findsOneWidget);
      expect(find.text(r'$150.00'), findsOneWidget);
      expect(find.text('Monthly Earnings'), findsOneWidget);
      expect(find.text('Earnings History'), findsOneWidget);
      expect(find.text('Order #8892'), findsOneWidget);
      expect(find.text('View All Transactions'), findsOneWidget);
    });

    testWidgets('5. OrderDetailScreen renders order info, buyer details, and actions', (tester) async {
      final mockOrder = FarmoraOrder(
        id: 'ord-1042-b',
        buyerId: 'b-sarah',
        buyerName: 'Sarah Jenkins',
        farmerId: 'farmer-1',
        farmerName: 'Green Valley Farm',
        buyerBusinessName: 'Fresh Market Co.',
        buyerAddress: '450 West End Ave,\nDistribution Center Bay 4',
        buyerPhone: '+1 (555) 234-5678',
        buyerAvatar: 'assets/images/buyer_sarah.png',
        items: [
          OrderItem(
            id: 'item-fuji',
            productId: 'prod-fuji',
            name: '120 Crates Organic Fuji Apples',
            price: 45.0,
            quantity: 120,
            unit: 'Crates (40 lbs ea)',
          ),
        ],
        totalAmount: 5400.0,
        status: 'pending',
        deliveryAddress: '450 West End Ave,\nDistribution Center Bay 4',
        createdAt: DateTime(2023, 10, 24),
      );

      await tester.pumpWidget(createTestWidget(OrderDetailScreen(order: mockOrder)));
      await tester.pumpAndSettle();

      expect(find.text('Order Detail'), findsOneWidget);
      expect(find.text('ORDER #ORD-1042-B'), findsOneWidget);
      expect(find.text('PENDING REVIEW'), findsOneWidget);
      expect(find.text('120 Crates Organic Fuji Apples'), findsWidgets);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Fresh Market Co.'), findsOneWidget);
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text(r'$5,400.00'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Accept Order'), findsOneWidget);
    });
  });
}
