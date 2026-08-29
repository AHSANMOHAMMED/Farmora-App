import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import '../../home/presentation/home_screen.dart';
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
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  context.read<FarmoraState>().signIn(selectedRole);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text('Continue to Farmora'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RegisterScreen(selectedRole: selectedRole),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text('Create an account'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      color: Color(0xff1f7a4d),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Demo mode · No account required',
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
