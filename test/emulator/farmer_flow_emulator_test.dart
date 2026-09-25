// Farmer / customer end-to-end flow on the Firebase Emulator Suite.
//
// `flutter test --platform chrome` could not run in the dev environment, so
// web_runner.dart runs the same steps in a headless browser instead. This
// wrapper is kept for machines where the browser test runner works:
//   rules_tests/node_modules/.bin/firebase emulators:exec //     --config firebase.emulators.json //     --only auth,firestore,storage --project demo-farmora //     "flutter test test/emulator --platform chrome --dart-define=FIREBASE_EMULATOR=true"
//
// Skipped in a normal `flutter test` run (no emulators there).
import 'package:flutter_test/flutter_test.dart';

import 'farmer_flow_steps.dart';

const _enabled = bool.fromEnvironment('FIREBASE_EMULATOR');

void main() {
  if (!_enabled) {
    test('farmer flow (emulator)', () {},
        skip: 'Run with the Firebase emulators and '
            '--dart-define=FIREBASE_EMULATOR=true');
    return;
  }
  final steps = farmerFlowSteps();
  setUpAll(steps.first.$2);
  for (final step in steps.skip(1)) {
    test(step.$1, step.$2, timeout: const Timeout(Duration(minutes: 2)));
  }
}
