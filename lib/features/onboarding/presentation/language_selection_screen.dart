import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_prefs.dart';
import '../../../core/widgets/farmora_logo.dart';
import '../../../providers/farmora_state.dart';

/// Full-screen language choice shown on first launch (no saved language),
/// before onboarding and login. Each language is written in its own script
/// so every user can find theirs whatever language the app is in.
class LanguageSelectionScreen extends StatefulWidget {
  /// Called after the language has been applied and saved; continues the
  /// normal flow (onboarding).
  final void Function(BuildContext context) onSelected;

  const LanguageSelectionScreen({super.key, required this.onSelected});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selecting;

  Future<void> _choose(AppLanguage language) async {
    if (_selecting != null) return;
    setState(() => _selecting = language.code);
    final state = Provider.of<FarmoraState?>(context, listen: false);
    try {
      if (state != null) {
        await state.setLanguage(language.code);
      } else {
        await LanguagePrefs.save(language.code);
      }
    } catch (e) {
      // Not signed in yet, so only the device copy is written (and that
      // never throws); keep going whatever happens.
      debugPrint('Language selection: $e');
    }
    if (!mounted) return;
    widget.onSelected(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.splashGradientStart,
              AppColors.splashGradientMid,
              AppColors.splashGradientEnd,
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FarmoraLogo(size: 88, showBadge: true),
                    const SizedBox(height: 16),
                    const Text(
                      'Farmora',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // The title in all three languages: nobody has chosen yet.
                    for (final language in AppLanguage.all)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          lookupAppLocalizations(Locale(language.code))
                              .langSelectTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: language.code == 'en' ? 20 : 16,
                            fontWeight: language.code == 'en'
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: language.code == 'en'
                                ? AppColors.onSurface
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    for (final language in AppLanguage.all)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _LanguageCard(
                          language: language,
                          selected: _selecting == language.code,
                          onTap: () => _choose(language),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.langSelectHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  /// First letter of each script, as a large visual cue.
  String get _glyph => switch (language.code) {
        'ta' => 'அ',
        'si' => 'අ',
        _ => 'A',
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: language.nativeName,
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        elevation: selected ? 3 : 1,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 84),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.outlineVariant.withValues(alpha: 0.5),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _glyph,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.nativeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      if (language.englishName != language.nativeName)
                        Text(
                          language.englishName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_ios_rounded,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  size: selected ? 26 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
