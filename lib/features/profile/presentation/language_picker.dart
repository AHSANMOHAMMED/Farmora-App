import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/farmora_strings.dart';
import '../../../providers/farmora_state.dart';

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = FarmoraStrings.of(context);
    final state = context.watch<FarmoraState>();

    const languages = [
      (name: 'English', native: 'English', flag: '🇬🇧'),
      (name: 'සිංහල', native: 'සිංහල', flag: '🇱🇰'),
      (name: 'தமிழ்', native: 'தமிழ்', flag: '🇱🇰'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.t('selectLanguage'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...languages.map((lang) {
              final isSelected = state.language == lang.name;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(lang.flag,
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                title: Text(
                  lang.native,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurface,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary)
                    : null,
                onTap: () {
                  context.read<FarmoraState>().setLanguage(lang.name);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${strings.t('language')}: ${lang.name}'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
