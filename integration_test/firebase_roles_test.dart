import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:farmora/firebase_options.dart';
import 'package:farmora/models/user_role.dart';
import 'package:farmora/providers/farmora_state.dart';

const _emulatorPassword = String.fromEnvironment(
  'FARMORA_EMULATOR_TEST_PASSWORD',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone login loads buyer, farmer, logistics, and admin roles',
      (tester) async {
    if (_emulatorPassword.isEmpty) {
      fail(
          'Pass FARMORA_EMULATOR_TEST_PASSWORD from the emulator seed script.');
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8085);
    FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
    FirebaseStorage.instance.useStorageEmulator('127.0.0.1', 9199);

    final state = FarmoraState();
    const accounts = <(String, Role)>[
      ('0771000001', Role.buyer),
      ('0771000002', Role.farmer),
      ('0771000003', Role.transporter),
      ('0771000004', Role.admin),
    ];

    for (final (phone, expectedRole) in accounts) {
      expect(
        await state.signInWithBackend(
          phone: phone,
          password: _emulatorPassword,
        ),
        isTrue,
        reason: state.authError,
      );
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await state.initFromFirestore(uid);

      expect(state.profileLoaded, isTrue);
      expect(state.role, expectedRole);
      expect(state.isVerified, isTrue);
      if (expectedRole == Role.admin) {
        final token =
            await FirebaseAuth.instance.currentUser!.getIdTokenResult(true);
        expect(token.claims?['admin'], isTrue);
      }

      await state.signOut();
    }
    state.dispose();
  });
}
