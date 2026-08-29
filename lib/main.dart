import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'firebase_options.dart';

// Modular Clean Architecture Exports
export 'app.dart';
export 'models/user_role.dart';
export 'models/product.dart';
export 'models/order.dart';
export 'models/transport_job.dart';
export 'providers/farmora_state.dart';
export 'core/constants/app_colors.dart';
export 'core/theme/app_theme.dart';
export 'core/widgets/stat_card.dart';
export 'core/widgets/product_tile.dart';
export 'core/widgets/order_card.dart';
export 'core/widgets/job_card.dart';
export 'core/widgets/farmora_logo.dart';
export 'features/splash/presentation/splash_screen.dart';
export 'features/onboarding/presentation/onboarding_screen.dart';
export 'features/auth/presentation/auth_gate.dart';
export 'features/auth/presentation/welcome_screen.dart';
export 'features/auth/presentation/login_screen.dart';
export 'features/auth/presentation/role_selection_screen.dart';
export 'features/auth/presentation/register_screen.dart';
export 'features/home/presentation/home_screen.dart';
export 'features/home/presentation/dashboard_screen.dart';
export 'features/buyer/presentation/products_screen.dart';
export 'features/farmer/presentation/add_product_dialog.dart';
export 'features/orders/presentation/orders_screen.dart';
export 'features/transporter/presentation/available_jobs_screen.dart';
export 'features/profile/presentation/profile_screen.dart';
export 'features/profile/presentation/role_sheet.dart';
export 'features/profile/presentation/language_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FarmoraApp());
}
