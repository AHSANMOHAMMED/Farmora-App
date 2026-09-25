// Runs the farmer flow steps in a browser and prints results to the console
// (read by a headless Chrome run). Build and run:
//   flutter build web --profile -t test/emulator/web_runner.dart -o build/e2e
//   (serve build/e2e, start the emulators, open it in Chrome)
import 'package:flutter/widgets.dart';

import 'farmer_flow_steps.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var passed = 0;
  final steps = farmerFlowSteps();
  for (final (name, run) in steps) {
    try {
      await run().timeout(const Duration(minutes: 2));
      passed++;
      // ignore: avoid_print
      print('E2E PASS | $name');
    } catch (e) {
      // Errors thrown inside Firestore web transactions arrive boxed.
      Object detail = e;
      try {
        detail = (e as dynamic).error ?? e;
      } catch (_) {}
      // ignore: avoid_print
      print('E2E FAIL | $name | $detail');
      break; // later steps depend on this one
    }
  }
  // ignore: avoid_print
  print('E2E DONE | $passed/${steps.length} steps passed');
}
