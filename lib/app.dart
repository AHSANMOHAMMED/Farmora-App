import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'providers/farmora_state.dart';
import 'core/routing/app_router.dart';

class FarmoraApp extends ConsumerWidget {
  const FarmoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return p.ChangeNotifierProvider(
      create: (_) => FarmoraState(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Farmora',
        theme: AppTheme.lightTheme,
        routerConfig: router,
        localizationsDelegates: const [
          FarmoraLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: FarmoraLocalizations.supportedLocales,
      ),
    );
  }
}
