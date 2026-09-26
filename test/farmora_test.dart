import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmora/providers/farmora_state.dart';
import 'package:farmora/app.dart';
import 'package:farmora/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:farmora/core/localization/l10n.dart';
import 'package:farmora/features/auth/presentation/auth_l10n.dart';
import 'package:farmora/features/auth/presentation/login_screen.dart';
import 'package:farmora/features/auth/presentation/welcome_screen.dart';
import 'package:farmora/features/profile/presentation/language_picker.dart';
import 'package:farmora/features/auth/presentation/register_screen.dart';
import 'package:farmora/features/home/presentation/dashboard_screen.dart';
import 'package:farmora/l10n/app_localizations_si.dart';
import 'package:farmora/l10n/app_localizations_ta.dart';
import 'package:farmora/models/user_role.dart';

import 'helpers/l10n_test_app.dart';

void _phoneViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(360, 3000);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _app(Widget home, FarmoraState state, Locale locale) =>
    ChangeNotifierProvider<FarmoraState>.value(
      value: state,
      child: localizedTestApp(home, locale: locale),
    );

void main() {
  testWidgets('Farmora app renders', (tester) async {
    // The splash reads the saved language (first-launch language picker).
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FarmoraState(),
        child: const FarmoraApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FarmoraApp), findsOneWidget);
  });

  group('Auth error / district localization', () {
    test('known auth errors are translated, unknown ones use the fallback', () {
      final ta = AppLocalizationsTa();
      expect(
        authErrorText('Phone number or password is incorrect.', ta, 'x'),
        ta.authErrWrongCredentials,
      );
      expect(authErrorText('[firebase_auth/internal] boom', ta, 'fallback'),
          'fallback');
      expect(authErrorText(null, ta, 'fallback'), 'fallback');
    });

    test('districts display in the chosen language, unknown stay unchanged',
        () {
      final si = AppLocalizationsSi();
      expect(districtLabel('Jaffna', si), si.authDistrictJaffna);
      expect(districtLabel('Nuwara Eliya', si), si.authDistrictNuwaraEliya);
      expect(districtLabel('Somewhere', si), 'Somewhere');
      expect(sriLankaDistricts, hasLength(25));
    });
  });

  group('Language switch on signed-out screens', () {
    for (final entry in {
      'login': const LoginScreen(),
      'welcome': const WelcomeScreen(),
    }.entries) {
      testWidgets('${entry.key} screen opens the language picker',
          (tester) async {
        _phoneViewport(tester);
        await tester
            .pumpWidget(_app(entry.value, FarmoraState(), const Locale('en')));
        await tester.pump();
        expect(find.byTooltip('Change language'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.translate_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(LanguagePicker), findsOneWidget);
        expect(find.text('தமிழ்'), findsWidgets);
        expect(find.text('සිංහල'), findsWidgets);
      });
    }
  });

  group('Localized screens fit a 360px phone', () {
    for (final locale in const [Locale('ta'), Locale('si')]) {
      for (final role in const [
        Role.farmer,
        Role.buyer,
        Role.transporter,
      ]) {
        testWidgets('${role.name} dashboard in ${locale.languageCode}',
            (tester) async {
          _phoneViewport(tester);
          final state = FarmoraState()..setRole(role);
          await tester.pumpWidget(_app(const DashboardScreen(), state, locale));
          await tester.pump();
          expect(tester.takeException(), isNull);
          final l = lookupAppLocalizations(locale);
          expect(find.text(l.dashboardQuickActions), findsWidgets);
          // Nothing English left from the old hard-coded strings.
          expect(find.text('Quick Actions'), findsNothing);
          expect(find.textContaining('Good '), findsNothing);
        });
      }

      // Admins land on AdminDashboardScreen (DashboardScreen has no admin
      // branch any more).
      testWidgets('admin dashboard in ${locale.languageCode}', (tester) async {
        _phoneViewport(tester);
        final state = FarmoraState()..setRole(Role.admin);
        await tester
            .pumpWidget(_app(const AdminDashboardScreen(), state, locale));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final l = lookupAppLocalizations(locale);
        expect(find.text(l.adminDashTitle), findsWidgets);
        expect(find.text(l.adminDashQuickHub), findsWidgets);
        expect(find.text('Quick Operations Hub'), findsNothing);
      });

      testWidgets('login screen in ${locale.languageCode}', (tester) async {
        _phoneViewport(tester);
        await tester
            .pumpWidget(_app(const LoginScreen(), FarmoraState(), locale));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final l = lookupAppLocalizations(locale);
        expect(find.text(l.forgotPassword), findsOneWidget);
        expect(find.text('Login'), findsNothing);
      });

      testWidgets('register screen in ${locale.languageCode}', (tester) async {
        _phoneViewport(tester);
        await tester.pumpWidget(_app(
            const RegisterScreen(selectedRole: Role.transporter),
            FarmoraState(),
            locale));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final l = lookupAppLocalizations(locale);
        expect(find.text(l.createAccount), findsWidgets);
        expect(find.text(l.authSignupTermsNote), findsOneWidget);
      });
    }
  });
}
