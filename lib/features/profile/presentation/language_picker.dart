import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_prefs.dart';
import '../../../providers/farmora_state.dart';

/// Bottom-sheet language picker. The whole app switches immediately; when
/// signed in the choice is also saved on the profile.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  Future<void> _select(BuildContext context, AppLanguage language) async {
    final state = context.read<FarmoraState>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (navigator.canPop()) navigator.pop();
    try {
      await state.setLanguage(language.code);
      // L10n.current already holds the NEW language here.
      messenger.showSnackBar(SnackBar(
        content: Text(L10n.current.langChangedTo(language.nativeName)),
        backgroundColor: AppColors.primary,
      ));
    } catch (e) {
      debugPrint('Saving language failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(L10n.current.langSaveFailed),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<FarmoraState>();

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
              l.langSelectTitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            for (final lang in AppLanguage.all)
              _LanguageTile(
                language: lang,
                selected: state.languageCode == lang.code,
                onTap: () => _select(context, lang),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  String get _glyph => switch (language.code) {
        'ta' => 'அ',
        'si' => 'අ',
        _ => 'A',
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      selected: selected,
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _glyph,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
      title: Text(
        language.nativeName,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.onSurface,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
