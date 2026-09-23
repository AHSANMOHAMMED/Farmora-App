import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/farmora_state.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/transporter/application/transporter_controller.dart';
import 'features/transporter/data/firestore_collection_job_repository.dart';
import 'features/transporter/data/firestore_transporter_account_repository.dart';

class FarmoraApp extends StatelessWidget {
  final bool showSplash;

  const FarmoraApp({
    super.key,
    this.showSplash = true,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FarmoraState()),
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
