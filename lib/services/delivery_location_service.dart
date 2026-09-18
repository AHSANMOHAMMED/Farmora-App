import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Location sharing for active deliveries. Stops once the job/order is delivered.
class DeliveryLocationService {
  DeliveryLocationService._();
  static final instance = DeliveryLocationService._();

  bool _sharing = false;
  String? _activeJobId;

  bool get isSharing => _sharing;

  Future<bool> requestConsentAndStart({required String jobId}) async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) return false;
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    _activeJobId = jobId;
    _sharing = true;
    return true;
  }

  void stopSharing({String? jobId}) {
    if (jobId != null && _activeJobId != null && jobId != _activeJobId) return;
    _sharing = false;
    _activeJobId = null;
  }

  void onJobStatusChanged(String jobId, String status) {
    if (status == 'delivered' || status == 'cancelled') {
      stopSharing(jobId: jobId);
    }
  }

  Future<Position?> currentPosition() async {
    if (!_sharing) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
