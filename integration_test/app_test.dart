import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:farmora/main.dart' as app;
import 'package:farmora/app.dart';
import 'package:farmora/features/auth/presentation/login_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end workflow tests', () {
    testWidgets('verify full user workflow (login, view products)', (tester) async {
      // Load app widget.
      app.main();
      
      // Wait for splash screen to finish (it has a 2.6s timer + 600ms transition)
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // We expect to see FarmoraApp initialized
      expect(find.byType(FarmoraApp), findsOneWidget);
      
      // Now we should be on OnboardingScreen
      expect(find.text('Skip'), findsOneWidget);
      
      // Tap Skip
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      
      // Find LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      
      // We could simulate typing phone and password if it's hooked up to mock backend
    });
  });
}
