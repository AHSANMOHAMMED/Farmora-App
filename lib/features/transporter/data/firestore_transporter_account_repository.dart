import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/transporter_notification.dart';
import '../domain/transporter_profile.dart';
import 'transporter_account_repository.dart';

class FirestoreTransporterAccountRepository
    implements TransporterAccountRepository {
  FirestoreTransporterAccountRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<TransporterProfile> watchProfile(String providerId) {
    return _firestore.collection('users').doc(providerId).snapshots().map(
      (document) {
        final data = document.data();
        if (data == null) throw StateError('Transporter profile was not found.');
        return TransporterProfile.fromMap(document.id, data);
      },
    );
  }

  @override
  Stream<List<TransporterNotification>> watchNotifications(String providerId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((document) {
              final data = document.data();
              return TransporterNotification(
                id: document.id,
                type: _type(data['type']?.toString()),
                title: data['title']?.toString() ?? 'Farmora update',
                message: data['body']?.toString() ?? '',
                createdAt: _date(data['createdAt']) ?? DateTime.now(),
                jobId: data['jobId']?.toString(),
                isRead: data['read'] == true,
              );
            }).toList());
  }

  @override
  Future<void> markNotificationRead(String notificationId) {
    return _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  @override
  Future<void> markAllNotificationsRead(String providerId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: providerId)
        .where('read', isEqualTo: false)
        .limit(100)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final document in snapshot.docs) {
      batch.update(document.reference, {'read': true});
    }
    await batch.commit();
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String vehicleType,
    required String vehicleRegistration,
    required double? vehicleCapacity,
    required String vehicleCapacityUnit,
    required String vehicleDescription,
    required bool isAvailable,
  }) async {
    await _functions.httpsCallable('updateTransporterProfile').call<void>({
      'displayName': name,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehicleRegistration': vehicleRegistration,
      'vehicleCapacity': vehicleCapacity,
      'vehicleCapacityUnit': vehicleCapacityUnit,
      'vehicleDescription': vehicleDescription,
      'availabilityStatus': isAvailable ? 'available' : 'unavailable',
    });
  }

  TransporterNotificationType _type(String? value) {
    return switch (value) {
      'job_accepted' || 'accepted' => TransporterNotificationType.accepted,
      'collection_reminder' || 'reminder' =>
        TransporterNotificationType.reminder,
      'job_cancelled' || 'cancelled' =>
        TransporterNotificationType.cancelled,
      'delivery_completed' || 'completed' =>
        TransporterNotificationType.completed,
      _ => TransporterNotificationType.newJob,
    };
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
