import 'package:intl/intl.dart';

import 'l10n.dart';

/// Locale-aware formatting for dates, numbers and money.
///
/// Uses the current app language ([L10n.current]); pass [locale] to override.
/// Money is always shown as "LKR 1,234" (grouped digits) in every language.
class AppFormat {
  AppFormat._();

  static String get _locale => L10n.current.localeName;

  /// LKR 12,500 (or LKR 12,500.50 with [decimals]).
  static String lkr(num amount, {int decimals = 0, String? locale}) {
    final f = NumberFormat.decimalPatternDigits(
      locale: locale ?? _locale,
      decimalDigits: decimals,
    );
    return 'LKR ${f.format(amount)}';
  }

  /// 12,500 — grouped number without currency.
  static String number(num value, {int decimals = 0, String? locale}) =>
      NumberFormat.decimalPatternDigits(
        locale: locale ?? _locale,
        decimalDigits: decimals,
      ).format(value);

  /// 12K / 1.2M style.
  static String compact(num value, {String? locale}) =>
      NumberFormat.compact(locale: locale ?? _locale).format(value);

  /// 25 Sep 2026
  static String date(DateTime d, {String? locale}) =>
      DateFormat.yMMMd(locale ?? _locale).format(d);

  /// 25 Sep 2026, 14:30
  static String dateTime(DateTime d, {String? locale}) =>
      '${DateFormat.yMMMd(locale ?? _locale).format(d)}, '
      '${DateFormat.Hm(locale ?? _locale).format(d)}';

  /// 14:30
  static String time(DateTime d, {String? locale}) =>
      DateFormat.Hm(locale ?? _locale).format(d);

  /// September 2026
  static String monthYear(DateTime d, {String? locale}) =>
      DateFormat.yMMMM(locale ?? _locale).format(d);

  /// Sep 2026
  static String shortMonthYear(DateTime d, {String? locale}) =>
      DateFormat.yMMM(locale ?? _locale).format(d);

  /// Sep
  static String shortMonth(DateTime d, {String? locale}) =>
      DateFormat.MMM(locale ?? _locale).format(d);

  /// 25 Sep
  static String dayMonth(DateTime d, {String? locale}) =>
      DateFormat.MMMd(locale ?? _locale).format(d);

  /// "Just now", "5 mins ago", "3 hours ago", "Yesterday", or a date.
  static String relative(DateTime d, {DateTime? now}) {
    final l = L10n.current;
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.inMinutes < 1) return l.commonJustNow;
    if (diff.inHours < 1) return l.commonMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l.commonHoursAgo(diff.inHours);
    if (diff.inDays == 1) return l.commonYesterday;
    if (diff.inDays < 7) return l.commonDaysAgo(diff.inDays);
    return date(d);
  }
}
