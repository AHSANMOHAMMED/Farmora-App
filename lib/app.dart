import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/farmora_state.dart';
import 'models/user_role.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/splash/presentation/splash_screen.dart';

class FarmoraApp extends StatelessWidget {
  final bool showSplash;

  const FarmoraApp({
    super.key,
    this.showSplash = true,
  });

  @override
  Widget build(BuildContext context) {
    // Check URL for ?demo=farmer to bypass auth for preview
    final params = Uri.base.queryParameters;
    final demoRole = params['demo'];
    final isDemoMode = demoRole != null;

    return ChangeNotifierProvider(
      create: (_) {
        final state = FarmoraState();
        if (isDemoMode) {
          // Auto sign-in as demo role
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final role = Role.values.firstWhere(
              (r) => r.name == demoRole,
              orElse: () => Role.farmer,
            );
            state.signIn(role);
          });
        }
        return state;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Farmora',
        theme: AppTheme.lightTheme,
        home: isDemoMode
            ? const HomeScreen()
            : (showSplash ? const SplashScreen() : const AuthGate()),
      ),
    );
  }
}
