import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firebase_service.dart';

/// Result of a location consent attempt.
enum LocationConsentResult {
  granted,
  permissionDenied,
  serviceDisabled,
}

/// Opt-in live location sharing for farmers and buyers.
///
/// Writes a throttled position to the user's own Firestore profile so order
/// participants and nearby transporters can see where they are. Users can
/// stop sharing at any time; sharing also stops automatically on sign-out.
class UserLocationService {
  UserLocationService._();
  static final instance = UserLocationService._();

  static const _minWriteInterval = Duration(seconds: 30);
  static const _distanceFilterMeters = 50;

  bool _sharing = false;
  StreamSubscription<Position>? _positionSub;
  DateTime _lastWrite = DateTime.fromMillisecondsSinceEpoch(0);
  Position? _lastPosition;

  bool get isSharing => _sharing;
  Position? get lastPosition => _lastPosition;

  /// Asks for consent and, when granted, shares this user's location live.
  Future<LocationConsentResult> startSharing() async {
    if (_sharing) return LocationConsentResult.granted;

    final status = await Permission.locationWhenInUse.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      return LocationConsentResult.permissionDenied;
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return LocationConsentResult.serviceDisabled;

    try {
      final first = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10));
      _lastPosition = first;
      await _write(first, force: true);
    } catch (e) {
      debugPrint('Initial user location fix failed: $e');
    }

    _sharing = true;
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: _distanceFilterMeters,
      ),
    ).listen(
      _onPosition,
      onError: (e) => debugPrint('User location stream error: $e'),
    );
    return LocationConsentResult.granted;
  }

  void _onPosition(Position position) {
    if (!_sharing) return;
    _lastPosition = position;
    _write(position);
  }

  Future<void> _write(Position position, {bool force = false}) async {
    final now = DateTime.now();
    if (!force && now.difference(_lastWrite) < _minWriteInterval) return;
    _lastWrite = now;
    try {
      await FirestoreService().updateMyLocation(
        lat: position.latitude,
        lng: position.longitude,
        accuracyLabel: position.accuracy.toStringAsFixed(0),
      );
    } catch (e) {
      debugPrint('User location write failed: $e');
    }
  }

  /// One-shot refresh from the profile toggle.
  Future<Position?> pushCurrentPosition() async {
    if (!_sharing) return null;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10));
      _lastPosition = pos;
      await _write(pos, force: true);
      return pos;
    } catch (e) {
      debugPrint('Manual user location push failed: $e');
      return null;
    }
  }

  void stopSharing() {
    _positionSub?.cancel();
    _positionSub = null;
    _sharing = false;
  }

  /// True when the stored profile location was refreshed recently enough
  /// to be considered "live" rather than a last-known snapshot.
  static bool isLocationFresh(DateTime? locationUpdatedAt) {
    if (locationUpdatedAt == null) return false;
    return DateTime.now().difference(locationUpdatedAt) <
        const Duration(minutes: 5);
  }
}
