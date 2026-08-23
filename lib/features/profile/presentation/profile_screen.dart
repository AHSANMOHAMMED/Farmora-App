import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import 'language_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final role = user?.role ?? Role.buyer;

    // Convert language code to display name
    String langDisplay = 'English';
    if (user?.languageCode == 'si') langDisplay = 'සිංහල';
    if (user?.languageCode == 'ta') langDisplay = 'தமிழ்';

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
        Center(
          child: Text(
            user?.displayName ?? 'User',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
          subtitle: Text(langDisplay),
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
          onTap: () => ref.read(authProvider.notifier).signOut(),
        ),
      ],
    );
  }
}

/// Alias for backward compatibility
typedef Profile = ProfileScreen;
