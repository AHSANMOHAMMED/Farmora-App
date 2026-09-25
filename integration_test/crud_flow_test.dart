import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:farmora/app.dart';
import 'package:farmora/features/auth/presentation/welcome_screen.dart';
import 'package:farmora/firebase_options.dart';
import 'package:farmora/providers/farmora_state.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signed-out users cannot enter a role dashboard', (tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    await FirebaseAuth.instance.signOut();

    await tester.pumpWidget(const FarmoraApp(showSplash: false));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(WelcomeScreen));
    final state = Provider.of<FarmoraState>(context, listen: false);
    expect(state.signedIn, isFalse);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
