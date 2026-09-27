import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transport_job.dart';
import 'service_errors.dart';

/// Last nine digits of a Sri Lankan phone number, so 077…, +9477… and
/// 77… all match.
String phoneKey(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  return digits.length > 9 ? digits.substring(digits.length - 9) : digits;
}

/// A driver's public card for fleet owners (`driver_profiles/{uid}`).
class DriverProfile {
  const DriverProfile({
    required this.driverId,
    required this.name,
    this.district = '',
    this.isVerified = false,
  });

  final String driverId;
  final String name;
  final String district;
  final bool isVerified;

  factory DriverProfile.fromMap(String id, Map<String, dynamic> d) =>
      DriverProfile(
        driverId: id,
        name: (d['name'] ?? '').toString(),
        district: (d['district'] ?? '').toString(),
        isVerified: d['isVerified'] == true,
      );
}

/// Transporter ↔ driver membership (`fleet_links/{transporterId}_{driverId}`):
/// invited → active (driver accepts) → removed (either side).
class FleetLink {
  const FleetLink({
    required this.id,
    required this.transporterId,
    required this.transporterName,
    required this.driverId,
    required this.driverName,
    required this.status,
  });

  final String id;
  final String transporterId;
  final String transporterName;
  final String driverId;
  final String driverName;
  final String status;

  factory FleetLink.fromMap(String id, Map<String, dynamic> d) => FleetLink(
        id: id,
        transporterId: (d['transporterId'] ?? '').toString(),
        transporterName: (d['transporterName'] ?? '').toString(),
        driverId: (d['driverId'] ?? '').toString(),
        driverName: (d['driverName'] ?? '').toString(),
        status: (d['status'] ?? 'invited').toString(),
      );
}

/// Fleets: drivers join a transporter, who assigns them deliveries. The
/// driver then advances the job (rules allow only those fields).
class FleetService {
  FleetService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get uid {
    final id = _auth.currentUser?.uid;
    if (id == null) throw UserStateError('Authentication required.');
    return id;
  }

  Future<Map<String, dynamic>> _me() async =>
      (await _db.collection('users').doc(uid).get()).data() ?? const {};

  String _name(Map<String, dynamic> me, String fallback) {
    final n = (me['displayName'] ?? me['name'] ?? '').toString().trim();
    return n.isEmpty ? fallback : n;
  }

  CollectionReference<Map<String, dynamic>> get _links =>
      _db.collection('fleet_links');

  // ── Driver ──────────────────────────────────────────────────

  /// Publishes / refreshes the driver's card so fleet owners can find them.
  Future<void> ensureDriverProfile() async {
    final me = await _me();
    await _db.collection('driver_profiles').doc(uid).set({
      'driverId': uid,
      'name': _name(me, 'Driver'),
      'phoneKey': phoneKey((me['phone'] ?? '').toString()),
      'district': (me['district'] ?? '').toString(),
      'isVerified': me['isVerified'] == true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<FleetLink>> myFleets() => _links
      .where('driverId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => FleetLink.fromMap(d.id, d.data())).toList());

  Future<void> respond(FleetLink link, {required bool accept}) =>
      _links.doc(link.id).update({
        'status': accept ? 'active' : 'removed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Stream<List<TransportJob>> assignedJobs() => _db
      .collection('transport_jobs')
      .where('driverId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => TransportJob.fromMap(d.id, d.data())).toList());

  // ── Transporter (fleet owner) ───────────────────────────────

  Future<DriverProfile?> findDriver(String phone) async {
    final key = phoneKey(phone);
    if (key.length < 9) throw UserArgumentError('Enter a full phone number.');
    final snap = await _db
        .collection('driver_profiles')
        .where('phoneKey', isEqualTo: key)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return DriverProfile.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  Stream<List<FleetLink>> myDrivers() => _links
      .where('transporterId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => FleetLink.fromMap(d.id, d.data())).toList());

  Future<void> invite(DriverProfile driver) async {
    final me = await _me();
    final ref = _links.doc('${uid}_${driver.driverId}');
    final existing = await ref.get();
    if (existing.exists) {
      if (existing.data()?['status'] == 'removed') {
        await ref.update({
          'status': 'invited',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return;
    }
    await ref.set({
      'transporterId': uid,
      'transporterName': _name(me, 'Transporter'),
      'driverId': driver.driverId,
      'driverName': driver.name,
      'status': 'invited',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    try {
      await _db.collection('notifications').add({
        'userId': driver.driverId,
        'title': 'Fleet invitation',
        'body': '${_name(me, 'A transporter')} invited you to drive for them.',
        'type': 'logistics',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> remove(FleetLink link) => _links.doc(link.id).update({
        'status': 'removed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Assigns (or, with null, unassigns) a driver to the owner's job.
  Future<void> assign(TransportJob job, FleetLink? driver) async {
    await _db.collection('transport_jobs').doc(job.id).update({
      'driverId': driver?.driverId ?? FieldValue.delete(),
      'driverName': driver?.driverName ?? FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (driver != null) {
      try {
        await _db.collection('notifications').add({
          'userId': driver.driverId,
          'title': 'New delivery assigned',
          'body': '${job.productName ?? job.title}: ${job.pickup ?? ''} → ${job.dropoff ?? ''}',
          'type': 'logistics',
          'jobId': job.id,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }
}
