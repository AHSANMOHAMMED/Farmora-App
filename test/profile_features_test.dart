import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';

import 'package:farmora/features/profile/presentation/edit_profile_screen.dart';
import 'package:farmora/features/profile/presentation/language_picker.dart';
import 'package:farmora/features/profile/presentation/profile_screen.dart';
import 'package:farmora/models/user_role.dart';
import 'package:farmora/providers/farmora_state.dart';

/// A valid 1x1 transparent PNG so Image.memory can decode it in tests.
const List<int> _k1x1Png = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

/// Platform fake returning a fake picked image so the photo-change flow can
/// be exercised without a real gallery picker.
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

Widget _wrap(FarmoraState state, Widget child) {
  return ChangeNotifierProvider<FarmoraState>.value(
    value: state,
    child: MaterialApp(home: child),
  );
}

void main() {
  tearDown(() {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(
      XFile.fromData(
        Uint8List.fromList(_k1x1Png),
        name: 'profile.jpg',
        mimeType: 'image/png',
      ),
    );
  });

  group('ProfileScreen regression tests (Kajana features)', () {
    testWidgets('renders avatar fallback, name and location row',
        (tester) async {
      final state = FarmoraState()
        ..displayName = 'Nimal Perera'
        ..district = 'Kandy'
        ..role = Role.farmer;

      await tester.pumpWidget(_wrap(state, const ProfileScreen()));

      expect(find.text('Nimal Perera'), findsOneWidget);
      // Single combined location/role row (no duplicated district line).
      expect(find.text('Kandy, Sri Lanka · Farmer'), findsOneWidget);
      expect(find.text('District: Kandy'), findsNothing);
    });

    testWidgets('shows Edit Profile entry and opens the edit screen',
        (tester) async {
      final state = FarmoraState()..role = Role.farmer;

      await tester.pumpWidget(_wrap(state, const ProfileScreen()));

      expect(find.text('Edit Profile'), findsOneWidget);

      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('shows verified badge only when state.isVerified is true',
        (tester) async {
      final state = FarmoraState()..role = Role.farmer;

      await tester.pumpWidget(_wrap(state, const ProfileScreen()));
      expect(find.byIcon(Icons.verified), findsNothing);

      final verifiedState = FarmoraState()
        ..role = Role.farmer
        ..isVerified = true;
      await tester.pumpWidget(_wrap(verifiedState, const ProfileScreen()));
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });
  });

  group('EditProfileScreen tests', () {
    Widget createEditTestWidget(FarmoraState state) {
      return _wrap(state, const EditProfileScreen());
    }

    testWidgets('pre-fills form with current profile values', (tester) async {
      final state = FarmoraState()
        ..role = Role.farmer
        ..displayName = 'Rohan Silva'
        ..district = 'Galle';

      await tester.pumpWidget(createEditTestWidget(state));
      await tester.pumpAndSettle();

      expect(find.text('Rohan Silva'), findsOneWidget);
      expect(find.text('Galle'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      final state = FarmoraState()
        ..role = Role.farmer
        ..displayName = '';

      await tester.pumpWidget(createEditTestWidget(state));

      await tester.tap(find.text('Save changes'));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('picking a photo previews it locally', (tester) async {
      ImagePickerPlatform.instance = _FakeImagePickerPlatform(
        XFile.fromData(
          Uint8List.fromList(_k1x1Png),
          name: 'new_avatar.jpg',
          mimeType: 'image/png',
        ),
      );

      final state = FarmoraState()..role = Role.farmer;
      await tester.pumpWidget(createEditTestWidget(state));

      await tester.tap(find.text('Change photo'));
      await tester.pump();
      await tester.pump();

      // A preview image widget exists after picking (decoding may fail in
      // tests but the state must hold the picked bytes).
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('save updates state locally (offline fallback)',
        (tester) async {
      final state = FarmoraState()
        ..role = Role.buyer
        ..displayName = 'Old Name'
        ..district = 'Colombo';

      await tester.pumpWidget(createEditTestWidget(state));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full name'), 'New Name');

      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(state.displayName, 'New Name');
      expect(state.district, 'Colombo'); // unchanged (same district)
    });
  });

  group('LanguagePicker tests', () {
    testWidgets('renders all three languages with the current one selected',
        (tester) async {
      final state = FarmoraState()..language = 'සිංහල';

      await tester.pumpWidget(_wrap(
        state,
        const Scaffold(body: SingleChildScrollView(child: LanguagePicker())),
      ));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('සිංහල'), findsOneWidget);
      expect(find.text('தமிழ்'), findsOneWidget);
      // Selected language shows the check icon (Kajana's redesigned picker).
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('tapping a language updates state.language', (tester) async {
      final state = FarmoraState()..language = 'English';

      await tester.pumpWidget(_wrap(
        state,
        const Scaffold(body: SingleChildScrollView(child: LanguagePicker())),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('தமிழ்'));
      await tester.pumpAndSettle();

      expect(state.language, 'தமிழ்');
    });
  });
}
