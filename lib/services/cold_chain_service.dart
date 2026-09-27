import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/utils/firebase_values.dart';
import 'push_relay.dart';
import 'service_errors.dart';

/// One temperature reading on a delivery (`transport_jobs/{id}/temps`).
class TempReading {
  const TempReading({
    required this.celsius,
    required this.source,
    this.recordedAt,
  });

  final double celsius;

  /// manual (thermometer), sensor (logger device) or ambient (outside air
  /// at the vehicle's GPS position).
  final String source;
  final DateTime? recordedAt;

  factory TempReading.fromMap(Map<String, dynamic> d) => TempReading(
        celsius: firebaseDouble(d['celsius']) ?? 0,
        source: (d['source'] ?? 'manual').toString(),
        recordedAt: firebaseDate(d['recordedAt']),
      );
}

/// Cold-chain monitoring: target range per delivery, readings from the
/// carrier (thermometer / logger) plus automatic outside-air temperature at
/// the vehicle's live position, and breach alerts to farmer and buyer.
class ColdChainService {
  ColdChainService._({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static final ColdChainService instance = ColdChainService._();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Minimum gap between automatic outside-air readings per job.
  static const ambientEvery = Duration(minutes: 10);
  final Map<String, DateTime> _lastAmbient = {};
  final Map<String, bool> _isColdChain = {};

  DocumentReference<Map<String, dynamic>> _job(String id) =>
      _db.collection('transport_jobs').doc(id);

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw UserStateError('Authentication required.');
    return uid;
  }

  Stream<List<TempReading>> readings(String jobId, {int limit = 200}) => _job(jobId)
      .collection('temps')
      .orderBy('recordedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map((d) => TempReading.fromMap(d.data())).toList()
        ..sort((a, b) => (a.recordedAt ?? DateTime(0))
            .compareTo(b.recordedAt ?? DateTime(0))));

  /// Farmer sets (or clears, with [enabled] false) the required range.
  Future<void> setRequirement(String jobId,
      {required bool enabled, double min = 2, double max = 8}) async {
    if (enabled && !(min >= -30 && max <= 40 && min < max)) {
      throw UserArgumentError('Enter a range between -30 °C and 40 °C.');
    }
    _isColdChain.remove(jobId);
    await _job(jobId).update({
      'coldChain': enabled,
      if (enabled) 'tempMinC': min,
      if (enabled) 'tempMaxC': max,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Logs a reading; out-of-range readings alert the farmer and buyer.
  Future<void> logReading(
    String jobId,
    double celsius, {
    String source = 'manual',
    double? lat,
    double? lng,
  }) async {
    if (celsius < -40 || celsius > 70) {
      throw UserArgumentError('Enter a temperature between -40 and 70 °C.');
    }
    final uid = _uid;
    final job = (await _job(jobId).get()).data() ?? const {};
    final min = firebaseDouble(job['tempMinC']);
    final max = firebaseDouble(job['tempMaxC']);
    // Outside air is context, not the cargo: it never counts as a breach.
    final breach = source != 'ambient' &&
        job['coldChain'] == true &&
        min != null &&
        max != null &&
        (celsius < min || celsius > max);
    final batch = _db.batch()
      ..set(_job(jobId).collection('temps').doc(), {
        'celsius': celsius,
        'source': source,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'recordedBy': uid,
        'recordedAt': FieldValue.serverTimestamp(),
      });
    if (source != 'ambient') {
      batch.update(_job(jobId), {
        'lastTempC': celsius,
        'lastTempAt': FieldValue.serverTimestamp(),
        'tempBreachCount': FieldValue.increment(breach ? 1 : 0),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    if (breach) {
      final msg =
          '${job['productName'] ?? 'Cargo'} is at ${celsius.toStringAsFixed(1)} °C '
          '(required ${min.toStringAsFixed(0)}–${max.toStringAsFixed(0)} °C).';
      for (final to in [job['farmerId'], job['buyerId']]) {
        if (to is! String || to.isEmpty) continue;
        try {
          await sendNotification(_db, {
            'userId': to,
            'title': 'Cold chain alert',
            'body': msg,
            'type': 'logistics',
            'jobId': jobId,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }
    }
  }

  /// Current outside-air temperature (°C) at a position (Open-Meteo, free).
  Future<double?> ambientAt(double lat, double lng) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toStringAsFixed(4),
      'longitude': lng.toStringAsFixed(4),
      'current': 'temperature_2m',
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final t = (jsonDecode(res.body) as Map)['current']?['temperature_2m'];
    return t is num ? t.toDouble() : null;
  }

  /// Called with each live GPS fix of a delivery: every [ambientEvery] on a
  /// cold-chain job, logs the outside-air temperature at that spot.
  Future<void> onPosition(String jobId, double lat, double lng) async {
    final last = _lastAmbient[jobId];
    if (last != null && DateTime.now().difference(last) < ambientEvery) return;
    _lastAmbient[jobId] = DateTime.now();
    try {
      final cold = _isColdChain[jobId] ??=
          (await _job(jobId).get()).data()?['coldChain'] == true;
      if (!cold) return;
      final t = await ambientAt(lat, lng);
      if (t != null) await logReading(jobId, t, source: 'ambient', lat: lat, lng: lng);
    } catch (e) {
      debugPrint('Ambient temperature skipped: $e');
    }
  }
}
