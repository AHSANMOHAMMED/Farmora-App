import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:farmora/core/localization/language_prefs.dart';

import 'package:farmora/features/profile/presentation/edit_profile_screen.dart';
import 'package:farmora/features/profile/presentation/language_picker.dart';
import 'package:farmora/features/profile/presentation/profile_screen.dart';
import 'package:farmora/l10n/app_localizations.dart';
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

Widget _wrap(FarmoraState state, Widget child, {Locale? locale}) {
  return ChangeNotifierProvider<FarmoraState>.value(
    value: state,
    child: MaterialApp(
      locale: locale ?? state.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({LanguagePrefs.key: 'en'});
  });

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
      // One location line plus a role badge (no duplicated district line).
      expect(find.text('Kandy, Sri Lanka'), findsOneWidget);
      expect(find.text('Farmer'), findsOneWidget);
      expect(find.text('District: Kandy'), findsNothing);
    });

    testWidgets('shows Edit Profile entry and opens the edit screen',
        (tester) async {
      final state = FarmoraState()..role = Role.farmer;

      await tester.pumpWidget(_wrap(state, const ProfileScreen()));

      expect(find.text('Edit profile'), findsOneWidget);

      await tester.tap(find.text('Edit profile'));
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

    testWidgets('shows profile completeness with what is missing',
        (tester) async {
      final state = FarmoraState()
        ..role = Role.farmer
        ..district = 'Kandy';

      await tester.pumpWidget(_wrap(state, const ProfileScreen()));

      // district done; photo, farm, bank and verification missing → 1/5.
      expect(find.text('Profile 20% complete'), findsOneWidget);
      expect(find.text('Add photo'), findsOneWidget);
      expect(find.text('Add farm details'), findsOneWidget);
      expect(find.text('Add bank details'), findsOneWidget);
      expect(find.text('Get verified'), findsOneWidget);
      expect(find.text('Add district'), findsNothing);
    });

    testWidgets('shows farm name in the header and farm summary tile',
        (tester) async {
      final state = FarmoraState()
        ..role = Role.farmer
        ..farmName = 'Green Valley Farm'
        ..farmSize = '2 acres'
        ..mainCrops = ['Carrot', 'Leeks'];

      await tester.pumpWidget(_wrap(state, const ProfileScreen()));

      expect(find.text('Green Valley Farm'), findsOneWidget);
      expect(find.text('Green Valley Farm · 2 acres · Carrot, Leeks'),
          findsOneWidget);
    });

    testWidgets('buyer profile hides farmer-only sections', (tester) async {
      final state = FarmoraState()..role = Role.buyer;

      await tester.pumpWidget(_wrap(state, const ProfileScreen()));

      expect(find.text('Buyer'), findsOneWidget);
      expect(find.text('Farm details'), findsNothing);
      expect(find.text('Bank details'), findsNothing);
      expect(find.text('Account verification'), findsNothing);
    });

    testWidgets('renders in Tamil when the language is Tamil', (tester) async {
      final state = FarmoraState()
        ..role = Role.farmer
        ..language = 'தமிழ்';

      await tester.pumpWidget(_wrap(state, const ProfileScreen()));

      expect(find.text('சுயவிவரத்தைத் திருத்து'), findsOneWidget);
      expect(find.text('விவசாயி'), findsOneWidget);
      expect(find.text('Edit profile'), findsNothing);
    });

    for (final language in ['English', 'தமிழ்', 'සිංහල']) {
      testWidgets('no overflow at 360px width in $language', (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final state = FarmoraState()
          ..role = Role.farmer
          ..language = language
          ..displayName = 'Nimal Perera Wickramasinghe Bandara'
          ..district = 'Nuwara Eliya'
          ..farmName = 'Green Valley Organic Vegetable Farm'
          ..memberSince = DateTime(2024, 9, 1);

        await tester.pumpWidget(_wrap(state, const ProfileScreen()));
        await tester.pumpAndSettle();
        final scrollable = find.byType(Scrollable).first;
        for (var i = 0; i < 8; i++) {
          await tester.drag(scrollable, const Offset(0, -300));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('log out asks for confirmation', (tester) async {
      final state = FarmoraState()..role = Role.farmer;

      await tester.pumpWidget(_wrap(state, const ProfileScreen()));
      final logout = find.widgetWithText(OutlinedButton, 'Log out');
      await tester.scrollUntilVisible(logout, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(logout);
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsNothing);
    });

    testWidgets('delete account needs the confirmation checkbox',
        (tester) async {
      final state = FarmoraState()..role = Role.farmer;

      await tester.pumpWidget(_wrap(state, const ProfileScreen()));
      final delete = find.text('Delete account');
      await tester.scrollUntilVisible(delete, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(delete);
      await tester.pumpAndSettle();

      expect(find.text('Delete your account?'), findsOneWidget);
      FilledButton confirm() => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Delete account'));
      expect(confirm().onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(confirm().onPressed, isNotNull);
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

    testWidgets('farmers can edit farm details',
        (tester) async {
      final farmer = FarmoraState()
        ..role = Role.farmer
        ..displayName = 'Nimal'
        ..district = 'Kandy';
      await tester.pumpWidget(createEditTestWidget(farmer));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Farm name'), 'Hill Farm');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Main crops'), 'Carrot, Beans ,');
      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(farmer.farmName, 'Hill Farm');
      expect(farmer.mainCrops, ['Carrot', 'Beans']);
    });

    testWidgets('buyers do not see farm details', (tester) async {
      final buyer = FarmoraState()..role = Role.buyer;
      await tester.pumpWidget(createEditTestWidget(buyer));
      await tester.pumpAndSettle();
      expect(find.text('Farm name'), findsNothing);
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      final state = FarmoraState()
        ..role = Role.farmer
        ..displayName = '';

      await tester.pumpWidget(createEditTestWidget(state));

      await tester.tap(find.text('Save changes'));
      await tester.pump();

      expect(find.text('Please enter your name'), findsOneWidget);
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

    testWidgets('choosing a language saves it and confirms in that language',
        (tester) async {
      final state = FarmoraState()..language = 'English';
      final profileWrites = <String>[];
      state.debugProfileLanguageWriter = (code) async => profileWrites.add(code);

      await tester.pumpWidget(_wrap(
        state,
        const Scaffold(body: SingleChildScrollView(child: LanguagePicker())),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('සිංහල'));
      await tester.pumpAndSettle();

      expect(state.language, 'සිංහල');
      expect(state.locale, const Locale('si'));
      expect(profileWrites, ['si']);
      expect(await LanguagePrefs.load(), 'si');
      expect(find.text('භාෂාව සිංහල ලෙස වෙනස් කළා'), findsOneWidget);
    });

    testWidgets('a failed profile save shows a localized error',
        (tester) async {
      final state = FarmoraState()..language = 'English';
      state.debugProfileLanguageWriter =
          (code) async => throw Exception('offline');

      await tester.pumpWidget(_wrap(
        state,
        const Scaffold(body: SingleChildScrollView(child: LanguagePicker())),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('தமிழ்'));
      await tester.pumpAndSettle();

      // Still switched locally; the error is in the new language.
      expect(state.language, 'தமிழ்');
      expect(
        find.text(lookupAppLocalizations(const Locale('ta')).langSaveFailed),
        findsOneWidget,
      );
    });
  });
}
