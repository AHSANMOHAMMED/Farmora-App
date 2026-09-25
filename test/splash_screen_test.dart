import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/main.dart';
import 'package:farmora/core/localization/l10n.dart';
import 'package:farmora/core/localization/language_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/l10n_test_app.dart';

void main() {
  setUp(() {
    // A language was already chosen, so the splash goes on to onboarding.
    SharedPreferences.setMockInitialValues({LanguagePrefs.key: 'en'});
  });

  group('Farmora Splash Screen Tests', () {
    testWidgets('renders brand title, logo, and full agricultural tagline',
        (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          const SplashScreen(
            duration: Duration.zero,
            autoNavigate: false,
          ),
        ),
      );

      // Verify App Name
      expect(find.text('Farmora'), findsOneWidget);

      // Verify Tagline
      expect(
        find.text('Connecting Farmers, Buyers & Transport'),
        findsOneWidget,
      );

      // Verify Agricultural Pillars
      expect(find.text('Farmers'), findsOneWidget);
      expect(find.text('Buyers'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);

      // Verify Logo
      expect(find.byType(FarmoraLogo), findsOneWidget);

      // Verify Loading indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Connecting agricultural network…'), findsOneWidget);
    });

    testWidgets('renders in Tamil and Sinhala without overflow at 360px',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final code in ['ta', 'si']) {
        await tester.pumpWidget(
          localizedTestApp(
            const SplashScreen(duration: Duration.zero, autoNavigate: false),
            locale: Locale(code),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        final l = lookupAppLocalizations(Locale(code));
        expect(find.text(l.splashTagline), findsOneWidget);
        expect(find.text(l.splashFarmers), findsOneWidget);
        expect(
            find.text('Connecting Farmers, Buyers & Transport'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('renders soft green gradient background', (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          const SplashScreen(
            duration: Duration.zero,
            autoNavigate: false,
          ),
        ),
      );

      final containerFinder = find.byType(Container).first;
      final Container container = tester.widget(containerFinder);
      final decoration = container.decoration as BoxDecoration?;

      expect(decoration, isNotNull);
      expect(decoration!.gradient, isA<LinearGradient>());

      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors.first, AppColors.splashGradientStart);
      expect(gradient.colors.last, AppColors.splashGradientEnd);
    });

    testWidgets(
        'executes onInitializationComplete callback on timer completion',
        (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        localizedTestApp(
          SplashScreen(
            duration: const Duration(milliseconds: 500),
            onInitializationComplete: () => completed = true,
          ),
        ),
      );

      expect(completed, isFalse);

      // Advance time past the splash duration
      await tester.pump(const Duration(milliseconds: 600));

      expect(completed, isTrue);
    });

    testWidgets('allows instant skip on tap', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        localizedTestApp(
          SplashScreen(
            duration: const Duration(seconds: 5),
            onInitializationComplete: () => completed = true,
          ),
        ),
      );

      expect(completed, isFalse);

      // Tap to skip
      await tester.tap(find.byType(SplashScreen));
      await tester.pump();

      expect(completed, isTrue);
    });

    testWidgets('with a saved language the splash goes straight to onboarding',
        (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          const SplashScreen(duration: Duration(milliseconds: 100)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(LanguageSelectionScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('first launch (no saved language) shows the language picker',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        localizedTestApp(
          const SplashScreen(duration: Duration(milliseconds: 100)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(LanguageSelectionScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      // Each language in its own script, and the title in all three.
      expect(find.text('English'), findsOneWidget);
      expect(find.text('தமிழ்'), findsOneWidget);
      expect(find.text('සිංහල'), findsOneWidget);
      expect(find.text('Choose your language'), findsOneWidget);

      // Choosing continues to onboarding and saves the choice.
      await tester.tap(find.text('සිංහල'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(await LanguagePrefs.load(), 'si');
    });

    testWidgets('FarmoraLogo renders custom painter with vector leaf and wheat',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FarmoraLogo(size: 100),
            ),
          ),
        ),
      );

      expect(find.byType(FarmoraLogo), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
