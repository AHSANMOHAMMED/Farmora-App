import 'package:farmora/core/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Delegates every widget test needs so `context.l10n` works.
const testLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// A MaterialApp with Farmora's localizations loaded (English by default).
/// Also keeps [L10n.current] in step, as the real app does.
MaterialApp localizedTestApp(Widget home, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: testLocalizationsDelegates,
    builder: (context, child) {
      L10n.update(AppLocalizations.of(context));
      return child ?? const SizedBox.shrink();
    },
    home: home,
  );
}
