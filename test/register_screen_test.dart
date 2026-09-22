import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:farmora/main.dart';
import 'package:farmora/l10n/app_localizations.dart';

/// Localization delegates required by screens that call
/// `AppLocalizations.of(context)`.
const _l10nDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Platform fake returning a fake picked image so the optional
/// photo-uploader flow can be tested without a real gallery picker.
class _FakeImagePickerPlatform extends ImagePickerPlatform {
  final XFile pickImageResult;

  _FakeImagePickerPlatform(this.pickImageResult);

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return pickImageResult;
  }
}

void _mockImagePicker() {
  ImagePickerPlatform.instance = _FakeImagePickerPlatform(
    XFile.fromData(
      Uint8List.fromList(List.filled(16, 0xFF)),
      name: 'profile.jpg',
      mimeType: 'image/jpeg',
    ),
  );
}

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
          localizationsDelegates: _l10nDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

    testWidgets('renders selected role banner, photo upload, and all form fields',
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
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // 4. Primary Button "Create Account"
      expect(find.widgetWithText(FilledButton, 'Create Account'), findsOneWidget);

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

    testWidgets('toggles optional profile photo on tap', (tester) async {
      setupViewport(tester);
      _mockImagePicker();
      await tester.pumpWidget(createRegisterTestWidget());

      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

      // Tap to pick a photo
      await tester.tap(find.text('Upload Photo (Optional)'));
      await tester.pump();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('validates required fields on submit', (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(createRegisterTestWidget());

      // Tap submit with empty form
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(find.text('Please enter your phone number'), findsOneWidget);
      expect(find.text('Please select your district'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('validates matching confirm password', (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(createRegisterTestWidget());

      // Fill in Name, Phone
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
      await tester.tap(find.text('Kandy').last);
      await tester.pumpAndSettle();

      // Enter mismatched passwords
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a strong password'),
        'secret123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'mismatch123',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('successful registration signs in and calls onRegistered', skip: true,
        (tester) async {
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
      await tester.pumpWidget(
        ChangeNotifierProvider<FarmoraState>(
          create: (_) => FarmoraState(),
          child: const MaterialApp(
            localizationsDelegates: _l10nDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RegisterScreen(
              selectedRole: Role.farmer,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back!'), findsOneWidget);
    });
  });
}
