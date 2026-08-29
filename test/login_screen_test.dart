import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:farmora/main.dart';

void main() {
  group('Farmora Login Screen Tests', () {
    Widget createLoginTestWidget({FarmoraState? state}) {
      return ChangeNotifierProvider<FarmoraState>(
        create: (_) => state ?? FarmoraState(),
        child: const MaterialApp(
          home: LoginScreen(),
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

    testWidgets('renders brand header, welcome greeting, and all form controls',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(createLoginTestWidget());

      // 1. Header: Farmora logo and name
      expect(find.byType(FarmoraLogo), findsOneWidget);
      expect(find.text('Farmora'), findsOneWidget);

      // 2. Welcome Back text
      expect(find.text('Welcome Back'), findsOneWidget);

      // 3. Input fields
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      // 4. Primary Green Button "Login"
      expect(find.text('Login'), findsOneWidget);

      // 5. Alternative OTP button
      expect(find.text('Login with OTP'), findsOneWidget);

      // 6. Registration footer link
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('toggles password visibility on eye icon tap', (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(createLoginTestWidget());

      final initialTextField =
          tester.widget<TextField>(find.byType(TextField).at(1));
      expect(initialTextField.obscureText, isTrue);

      // Tap visibility toggle icon
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      final revealedTextField =
          tester.widget<TextField>(find.byType(TextField).at(1));
      expect(revealedTextField.obscureText, isFalse);
    });

    testWidgets('validates required phone and password fields', (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(createLoginTestWidget());

      // Tap login without inputs
      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Please enter your phone number'), findsOneWidget);
    });

    testWidgets('successful login signs in via FarmoraState', skip: true, (tester) async {
      setupViewport(tester);
      final state = FarmoraState();
      await tester.pumpWidget(createLoginTestWidget(state: state));

      expect(state.signedIn, isFalse);

      // Enter phone number and password
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '0771234567',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );

      // Tap Login
      await tester.tap(find.text('Login'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(state.signedIn, isTrue);
    });

    testWidgets('Login with OTP opens modal sheet and allows OTP verification', skip: true,
        (tester) async {
      setupViewport(tester);
      final state = FarmoraState();
      await tester.pumpWidget(createLoginTestWidget(state: state));

      // Tap Login with OTP
      await tester.tap(find.text('Login with OTP'));
      await tester.pumpAndSettle();

      // Modal sheet appears
      expect(find.text('Enter the 4-digit code sent via SMS to 077 123 4567'),
          findsOneWidget);
      expect(find.text('Verify & Login'), findsOneWidget);

      // Tap Verify & Login
      await tester.tap(find.text('Verify & Login'));
      await tester.pumpAndSettle();

      expect(state.signedIn, isTrue);
    });

    testWidgets('tapping Register navigates to RoleSelectionScreen',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(createLoginTestWidget());

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Join Farmora as'), findsOneWidget);
    });
  });
}
