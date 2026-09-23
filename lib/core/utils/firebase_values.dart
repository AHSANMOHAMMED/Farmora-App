/// Shared Firestore value parsing helpers.
///
/// Firestore `FieldValue.serverTimestamp()` values arrive as `Timestamp`
/// objects (with `toDate()` / `seconds` / `millisecondsSinceEpoch`), not ISO
/// strings. Parsing helpers here tolerate both shapes plus ISO strings.
library;

/// Converts a Firestore timestamp-ish value (Timestamp, ISO string, millis,
/// microseconds) into a [DateTime], or null when unparseable.
DateTime? firebaseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  // cloud_firestore Timestamp exposes toDate(); accessed reflectively so this
  // helper stays dependency-free for pure-Dart tests.
  try {
    final dynamic v = value;
    final dynamic date = v.toDate();
    if (date is DateTime) return date;
  } catch (_) {
    // Not a Timestamp — fall through to other shapes.
  }

  if (value is int) {
    // Firestore Timestamp microseconds are ~1e15+; millis are ~1e12.
    if (value > 100000000000000) {
      return DateTime.fromMicrosecondsSinceEpoch(value);
    }
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  final parsed = DateTime.tryParse(value.toString());
  if (parsed != null) return parsed;

  // Timestamp.toString() format: "2026-09-23 18:38:10.123Z" uses a space
  // instead of 'T' — normalize and retry.
  final asString = value.toString();
  if (asString.contains(' ') && !asString.contains('T')) {
    return DateTime.tryParse(asString.replaceFirst(' ', 'T'));
  }
  return null;
}

/// Safe int conversion that tolerates num and numeric strings.
int? firebaseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Safe double conversion that tolerates num and numeric strings.
double? firebaseDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
