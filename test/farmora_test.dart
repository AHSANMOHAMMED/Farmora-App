import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/main.dart';

void main() {
  testWidgets('Farmora starts with login when splash is disabled',
      (tester) async {
    await tester.pumpWidget(const FarmoraApp(showSplash: false));
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('Farmora starts with splash and transitions to login',
      (tester) async {
    await tester.pumpWidget(const FarmoraApp());
    expect(find.text('Farmora'), findsOneWidget);
    expect(find.text('Connecting Farmers, Buyers & Transport'), findsOneWidget);

    // Tap splash to transition to onboarding
    await tester.tap(find.byType(SplashScreen));
    await tester.pumpAndSettle();

    expect(find.text('Sell Your Harvest Directly'), findsOneWidget);

    // Skip onboarding to go to login
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });

  test('state supports all stakeholder roles and product creation', () {
    final state = FarmoraState();
    state.signIn(Role.farmer);
    expect(state.signedIn, isTrue);
    expect(state.role, Role.farmer);
    final count = state.products.length;
    state.addProduct(const Product(
        id: 'test',
        name: 'Test crop',
        category: 'Vegetables',
        location: 'Kandy',
        quantity: '1 kg',
        price: 'LKR 100',
        emoji: '🥬',
        color: Color(0xffddf1dd)));
    expect(state.products.length, count + 1);
  });
}
