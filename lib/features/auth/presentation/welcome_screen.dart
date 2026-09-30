import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/farmora_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/farmora_state.dart';
import 'auth_blocked_banner.dart';
import 'auth_gate.dart';
import 'auth_language_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _handleAdminLogin(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Admin access: Signing in...'),
          ],
        ),
        backgroundColor: AppColors.forestGreen,
        duration: Duration(seconds: 3),
      ),
    );

    final state = context.read<FarmoraState>();
    final success = await state.signInWithBackend(
      phone: '0725068682',
      password: 'admin123',
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome, Administrator!'),
          backgroundColor: AppColors.forestGreen,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.authError ?? 'Admin login failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            const Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AuthLanguageButton(),
            ),
            const AuthBlockedBanner(padding: EdgeInsets.only(bottom: 12)),
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () => _handleAdminLogin(context),
                child: const Tooltip(
                  message: 'Double-tap logo for Admin login',
                  child: FarmoraLogo(size: 84),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.welcome ?? 'Welcome to Farmora',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.splashSubtitle ?? 'Fresh produce directly from local farmers',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 36),

            // 1. Create Account (opens RegisterScreen with embedded 3-role selector)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    l10n?.createAccount ?? 'Create Account',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Sign In (opens standard LoginScreen)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppColors.forestGreen,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.login_rounded),
                label: Text(
                  l10n?.signIn ?? 'Sign In',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
