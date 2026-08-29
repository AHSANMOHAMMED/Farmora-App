import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/farmora_logo.dart';
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          children: [
            const FarmoraLogo(size: 80),
            const SizedBox(height: 20),
            const Text('Welcome to\nFarmora', style: TextStyle(fontSize: 40, height: 1.05, fontWeight: FontWeight.w900, color: AppColors.forestGreen)),
            const SizedBox(height: 14),
            const Text('A fairer, fresher way to connect farms, families, and reliable transport.', style: TextStyle(fontSize: 17, color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 36),
            const Text('I am joining as a…', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            ...Role.values.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () => setState(() => selectedRole = r),
                leading: Icon(r.icon, color: AppColors.primary),
                title: Text(r.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: Icon(selectedRole == r ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.primary),
                tileColor: selectedRole == r ? AppColors.primaryLight : AppColors.surfaceContainerLowest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            )),
            const SizedBox(height: 18),

            // Primary CTA: Register
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RegisterScreen(selectedRole: selectedRole)),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sign In
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Sign In'),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
