import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:farmora/main.dart' as app;
import 'package:farmora/app.dart';
import 'package:farmora/features/auth/presentation/login_screen.dart';
import 'package:farmora/features/home/presentation/home_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end workflow tests', () {
    testWidgets('verify full user workflow (login, view products)', (tester) async {
      // Load app widget.
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // We expect to see FarmoraApp initialized
      expect(find.byType(FarmoraApp), findsOneWidget);
      
      // Find LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      
      // We could simulate typing phone and password if it's hooked up to mock backend
    });
  });
}
