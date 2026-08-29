import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:farmora/main.dart';

void main() {
  group('Farmora Role Selection Screen Tests', () {
    Widget createRoleTestWidget({
      FarmoraState? state,
      Role? initialRole,
      ValueChanged<Role>? onRoleSelected,
    }) {
      return ChangeNotifierProvider<FarmoraState>(
        create: (_) => state ?? FarmoraState(),
        child: MaterialApp(
          home: RoleSelectionScreen(
            initialRole: initialRole,
            onRoleSelected: onRoleSelected,
          ),
        ),
      );
    }

    void setupViewport(WidgetTester tester) {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(600, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets(
        'renders title "Join Farmora as" and all 3 selectable cards with descriptions',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(createRoleTestWidget());

      // 1. Title
      expect(find.text('Join Farmora as'), findsOneWidget);

      // 2. Card 1: Farmer
      expect(find.text('Farmer'), findsOneWidget);
      expect(find.text('I want to sell my products'), findsOneWidget);
      expect(find.byIcon(Icons.agriculture_rounded), findsOneWidget);

      // 3. Card 2: Buyer
      expect(find.text('Buyer'), findsOneWidget);
      expect(find.text('I want to buy products'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_basket_rounded), findsOneWidget);

      // 4. Card 3: Transport Provider
      expect(find.text('Transport Provider'), findsOneWidget);
      expect(find.text('I want to deliver products'), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping_rounded), findsOneWidget);

      // 5. Continue button is disabled initially
      final continueButton =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(continueButton.onPressed, isNull);
    });

    testWidgets('selecting a role enables the Continue button and navigates to RegisterScreen',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(createRoleTestWidget());

      // Continue button is initially disabled
      FilledButton continueButton =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(continueButton.onPressed, isNull);

      // Tap on the Farmer card
      await tester.tap(find.text('Farmer'));
      await tester.pumpAndSettle();

      // Checkmark icon appears
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Continue button is now enabled
      continueButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(continueButton.onPressed, isNotNull);

      // Tap Continue
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Create Account'), findsOneWidget);
      expect(find.text('Joining as Farmer'), findsOneWidget);
    });

    testWidgets('selecting different roles updates the selection and callback',
        (tester) async {
      setupViewport(tester);
      Role? selected;
      await tester.pumpWidget(
        createRoleTestWidget(
          onRoleSelected: (r) => selected = r,
        ),
      );

      // Select Transport Provider
      await tester.tap(find.text('Transport Provider'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(selected, Role.transporter);
    });

    testWidgets('tapping Log In navigates to LoginScreen',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(createRoleTestWidget());

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
    });
  });
}
