import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/farmora_state.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/splash/presentation/splash_screen.dart';

class FarmoraApp extends StatelessWidget {
  final bool showSplash;

  const FarmoraApp({
    super.key,
    this.showSplash = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FarmoraState(),
      child: Consumer<FarmoraState>(
        builder: (context, state, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Farmora',
            theme: AppTheme.lightTheme,
            locale: state.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: showSplash ? const SplashScreen() : const AuthGate(),
          );
        },
      ),
    );
  }
}
