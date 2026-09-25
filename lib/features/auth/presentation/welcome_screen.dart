import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/farmora_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user_role.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Role selectedRole = Role.buyer;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          children: [
            const FarmoraLogo(size: 80),
            const SizedBox(height: 20),
            Text(
              l10n?.welcome ?? 'Welcome to Farmora',
              style: const TextStyle(
                fontSize: 40,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n?.splashSubtitle ?? 'Fresh produce directly from local farmers',
              style: const TextStyle(
                fontSize: 17,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 36),
            Text(
              l10n?.selectRole ?? 'Select your role',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...Role.values.where((r) => r != Role.admin).map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: selectedRole == r
                      ? AppColors.primaryLight
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () => setState(() => selectedRole = r),
                    leading: Icon(r.icon, color: AppColors.primary),
                    title: Text(r.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: Icon(
                      selectedRole == r
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RegisterScreen(selectedRole: selectedRole),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    l10n?.createAccount ?? 'Create Account',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                icon: const Icon(Icons.login_rounded),
                label: Text(l10n?.signIn ?? 'Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
