import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/l10n.dart';
import 'providers/farmora_state.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/transporter/application/transporter_controller.dart';
import 'features/transporter/data/firestore_collection_job_repository.dart';
import 'features/transporter/data/firestore_transporter_account_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FarmoraApp extends StatelessWidget {
  final bool showSplash;

  /// Language saved on the device ('en' / 'ta' / 'si'), loaded in main()
  /// before runApp so the first frame is in that language. When null the
  /// saved language (if any) is applied as soon as it has been read.
  final String? initialLanguageCode;

  const FarmoraApp({
    super.key,
    this.showSplash = true,
    this.initialLanguageCode,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final state = FarmoraState(initialLanguageCode: initialLanguageCode);
          if (initialLanguageCode == null) state.restoreSavedLanguage();
          return state;
        }),
        ChangeNotifierProvider(
          create: (_) => TransporterController(
            repository: FirestoreCollectionJobRepository(),
            accountRepository: FirestoreTransporterAccountRepository(),
          ),
        ),
      ],
      child: Consumer<FarmoraState>(
        builder: (context, state, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            // Brand name: the same in every language.
            onGenerateTitle: (context) => context.l10n.appName,
            theme: AppTheme.lightTheme,
            locale: state.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            navigatorObservers: [
              if (Firebase.apps.isNotEmpty)
                FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
            ],
            // Keeps L10n.current (used by models/services) in step with the
            // language the widgets are rendered in.
            builder: (context, child) {
              L10n.update(AppLocalizations.of(context));
              return child ?? const SizedBox.shrink();
            },
            home: showSplash ? const SplashScreen() : const AuthGate(),
          );
        },
      ),
    );
  }
}
