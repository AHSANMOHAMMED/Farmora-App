import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firebase_service.dart';

/// Location sharing for active deliveries. Starts only with explicit user
/// consent, streams throttled GPS updates to the assigned transport job while
/// the delivery is active, and stops automatically once the job is delivered
/// or cancelled.
class DeliveryLocationService {
  DeliveryLocationService._();
  static final instance = DeliveryLocationService._();

  static const _minWriteInterval = Duration(seconds: 8);
  static const _distanceFilterMeters = 15;

  bool _sharing = false;
  String? _activeJobId;
  StreamSubscription<Position>? _positionSub;
  DateTime _lastWrite = DateTime.fromMillisecondsSinceEpoch(0);
  Position? _lastPosition;

  bool get isSharing => _sharing;
  String? get activeJobId => _activeJobId;

  /// The most recent position captured while sharing (for map markers).
  Position? get lastPosition => _lastPosition;

  /// Requests permission consent and begins streaming the courier's live
  /// position to Firestore for [jobId]. Returns false when permission or
  /// device location services are unavailable.
  Future<bool> requestConsentAndStart({required String jobId}) async {
    if (_sharing && _activeJobId == jobId) return true;

    if (!kIsWeb) {
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) return false;
    } else {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return false;
      }
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    // Capture an immediate first fix so the map shows something right away.
    try {
      final first = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
      _lastPosition = first;
      await _writePosition(jobId, first, force: true);
    } catch (e) {
      debugPrint('Initial location fix failed: $e');
    }

    _activeJobId = jobId;
    _sharing = true;
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _distanceFilterMeters,
      ),
    ).listen(
      (position) => _onPosition(jobId, position),
      onError: (e) => debugPrint('Location stream error: $e'),
    );
    return true;
  }

  void _onPosition(String jobId, Position position) {
    if (!_sharing || _activeJobId != jobId) return;
    _lastPosition = position;
    _writePosition(jobId, position);
  }

  /// Throttled Firestore write — at most one update per [_minWriteInterval].
  Future<void> _writePosition(
    String jobId,
    Position position, {
    bool force = false,
  }) async {
    final now = DateTime.now();
    if (!force && now.difference(_lastWrite) < _minWriteInterval) return;
    _lastWrite = now;
    try {
      await FirestoreService().updateTransportJobLocation(
        jobId: jobId,
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (e) {
      debugPrint('Courier location write failed: $e');
    }
  }

  /// One-shot manual refresh for users who tap "Update my location".
  Future<Position?> pushCurrentPosition({required String jobId}) async {
    if (!_sharing || _activeJobId != jobId) return null;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
      _lastPosition = pos;
      await _writePosition(jobId, pos, force: true);
      return pos;
    } catch (e) {
      debugPrint('Manual location push failed: $e');
      return null;
    }
  }

  /// One-shot GPS fix without requiring an active sharing session. Used by
  /// transition flows that want to stamp a position at pickup/transit time.
  Future<Position?> currentPositionQuick() async {
    try {
      if (!kIsWeb) {
        final status = await Permission.locationWhenInUse.status;
        if (!status.isGranted) return null;
      } else {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          return null;
        }
      }
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Quick location fix failed: $e');
      return null;
    }
  }

  void stopSharing({String? jobId}) {
    if (jobId != null && _activeJobId != null && jobId != _activeJobId) return;
    _positionSub?.cancel();
    _positionSub = null;
    _sharing = false;
    _activeJobId = null;
  }

  /// Auto-stop hook called on every delivery state transition.
  void onJobStatusChanged(String jobId, String status) {
    final normalized = status.toLowerCase().replaceAll(' ', '');
    if (normalized == 'delivered' || normalized == 'cancelled') {
      stopSharing(jobId: jobId);
    }
  }

  /// Stops any active session (e.g. on sign-out).
  void stopAll() {
    stopSharing();
    _lastPosition = null;
  }

  /// @visibleForTesting: simulates an active sharing session without GPS or
  /// permission prompts so state-machine behavior can be unit tested.
  void debugStartForTest(String jobId) {
    _activeJobId = jobId;
    _sharing = true;
  }

  /// True when the courier position is fresh enough to show as "live"
  /// (updated within the last two minutes).
  static bool isLocationFresh(DateTime? locationUpdatedAt) {
    if (locationUpdatedAt == null) return false;
    return DateTime.now().difference(locationUpdatedAt) <
        const Duration(minutes: 2);
  }

  /// Approximate distance in km between two positions; null when unknown.
  static double? distanceBetweenKm(Position? a, LatLngPoint? b) {
    if (a == null || b == null) return null;
    return distanceKmBetween(a.latitude, a.longitude, b.latitude, b.longitude);
  }
}

/// Plain lat/lng value object decoupled from google_maps types so this
/// service stays testable without platform channels.
class LatLngPoint {
  final double latitude;
  final double longitude;
  const LatLngPoint({required this.latitude, required this.longitude});
}

/// Haversine distance in kilometers (exposed for tests and UI labels).
double distanceKmBetween(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double deg(double d) => d * math.pi / 180.0;
  final dLat = deg(lat2 - lat1);
  final dLng = deg(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(deg(lat1)) * math.cos(deg(lat2)) *
          math.sin(dLng / 2) * math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}
