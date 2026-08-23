import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'si', 'name': 'සිංහල'},
      {'code': 'ta', 'name': 'தமிழ்'}
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: languages
          .map(
            (lang) => ListTile(
              title: Text(lang['name']!),
              onTap: () {
                ref.read(authProvider.notifier).setLanguage(lang['code']!);
                Navigator.pop(context);
              },
            ),
          )
          .toList(),
    );
  }
}
