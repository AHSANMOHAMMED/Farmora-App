import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import '../../auth/presentation/login_screen.dart';
import 'language_picker.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final role = state.role;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Profile',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        const CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xffdcefe2),
          child: Icon(
            Icons.person,
            size: 42,
            color: Color(0xff1f7a4d),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Alex Perera',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        Center(
          child: Text(
            role.label,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(height: 28),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'),
          subtitle: Text(state.language),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showModalBottomSheet(
            context: context,
            builder: (_) => const LanguagePicker(),
          ),
        ),
        const ListTile(
          leading: Icon(Icons.help_outline),
          title: Text('Help & support'),
          trailing: Icon(Icons.chevron_right),
        ),
        const ListTile(
          leading: Icon(Icons.settings_outlined),
          title: Text('Settings'),
          trailing: Icon(Icons.chevron_right),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: () async {
            await context.read<FarmoraState>().signOut();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}

/// Alias for backward compatibility
typedef Profile = ProfileScreen;
