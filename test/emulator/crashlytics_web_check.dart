// Debug-mode web check for the Crashlytics fix. Run in a browser with
//   flutter run -d web-server -t test/emulator/crashlytics_web_check.dart
// and read the console. Crashlytics asserts only in debug builds.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:farmora/core/services/error_reporter.dart';
import 'package:farmora/firebase_options.dart';

// ignore_for_file: avoid_print
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ErrorReporter.init();
  print('CHECK | web=$kIsWeb debug=$kDebugMode '
      'crashlyticsEnabled=${ErrorReporter.crashlyticsEnabled}');

  // New path: a framework error goes through ErrorReporter.
  var secondary = false;
  final previous = FlutterError.presentError;
  FlutterError.presentError = (_) {}; // keep the console readable
  try {
    FlutterError.reportError(FlutterErrorDetails(
      exception: Exception('probe framework error'),
      library: 'crashlytics_web_check',
    ));
  } catch (e) {
    secondary = true;
    print('CHECK | NEW PATH threw: $e');
  }
  FlutterError.presentError = previous;
  print('CHECK | new path secondary error: $secondary');

  // Old path (what main.dart used to install) — expected to fail on web.
  try {
    await FirebaseCrashlytics.instance.recordFlutterFatalError(
        FlutterErrorDetails(exception: Exception('probe')));
    print('CHECK | old path: no error');
  } catch (e) {
    final text = e.toString().replaceAll('\n', ' ');
    print('CHECK | old path fails as reported: '
        '${text.substring(0, text.length > 160 ? 160 : text.length)}');
  }
  print('CHECK DONE');
}
