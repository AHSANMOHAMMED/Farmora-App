import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_role.dart';
import '../providers/auth_provider.dart';

/// Onboarding screen — collects role, name, phone, language after first sign-up
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  Role _selectedRole = Role.buyer;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedLanguage = 'English';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          children: [
            const Text(
              'Set up your\nFarmora profile',
              style: TextStyle(
                fontSize: 34,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tell us a bit about yourself so we can personalize your experience.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Role selection
            const Text(
              'I am joining as a…',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 12),
            ...Role.values.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => setState(() => _selectedRole = r),
                  leading: Icon(r.icon, color: const Color(0xff1f7a4d)),
                  title: Text(
                    r.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    r.description,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: Icon(
                    _selectedRole == r
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: const Color(0xff1f7a4d),
                  ),
                  tileColor: _selectedRole == r
                      ? const Color(0xffe4f3e8)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Display name',
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'e.g. Ahsan',
              ),
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number (optional)',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '+94 7X XXX XXXX',
              ),
            ),
            const SizedBox(height: 16),

            // Language
            DropdownButtonFormField<String>(
              initialValue: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Preferred language',
                prefixIcon: Icon(Icons.language),
              ),
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'සිංහල', child: Text('Sinhala (සිංහල)')),
                DropdownMenuItem(value: 'தமிழ்', child: Text('Tamil (தமிழ்)')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedLanguage = v);
              },
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _nameController.text.trim().isEmpty
                    ? null
                    : () async {
                        final notifier = ref.read(authProvider.notifier);
                        await notifier.completeOnboarding(
                          role: _selectedRole,
                          displayName: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          languageCode: _selectedLanguage,
                        );
                        if (context.mounted) context.go('/home');
                      },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text('Get started'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
