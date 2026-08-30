import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/main.dart';

void main() {
  group('Farmora Onboarding Screens Tests', () {
    testWidgets(
        'Screen 1 renders farmer focus, headline, highlights, and action buttons',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Verify Screen 1 (Farmer) headline
      expect(find.text('Sell Your Harvest Directly'), findsOneWidget);
      expect(find.text('FOR FARMERS'), findsOneWidget);
      expect(
        find.textContaining('Connect directly with buyers without middlemen'),
        findsOneWidget,
      );

      // Verify highlights
      expect(find.text('Direct Sales'), findsOneWidget);
      expect(find.text('Fair Pricing'), findsOneWidget);
      expect(find.text('Fast Payout'), findsOneWidget);

      // Verify Navigation buttons
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Tapping Next navigates from Screen 1 -> Screen 2 -> Screen 3',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // 1. Initial on Farmer screen
      expect(find.text('Sell Your Harvest Directly'), findsOneWidget);

      // Advance to Screen 2 (Buyer)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Get Fresh Products Easily'), findsOneWidget);
      expect(find.text('FOR BUYERS'), findsOneWidget);
      expect(find.text('100% Farm Fresh'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Advance to Screen 3 (Transport)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Reliable Transport for Every Order'), findsOneWidget);
      expect(find.text('FOR TRANSPORTERS'), findsOneWidget);
      expect(find.text('Verified Cargo'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Back button navigates back to previous slide',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Advance to Screen 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Get Fresh Products Easily'), findsOneWidget);

      // Tap Back
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Sell Your Harvest Directly'), findsOneWidget);
    });

    testWidgets('Skip button invokes onComplete callback immediately',
        (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onComplete: () => completed = true,
          ),
        ),
      );

      expect(completed, isFalse);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('Get Started button on final screen invokes onComplete',
        (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onComplete: () => completed = true,
          ),
        ),
      );

      // Screen 1 -> Screen 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Screen 2 -> Screen 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(completed, isFalse);

      // Tap Get Started on Screen 3
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });
  });
}
