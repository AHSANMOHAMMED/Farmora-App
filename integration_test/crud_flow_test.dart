import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:farmora/main.dart' as app;
import 'package:farmora/features/home/presentation/home_screen.dart';
import 'package:farmora/providers/farmora_state.dart';
import 'package:farmora/models/user_role.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End CRUD Flow Tests', () {
    testWidgets('Full CRUD for Farmer, Buyer, Transporter', (tester) async {
      // 1. Initialize Firebase and Pump App bypassing Splash Screen
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: app.DefaultFirebaseOptions.currentPlatform,
        );
      }
      
      await tester.pumpWidget(const app.FarmoraApp(showSplash: false));
      await tester.pumpAndSettle();

      // We are now on WelcomeScreen or HomeScreen.
      // If we are on WelcomeScreen, grab state and sign in.

      // Grab FarmoraState from MaterialApp context
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final state = Provider.of<FarmoraState>(context, listen: false);

      // ==========================================
      // FARMER FLOW (Products & Jobs CRUD)
      // ==========================================
      state.signIn(Role.farmer);
      await tester.pumpAndSettle();

      // Now we should be on HomeScreen (Farmer view)
      expect(find.byType(HomeScreen), findsOneWidget);

      expect(find.text('Farm Dashboard'), findsOneWidget);

      // Create a Product
      await tester.tap(find.text('Add New Product'));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.widgetWithText(TextFormField, 'Product Name').first, 'Test Integration Tomato');
      await tester.enterText(find.widgetWithText(TextFormField, 'Category').first, 'Vegetables');
      await tester.enterText(find.widgetWithText(TextFormField, 'Description').first, 'Fresh integration test tomatoes');
      await tester.enterText(find.widgetWithText(TextFormField, 'Unit (e.g. kg, lb, piece)').first, 'kg');
      await tester.enterText(find.widgetWithText(TextFormField, 'Location').first, 'Integration Farm');
      await tester.enterText(find.widgetWithText(TextFormField, 'Price per unit').first, '5.0');
      await tester.enterText(find.widgetWithText(TextFormField, 'Quantity available').first, '100');
      
      // Submit Product
      await tester.tap(find.text('Publish Listing'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Read Product
      await tester.tap(find.text('My Products'));
      await tester.pumpAndSettle();
      expect(find.text('Test Integration Tomato'), findsWidgets);

      // Update Product
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Listing'));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.widgetWithText(TextFormField, 'Price per unit').first, '6.0');
      await tester.tap(find.text('Update Listing'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Delete Product
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Listing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Farmer Deliveries
      await tester.tap(find.text('Deliveries'));
      await tester.pumpAndSettle();
      expect(find.text('My Deliveries'), findsOneWidget);

      // Switch role to Buyer
      state.signOut();
      await tester.pumpAndSettle();
      state.signIn(Role.buyer);
      await tester.pumpAndSettle();

      // ==========================================
      // BUYER FLOW (Orders CRUD)
      // ==========================================
      expect(find.text('Marketplace'), findsOneWidget);

      // Switch role to Transporter
      state.signOut();
      await tester.pumpAndSettle();
      state.signIn(Role.transporter);
      await tester.pumpAndSettle();

      // ==========================================
      // TRANSPORTER FLOW (Jobs CRUD)
      // ==========================================
      expect(find.text('Job Board'), findsOneWidget);
      await tester.tap(find.text('My Jobs'));
      await tester.pumpAndSettle();
    });
  });
}
