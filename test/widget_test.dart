import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:farmora/main.dart';
import 'package:farmora/core/localization/l10n.dart';
import 'package:farmora/core/localization/language_prefs.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({LanguagePrefs.key: 'en'});
  });

  testWidgets('FarmoraApp boots into the splash screen with brand elements',
      (WidgetTester tester) async {
    // Build the real app shell. The splash screen is shown first and does not
    // require Firebase, so this works as a pure widget smoke test.
    await tester.pumpWidget(const FarmoraApp());

    // Splash is displayed with the brand identity while initialization runs.
    expect(find.text('Farmora'), findsOneWidget);
    expect(find.text('Connecting Farmers, Buyers & Transport'), findsOneWidget);

    // The app has not navigated past the splash yet (2.6s timer + transition).
    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('the saved language is used from the very first frame',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FarmoraApp(initialLanguageCode: 'ta'));

    final ta = lookupAppLocalizations(const Locale('ta'));
    expect(find.text(ta.splashTagline), findsOneWidget);
    expect(find.text('Connecting Farmers, Buyers & Transport'), findsNothing);
    expect(L10n.current.localeName, 'ta');
  });

  testWidgets('without an initial language the saved one is restored',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({LanguagePrefs.key: 'si'});
    await tester.pumpWidget(const FarmoraApp());
    await tester.pump();
    await tester.pump();

    final si = lookupAppLocalizations(const Locale('si'));
    expect(find.text(si.splashTagline), findsOneWidget);
  });
}
