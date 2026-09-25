import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the translations: every English key must exist in Tamil and
/// Sinhala, keep the same placeholders, and not just be the English text.
Map<String, String> _load(String lang) {
  final raw = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
      as Map<String, dynamic>;
  return {
    for (final e in raw.entries)
      if (!e.key.startsWith('@')) e.key: e.value as String,
  };
}

/// Placeholder names used in an ICU message (e.g. {count}, {name}).
Set<String> _placeholders(String message) => RegExp(r'\{(\w+)[,}]')
    .allMatches(message)
    .map((m) => m.group(1)!)
    .toSet();

/// Words that are legitimately the same in every language.
const _sameEverywhere = {
  'Farmora', 'LKR', 'WhatsApp', 'Google', 'OTP', 'QR', 'COD', 'SMS', 'PDF',
  'FCM', 'UID', 'Firebase', 'Cloud', 'Messaging', 'GMV', 'KYC', 'GPS', 'CSV',
  'km', 'kg',
};

/// True when [message] has real words to translate once placeholders,
/// ICU syntax, symbols and brand words are removed.
bool _hasTranslatableText(String message) {
  var text = message
      .replaceAll(RegExp(r'\{\w+\}'), ' ')
      .replaceAll(RegExp(r'\{\w+,\s*(plural|select)\s*,'), ' ')
      .replaceAll(RegExp(r'(=\d+|other|zero|one|few|many)\s*\{'), ' ');
  for (final word in _sameEverywhere) {
    text = text.replaceAll(word, ' ');
  }
  return RegExp(r'[A-Za-z]{3,}').hasMatch(text);
}

void main() {
  final en = _load('en');

  for (final lang in ['ta', 'si']) {
    group('app_$lang.arb', () {
      final other = _load(lang);

      test('has every English key', () {
        final missing = en.keys.where((k) => !other.containsKey(k)).toList();
        expect(missing, isEmpty, reason: 'Missing in $lang: $missing');
      });

      test('has no extra keys', () {
        final extra = other.keys.where((k) => !en.containsKey(k)).toList();
        expect(extra, isEmpty, reason: 'Not in en: $extra');
      });

      test('keeps the same placeholders', () {
        final wrong = [
          for (final k in en.keys)
            if (other.containsKey(k) &&
                !_placeholders(other[k]!)
                    .containsAll(_placeholders(en[k]!)))
              k,
        ];
        expect(wrong, isEmpty, reason: 'Placeholder mismatch in $lang: $wrong');
      });

      test('is actually translated', () {
        final untranslated = [
          for (final k in en.keys)
            if (other[k] != null &&
                (other[k] == en[k] ||
                    RegExp(r'^\[(TA|SI)\]').hasMatch(other[k]!)) &&
                _hasTranslatableText(en[k]!))
              k,
        ];
        expect(untranslated, isEmpty,
            reason: 'Still English in $lang: $untranslated');
      });
    });
  }
}
