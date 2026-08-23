import 'package:flutter/material.dart';
import 'app.dart';

// Modular Clean Architecture Exports
export 'app.dart';
export 'models/user_role.dart';
export 'models/product.dart';
export 'models/order.dart';
export 'models/transport_job.dart';
export 'models/earnings_model.dart';
export 'models/verification_model.dart';
export 'providers/farmora_state.dart';
export 'core/constants/app_colors.dart';
export 'core/theme/app_theme.dart';
export 'core/widgets/farmer_header.dart';
export 'core/widgets/status_chip.dart';
export 'core/widgets/stat_card.dart';
export 'core/widgets/product_tile.dart';
export 'core/widgets/order_card.dart';
export 'core/widgets/job_card.dart';
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
export 'features/buyer/presentation/products_screen.dart';
export 'features/orders/presentation/orders_screen.dart';
export 'features/transporter/presentation/available_jobs_screen.dart';
export 'features/profile/presentation/profile_screen.dart';
export 'features/profile/presentation/role_sheet.dart';
export 'features/profile/presentation/language_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FarmoraApp());
}
