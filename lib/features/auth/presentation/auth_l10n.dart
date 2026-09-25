import '../../../core/localization/l10n.dart';

/// Localized text for [FarmoraState.authError].
///
/// `authError` holds the English message produced by
/// `FirebaseAuthService` (or a raw exception string). Known messages are
/// mapped to the current language; anything else falls back to [fallback]
/// so raw exception text is never shown to users.
String authErrorText(String? raw, AppLocalizations l, String fallback) {
  if (raw == null || raw.trim().isEmpty) return fallback;
  return switch (raw.trim()) {
    'Your account role is invalid.' => l.authErrInvalidRole,
    'User profile was not found.' => l.authErrProfileNotFound,
    'No Farmora profile found. Register with Google first.' =>
      l.authErrNoGoogleProfile,
    'No Farmora profile found. Register this phone number first.' =>
      l.authErrNoPhoneProfile,
    'Enter a valid mobile number first.' => l.authErrEnterValidMobile,
    'Enter a valid phone number, for example +94771234567.' =>
      l.authErrPhoneFormat,
    'Enter the 6-digit verification code.' => l.authErrEnterSixDigits,
    'Request a new OTP first.' => l.authErrRequestNewOtp,
    'This mobile number is already registered.' ||
    'This mobile number is already registered to another account.' =>
      l.authErrPhoneTaken,
    'Could not save your profile.' => l.authErrCouldNotSaveProfile,
    'An account already exists for this phone number.' =>
      l.authErrAccountExists,
    'Password must contain at least 6 characters.' => l.passwordTooShort,
    'Phone number or password is incorrect.' => l.authErrWrongCredentials,
    'Network error. Check your internet connection.' => l.errorOffline,
    'Enable this sign-in provider in Firebase Authentication.' =>
      l.authErrMethodUnavailable,
    'Enter a valid phone number with country code.' => l.authErrInvalidPhone,
    'The OTP is incorrect. Please try again.' => l.authErrWrongOtp,
    'The OTP expired. Request a new code.' => l.authErrOtpExpired,
    'Too many attempts. Please try again later.' => l.tooManyAttempts,
    'SMS quota exceeded. Use a Firebase test phone number.' =>
      l.authErrSmsLimit,
    'Google sign-in was cancelled.' => l.authErrGoogleCancelled,
    _ => fallback,
  };
}

/// Sri Lankan districts. Values stay English (stored in Firestore); show
/// them with [districtLabel].
const List<String> sriLankaDistricts = [
  'Ampara',
  'Anuradhapura',
  'Badulla',
  'Batticaloa',
  'Colombo',
  'Galle',
  'Gampaha',
  'Hambantota',
  'Jaffna',
  'Kalutara',
  'Kandy',
  'Kegalle',
  'Kilinochchi',
  'Kurunegala',
  'Mannar',
  'Matale',
  'Matara',
  'Monaragala',
  'Mullaitivu',
  'Nuwara Eliya',
  'Polonnaruwa',
  'Puttalam',
  'Ratnapura',
  'Trincomalee',
  'Vavuniya',
];

/// Display name of a district stored in English. Unknown values are returned
/// unchanged.
String districtLabel(String raw, [AppLocalizations? l10n]) {
  final l = l10n ?? L10n.current;
  return switch (raw.trim().toLowerCase()) {
    'ampara' => l.authDistrictAmpara,
    'anuradhapura' => l.authDistrictAnuradhapura,
    'badulla' => l.authDistrictBadulla,
    'batticaloa' => l.authDistrictBatticaloa,
    'colombo' => l.authDistrictColombo,
    'galle' => l.authDistrictGalle,
    'gampaha' => l.authDistrictGampaha,
    'hambantota' => l.authDistrictHambantota,
    'jaffna' => l.authDistrictJaffna,
    'kalutara' => l.authDistrictKalutara,
    'kandy' => l.authDistrictKandy,
    'kegalle' => l.authDistrictKegalle,
    'kilinochchi' => l.authDistrictKilinochchi,
    'kurunegala' => l.authDistrictKurunegala,
    'mannar' => l.authDistrictMannar,
    'matale' => l.authDistrictMatale,
    'matara' => l.authDistrictMatara,
    'monaragala' || 'moneragala' => l.authDistrictMonaragala,
    'mullaitivu' => l.authDistrictMullaitivu,
    'nuwara eliya' => l.authDistrictNuwaraEliya,
    'polonnaruwa' => l.authDistrictPolonnaruwa,
    'puttalam' => l.authDistrictPuttalam,
    'ratnapura' => l.authDistrictRatnapura,
    'trincomalee' => l.authDistrictTrincomalee,
    'vavuniya' => l.authDistrictVavuniya,
    _ => raw,
  };
}
