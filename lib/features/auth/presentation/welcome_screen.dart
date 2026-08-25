import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_role.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'phone_auth_screen.dart';

/// Welcome screen with role selection and sign-in options.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  Role selectedRole = Role.buyer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          children: [
            const Text(
              'Welcome to\nFarmora',
              style: TextStyle(
                fontSize: 40,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'A fairer, fresher way to connect farms, families, and reliable transport.',
              style: TextStyle(
                fontSize: 17,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 36),
            const Text(
              'I am joining as a…',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 12),
            ...Role.values.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => setState(() => selectedRole = r),
                  leading: Icon(r.icon, color: const Color(0xff1f7a4d)),
                  title: Text(
                    r.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: Icon(
                    selectedRole == r
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: const Color(0xff1f7a4d),
                  ),
                  tileColor: selectedRole == r
                      ? const Color(0xffe4f3e8)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Primary CTA: Demo mode (works without Firebase)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ref.read(authProvider.notifier).signInDemo(selectedRole);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text('Continue as Demo'),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary CTA: Real sign-in with Firebase Auth
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('Sign In with Email'),
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Create Account'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
                  );
                },
                icon: const Icon(Icons.phone_outlined),
                label: const Text('Sign In with Phone'),
              ),
            ),

            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Demo mode uses local data · Sign in for real Firestore data',
                style: TextStyle(color: Colors.black45, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
