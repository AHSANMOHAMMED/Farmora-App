import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:farmora/app.dart';
import 'package:farmora/core/localization/l10n.dart';
import 'package:farmora/core/localization/language_prefs.dart';
import 'package:farmora/core/theme/app_theme.dart';
import 'package:farmora/features/home/presentation/dashboard_screen.dart';
import 'package:farmora/features/profile/presentation/profile_screen.dart';
import 'package:farmora/features/splash/presentation/splash_screen.dart';
import 'package:farmora/models/user_role.dart';
import 'package:farmora/providers/farmora_state.dart';

import 'helpers/l10n_test_app.dart';

/// Mirrors app.dart: the MaterialApp listens to FarmoraState and takes its
/// locale from it, so changing the language rebuilds everything.
Widget _app(FarmoraState state, Widget home) {
  return ChangeNotifierProvider<FarmoraState>.value(
    value: state,
    child: Consumer<FarmoraState>(
      builder: (context, state, _) => MaterialApp(
        locale: state.locale,
        theme: AppTheme.lightTheme,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: testLocalizationsDelegates,
        builder: (context, child) {
          L10n.update(AppLocalizations.of(context));
          return child ?? const SizedBox.shrink();
        },
        home: home,
      ),
    ),
  );
}

AppLocalizations _l(String code) => lookupAppLocalizations(Locale(code));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({LanguagePrefs.key: 'en'});
  });

  testWidgets('ProfileScreen switches language without a restart',
      (tester) async {
    final state = FarmoraState()..role = Role.farmer;
    await tester.pumpWidget(_app(state, const ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text(_l('en').editProfile), findsOneWidget);
    expect(find.text(_l('en').roleFarmer), findsOneWidget);

    state.language = 'தமிழ்';
    await tester.pumpAndSettle();
    expect(find.text(_l('ta').editProfile), findsOneWidget);
    expect(find.text(_l('ta').roleFarmer), findsOneWidget);
    expect(find.text(_l('en').editProfile), findsNothing);
    expect(L10n.current.localeName, 'ta');

    state.language = 'සිංහල';
    await tester.pumpAndSettle();
    expect(find.text(_l('si').editProfile), findsOneWidget);
    expect(find.text(_l('si').roleFarmer), findsOneWidget);
    expect(find.text(_l('ta').editProfile), findsNothing);
    expect(L10n.current.localeName, 'si');
  });

  testWidgets('setLanguage switches the dashboard and is saved on the device',
      (tester) async {
    final state = FarmoraState()..setRole(Role.farmer);
    await tester
        .pumpWidget(_app(state, const Scaffold(body: DashboardScreen())));
    await tester.pumpAndSettle();
    expect(find.text(_l('en').dashboardFarmActivity), findsOneWidget);

    await state.setLanguage('ta');
    await tester.pumpAndSettle();
    expect(find.text(_l('ta').dashboardFarmActivity), findsOneWidget);
    expect(find.text(_l('en').dashboardFarmActivity), findsNothing);
    expect(await LanguagePrefs.load(), 'ta');

    await state.setLanguage('සිංහල');
    await tester.pumpAndSettle();
    expect(find.text(_l('si').dashboardFarmActivity), findsOneWidget);
    expect(await LanguagePrefs.load(), 'si');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the real FarmoraApp rebuilds in the new language',
      (tester) async {
    await tester.pumpWidget(const FarmoraApp());
    expect(find.text(_l('en').splashTagline), findsOneWidget);

    final state = Provider.of<FarmoraState>(
      tester.element(find.byType(SplashScreen)),
      listen: false,
    );
    state.language = 'தமிழ்';
    await tester.pump();
    expect(find.text(_l('ta').splashTagline), findsOneWidget);

    state.language = 'සිංහල';
    await tester.pump();
    expect(find.text(_l('si').splashTagline), findsOneWidget);
    expect(find.text(_l('en').splashTagline), findsNothing);
  });

  testWidgets('Inter text styles inherit the Tamil/Sinhala font fallback',
      (tester) async {
    final state = FarmoraState();
    const key = Key('inter');
    await tester.pumpWidget(_app(
      state,
      const Scaffold(
        body: Text('தமிழ் සිංහල',
            key: key, style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
      ),
    ));
    final context = tester.element(find.byKey(key));
    final effective = DefaultTextStyle.of(context)
        .style
        .merge(const TextStyle(fontFamily: 'Inter', fontSize: 14));
    expect(effective.fontFamilyFallback,
        containsAll(['NotoSansTamil', 'NotoSansSinhala']));
    expect(AppTheme.lightTheme.textTheme.bodyMedium!.fontFamilyFallback,
        containsAll(['NotoSansTamil', 'NotoSansSinhala']));
  });
}
