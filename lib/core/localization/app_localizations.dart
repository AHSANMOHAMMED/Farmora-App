import 'package:flutter/material.dart';

import 'l10n_en.dart';
import 'l10n_si.dart';
import 'l10n_ta.dart';

/// Localization delegate for the app
class FarmoraLocalizations {
  final Locale locale;

  FarmoraLocalizations(this.locale);

  static FarmoraLocalizations of(BuildContext context) {
    return Localizations.of<FarmoraLocalizations>(context, FarmoraLocalizations)!;
  }

  static const LocalizationsDelegate<FarmoraLocalizations> delegate =
      _FarmoraLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  late final Map<String, String> _strings = _loadStrings();

  Map<String, String> _loadStrings() {
    switch (locale.languageCode) {
      case 'si':
        return siStrings;
      case 'ta':
        return taStrings;
      default:
        return enStrings;
    }
  }

  String translate(String key) => _strings[key] ?? key;

  // ─── Convenience getters ───────────────────────────────────

  String get appName => translate('app_name');
  String get welcomeTitle => translate('welcome_title');
  String get welcomeSubtitle => translate('welcome_subtitle');
  String get continueButton => translate('continue_button');
  String get demoMode => translate('demo_mode');
  String get signIn => translate('sign_in');
  String get signUp => translate('sign_up');
  String get email => translate('email');
  String get password => translate('password');
  String get fullName => translate('full_name');
  String get phoneNumber => translate('phone_number');
  String get language => translate('language');
  String get home => translate('home');
  String get products => translate('products');
  String get orders => translate('orders');
  String get profile => translate('profile');
  String get searchHint => translate('search_hint');
  String get noProductsYet => translate('no_products_yet');
  String get addProduct => translate('add_product');
  String get productName => translate('product_name');
  String get quantity => translate('quantity');
  String get pricePerUnit => translate('price_per_unit');
  String get publish => translate('publish');
  String get cancel => translate('cancel');
  String get tryAgain => translate('try_again');
  String get somethingWentWrong => translate('something_went_wrong');
  String get networkError => translate('network_error');
  String get signOut => translate('sign_out');
  String get helpAndSupport => translate('help_and_support');
  String get settings => translate('settings');

  String get roleFarmer => translate('role_farmer');
  String get roleBuyer => translate('role_buyer');
  String get roleTransporter => translate('role_transporter');

  String get statusPending => translate('status_pending');
  String get statusConfirmed => translate('status_confirmed');
  String get statusInTransit => translate('status_in_transit');
  String get statusDelivered => translate('status_delivered');

  String get onboardingTitle => translate('onboarding_title');
  String get onboardingSubtitle => translate('onboarding_subtitle');
  String get getStarted => translate('get_started');
}

class _FarmoraLocalizationsDelegate
    extends LocalizationsDelegate<FarmoraLocalizations> {
  const _FarmoraLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  Future<FarmoraLocalizations> load(Locale locale) async {
    return FarmoraLocalizations(locale);
  }

  @override
  bool shouldReload(_FarmoraLocalizationsDelegate old) => false;
}
