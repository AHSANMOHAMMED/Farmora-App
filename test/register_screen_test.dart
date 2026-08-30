import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:farmora/main.dart';

void main() {
  group('Farmora Register Screen Tests', () {
    Widget createRegisterTestWidget({
      FarmoraState? state,
      Role selectedRole = Role.farmer,
      VoidCallback? onRegistered,
    }) {
      return ChangeNotifierProvider<FarmoraState>(
        create: (_) => state ?? FarmoraState(),
        child: MaterialApp(
          home: RegisterScreen(
            selectedRole: selectedRole,
            onRegistered: onRegistered,
          ),
        ),
      );
    }

    void setupViewport(WidgetTester tester) {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(600, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets(
        'renders selected role banner, photo upload, and all form fields',
        (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(
        createRegisterTestWidget(selectedRole: Role.farmer),
      );

      // 1. Top Role Banner
      expect(find.text('Joining as Farmer'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);

      // 2. Profile Photo Uploader
      expect(find.text('Upload Photo (Optional)'), findsOneWidget);

      // 3. Form Input Fields
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('District / Location'), findsOneWidget);
      expect(find.text('Password'), findsNothing);
      expect(find.text('Confirm Password'), findsNothing);

      // 4. Primary Button "Create Account"
      expect(
          find.widgetWithText(FilledButton, 'Create Account'), findsOneWidget);

      // 5. Footer Log In link
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('displays correct role banner for Buyer and Transport Provider',
        (tester) async {
      setupViewport(tester);

      // Buyer
      await tester.pumpWidget(
        createRegisterTestWidget(selectedRole: Role.buyer),
      );
      expect(find.text('Joining as Buyer'), findsOneWidget);

      // Transport Provider
      await tester.pumpWidget(
        createRegisterTestWidget(selectedRole: Role.transporter),
      );
      expect(find.text('Joining as ${Role.transporter.label}'), findsOneWidget);
    });

    testWidgets('renders optional profile photo picker', (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(createRegisterTestWidget());

      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

      expect(find.text('Upload Photo (Optional)'), findsOneWidget);
    });

    testWidgets('validates required fields on submit', (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(createRegisterTestWidget());

      // Tap submit with empty form
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Enter your name, phone number, and district.'),
          findsOneWidget);
      expect(find.text('Please enter a password'), findsNothing);
    });

    testWidgets('successful registration signs in and calls onRegistered',
        skip: true, (tester) async {
      setupViewport(tester);
      final state = FarmoraState();
      bool registered = false;

      await tester.pumpWidget(
        createRegisterTestWidget(
          state: state,
          selectedRole: Role.farmer,
          onRegistered: () => registered = true,
        ),
      );

      expect(state.signedIn, isFalse);

      // Fill in all valid fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. Kamal Perera'),
        'Kamal Perera',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. 077 123 4567'),
        '0771234567',
      );

      // Select District
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nuwara Eliya').last);
      await tester.pumpAndSettle();

      // Passwords
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a strong password'),
        'pass1234',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'pass1234',
      );

      // Tap Create Account
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(state.signedIn, isTrue);
      expect(state.role, Role.farmer);
      expect(registered, isTrue);
    });

    testWidgets('tapping Log In navigates to LoginScreen', (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(createRegisterTestWidget());

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
    });
  });
}
