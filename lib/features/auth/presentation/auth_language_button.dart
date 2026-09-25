import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../providers/farmora_state.dart';
import '../../profile/presentation/language_picker.dart';

/// Small "🌐 தமிழ்" style switch for the signed-out screens. Shows the
/// current language's native name and opens the [LanguagePicker] sheet.
class AuthLanguageButton extends StatelessWidget {
  const AuthLanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<FarmoraState>().language;
    return Tooltip(
      message: context.l10n.authLanguageButton,
      child: TextButton.icon(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const LanguagePicker(),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(48, 40),
        ),
        icon: const Icon(Icons.translate_rounded, size: 18),
        label: Text(
          language,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}
