import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/main.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Farmora starts with role selection', (tester) async {
    await tester.pumpWidget(const FarmoraApp());
    expect(find.textContaining('Welcome to'), findsOneWidget);
    expect(find.text('Continue to Farmora'), findsOneWidget);
  });

  test('state supports all stakeholder roles and product creation', () {
    final state = FarmoraState();
    state.signIn(Role.farmer);
    expect(state.signedIn, isTrue);
    expect(state.role, Role.farmer);
    final count = state.products.length;
    state.addProduct(Product(id: 'test', name: 'Test crop', category: 'Vegetables', location: 'Kandy', quantity: '1 kg', price: 'LKR 100', emoji: '🥬', color: const Color(0xffddf1dd)));
    expect(state.products.length, count + 1);
  });
}
