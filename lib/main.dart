import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase once `flutterfire configure` has filled firebase_options.dart.
  // Without Firebase the auth gate stays signed-out — no mock marketplace data.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _activateAppCheck();
  } catch (e) {
    debugPrint('Firebase initialization failed (running in offline/mock mode): $e');
  }

  runApp(const FarmoraApp());
}

Future<void> _activateAppCheck() async {
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
