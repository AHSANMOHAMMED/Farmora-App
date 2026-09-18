import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/farmora_state.dart';

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languages = [
      (label: l10n.english, value: 'English'),
      (label: l10n.sinhala, value: 'සිංහල'),
      (label: l10n.tamil, value: 'தமிழ்'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: languages
          .map(
            (lang) => ListTile(
              title: Text(lang.label),
              onTap: () {
                context.read<FarmoraState>().setLanguage(lang.value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.languageChanged)),
                );
              },
            ),
          )
          .toList(),
    );
  }
}
