import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'app.dart';

// Modular Clean Architecture Exports
export 'app.dart';
export 'firebase_options.dart';
export 'models/user_role.dart';
export 'models/product.dart';
export 'models/order.dart';
export 'models/offer.dart';
export 'models/transport_job.dart';
export 'models/earnings_model.dart';
export 'models/verification_model.dart';
export 'providers/farmora_state.dart';
export 'services/firebase_service.dart';
export 'core/constants/app_colors.dart';
export 'core/theme/app_theme.dart';
export 'core/widgets/farmer_header.dart';
export 'core/widgets/status_chip.dart';
export 'core/widgets/stat_card.dart';
export 'core/widgets/product_tile.dart';
export 'core/widgets/order_card.dart';
export 'core/widgets/job_card.dart';
export 'core/widgets/route_progress_map.dart';
export 'features/auth/presentation/auth_gate.dart';
export 'features/auth/presentation/welcome_screen.dart';
export 'features/home/presentation/home_screen.dart';
export 'features/home/presentation/dashboard_screen.dart';
export 'features/farmer/presentation/earnings_screen.dart';
export 'features/farmer/presentation/farmer_products_screen.dart';
export 'features/farmer/presentation/add_product_screen.dart';
export 'features/farmer/presentation/farmer_orders_screen.dart';
export 'features/farmer/presentation/order_detail_screen.dart';
export 'features/farmer/presentation/account_verification_screen.dart';
export 'features/buyer/presentation/buyer_products_screen.dart';
export 'features/buyer/presentation/buyer_orders_screen.dart';
export 'features/buyer/presentation/buyer_order_detail_screen.dart';
export 'features/buyer/presentation/product_detail_screen.dart';
export 'features/buyer/presentation/cart_screen.dart';
export 'models/cart_item.dart';
export 'features/orders/presentation/orders_screen.dart';
export 'features/transporter/presentation/available_jobs_screen.dart';
export 'features/transporter/application/transporter_controller.dart';
export 'features/transporter/domain/collection_job.dart';
export 'features/transporter/domain/transporter_notification.dart';
export 'features/transporter/presentation/collection_job_details_screen.dart';
export 'features/transporter/presentation/logistics_available_jobs_screen.dart';
export 'features/transporter/presentation/logistics_dashboard_screen.dart';
export 'features/transporter/presentation/my_jobs_screen.dart';
export 'features/transporter/presentation/transporter_notifications_screen.dart';
export 'features/transporter/presentation/transporter_profile_screen.dart';
export 'features/profile/presentation/profile_screen.dart';
export 'features/profile/presentation/legal_screens.dart';
export 'features/messaging/presentation/conversations_screen.dart';
export 'features/messaging/presentation/chat_screen.dart';
export 'models/conversation_model.dart';
export 'features/profile/presentation/role_sheet.dart';
export 'features/profile/presentation/language_picker.dart';
export 'core/widgets/farmora_logo.dart';
export 'features/splash/presentation/splash_screen.dart';
export 'features/onboarding/presentation/onboarding_screen.dart';
export 'features/auth/presentation/login_screen.dart';
export 'features/auth/presentation/role_selection_screen.dart';
export 'features/auth/presentation/register_screen.dart';

const _useFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
  defaultValue: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase once `flutterfire configure` has filled firebase_options.dart.
// The emulator switch is opt-in; normal builds stay attached to the configured
// Firebase project.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (_useFirebaseEmulators) {
      _configureFirebaseEmulators();
    }
    if (!kIsWeb && !_useFirebaseEmulators) {
      await _activateAppCheck();

      // Initialize Crashlytics
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      FirebasePerformance.instance.setPerformanceCollectionEnabled(!kDebugMode);
    }
    FirebaseAnalytics.instance
        .setAnalyticsCollectionEnabled(!_useFirebaseEmulators && !kDebugMode);
  } catch (e) {
    throw StateError(
        'Firebase initialization failed; Farmora needs a live Firebase backend: $e');
  }

  runApp(const FarmoraApp());
}

void _configureFirebaseEmulators() {
  final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : '127.0.0.1';
  FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8085);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  FirebaseStorage.instance.useStorageEmulator(host, 9199);
}

Future<void> _activateAppCheck() async {
  if (kIsWeb) return;
  try {
    await FirebaseAppCheck.instance.activate(
      // Debug provider for local builds. Production: Play Integrity / DeviceCheck.
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );
  } catch (e) {
    debugPrint('App Check not activated: $e');
  }
}
