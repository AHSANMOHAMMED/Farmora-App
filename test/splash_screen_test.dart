import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/main.dart';

void main() {
  group('Farmora Splash Screen Tests', () {
    testWidgets('renders brand title, logo, and full agricultural tagline',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(
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

    testWidgets('renders soft green gradient background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(
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

    testWidgets('executes onInitializationComplete callback on timer completion',
        (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
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
        MaterialApp(
          home: SplashScreen(
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
