/// Localization helpers shared across Farmora.
///
/// * In widgets use `context.l10n.someKey` (rebuilds when the language
///   changes).
/// * In code without a BuildContext (models, services, state, error mapping)
///   use `L10n.current.someKey`; it is kept in sync with the app language by
///   [FarmoraState] and the MaterialApp builder.
/// * Status values stored in Firestore stay English; show them with
///   [statusLabel].
library;

import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_en.dart';

export '../../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class L10n {
  L10n._();

  static AppLocalizations _current = AppLocalizationsEn();

  /// Strings for the language the app is currently shown in.
  static AppLocalizations get current => _current;

  static void update(AppLocalizations l) => _current = l;

  static void updateLocale(Locale locale) {
    try {
      _current = lookupAppLocalizations(locale);
    } catch (_) {
      _current = AppLocalizationsEn();
    }
  }
}

String _normalize(String raw) =>
    raw.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');

/// Display label for a raw status value (orders, payments, jobs, offers,
/// disputes, reviews, settlements, products …). Unknown values are returned
/// unchanged so nothing disappears.
String statusLabel(String raw, [AppLocalizations? l]) {
  final s = l ?? L10n.current;
  return switch (_normalize(raw)) {
    'pending' || 'awaiting' => s.statusPending,
    'accepted' => s.statusAccepted,
    'confirmed' => s.statusConfirmed,
    'assigned' => s.statusAssigned,
    'pickedup' => s.statusPickedUp,
    'intransit' || 'ontheway' || 'shipped' => s.statusInTransit,
    'delivered' => s.statusDelivered,
    'completed' || 'complete' => s.statusCompleted,
    'cancelled' || 'canceled' => s.statusCancelled,
    'declined' => s.statusDeclined,
    'rejected' => s.statusRejected,
    'approved' => s.statusApproved,
    'requested' => s.statusRequested,
    'countered' || 'counteroffer' => s.statusCountered,
    'active' || 'available' => s.statusActive,
    'inactive' => s.statusInactive,
    'outofstock' => s.statusOutOfStock,
    'empty' => s.statusEmpty,
    'open' => s.statusOpen,
    'collected' => s.statusCollected,
    'processing' => s.statusProcessing,
    'settled' => s.statusSettled,
    'onhold' => s.statusOnHold,
    'paid' => s.statusPaid,
    'unpaid' => s.statusUnpaid,
    'refunded' => s.statusRefunded,
    'disputed' => s.statusDisputed,
    'underreview' || 'inreview' => s.statusUnderReview,
    'resolved' => s.statusResolved,
    'suspended' => s.statusSuspended,
    'verified' => s.statusVerified,
    'failed' => s.statusFailed,
    'draft' => s.statusDraft,
    'harvested' => s.statusHarvested,
    'sold' => s.statusSold,
    'expired' => s.statusExpired,
    _ => raw,
  };
}
