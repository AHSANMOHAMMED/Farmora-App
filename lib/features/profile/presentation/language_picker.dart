import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/farmora_state.dart';

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    const languages = ['English', 'සිංහල', 'தமிழ்'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: languages
          .map(
            (lang) => ListTile(
              title: Text(lang),
              onTap: () {
                context.read<FarmoraState>().setLanguage(lang);
                Navigator.pop(context);
              },
            ),
          )
          .toList(),
    );
  }
}
