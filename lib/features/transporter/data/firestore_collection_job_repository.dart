import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/config/app_backend.dart';
import '../../../services/firebase_service.dart';
import '../domain/collection_job.dart';
import 'collection_job_repository.dart';

class FirestoreCollectionJobRepository implements CollectionJobRepository {
  FirestoreCollectionJobRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _jobs =>
      _firestore.collection('transport_jobs');

  CollectionReference<Map<String, dynamic>> get _issues =>
      _firestore.collection('transport_job_issues');

  CollectionReference<Map<String, dynamic>> get _ratings =>
      _firestore.collection('transport_job_ratings');

  @override
  Stream<List<CollectionJob>> watchJobs(String logisticsProviderId) {
    return _jobs
        .where('transporterId', isEqualTo: logisticsProviderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDocument).toList());
  }

  @override
  Future<List<CollectionJob>> getJobs(String logisticsProviderId) async {
    try {
      final snapshots = await Future.wait([
        _jobs
            .where('status', isEqualTo: 'requested')
            .orderBy('createdAt', descending: true)
            .get(),
        _jobs
            .where('transporterId', isEqualTo: logisticsProviderId)
            .orderBy('createdAt', descending: true)
            .get(),
      ]);
      final merged = <String, CollectionJob>{};
      for (final snapshot in snapshots) {
        for (final document in snapshot.docs) {
          merged[document.id] = _fromDocument(document);
        }
      }
      return merged.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on FirebaseException catch (error) {
      throw CollectionJobException(_firebaseMessage(error));
    }
  }

  @override
  Future<CollectionJob> getJob(String id) async {
    try {
      final document = await _jobs.doc(id).get();
      if (!document.exists) {
        throw const CollectionJobException('Job not found.');
      }
      return _fromDocument(document);
    } on CollectionJobException {
      rethrow;
    } on FirebaseException catch (error) {
      throw CollectionJobException(_firebaseMessage(error));
    }
  }

  @override
  Future<CollectionJob> acceptJob({
    required String jobId,
    required String logisticsProviderId,
  }) async {
    try {
      await _transition(jobId, 'accepted');
      return await getJob(jobId);
    } on FirebaseFunctionsException catch (error) {
      throw CollectionJobException(_functionMessage(error));
    }
  }

  @override
  Future<CollectionJob> updateStatus({
    required String jobId,
    required String logisticsProviderId,
    required CollectionJobStatus status,
    String? reason,
  }) async {
    try {
      if (status == CollectionJobStatus.collected) {
        await _transition(jobId, 'pickedUp');
      } else if (status == CollectionJobStatus.inTransit) {
        await _transition(jobId, 'inTransit');
      } else if (status == CollectionJobStatus.completed) {
        final snapshot = await _jobs.doc(jobId).get();
        final currentStatus = snapshot.data()?['status']?.toString();
        if (currentStatus == 'pickedUp') {
          await _transition(jobId, 'inTransit');
        }
        await _transition(jobId, 'delivered');
      } else if (status == CollectionJobStatus.cancelled) {
        await _transition(jobId, 'cancelled', reason: reason);
      } else {
        throw CollectionJobException(
          'Unsupported status update: ${status.label}.',
        );
      }
      return await getJob(jobId);
    } on CollectionJobException {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      throw CollectionJobException(_functionMessage(error));
    } on FirebaseException catch (error) {
      throw CollectionJobException(_firebaseMessage(error));
    }
  }

  Future<void> _transition(String jobId, String status,
      {String? reason}) async {
    if (!kUseCloudFunctions) {
      await FirestoreService().transitionTransport(jobId, status);
      return;
    }
    await _functions.httpsCallable('transitionTransport').call<void>({
      'jobId': jobId,
      'status': status,
      if (reason != null) 'reason': reason,
    });
  }

  @override
  Future<void> reportIssue({
    required String jobId,
    required String logisticsProviderId,
    required String reason,
    String description = '',
  }) async {
    try {
      await _issues.doc(jobId).set({
        'jobId': jobId,
        'logisticsProviderId': logisticsProviderId,
        'reason': reason,
        'description': description.trim(),
        'reportedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw CollectionJobException(_firebaseMessage(error));
    }
  }

  @override
  Future<void> rateDelivery({
    required String jobId,
    required String logisticsProviderId,
    required int stars,
    String comment = '',
  }) async {
    if (stars < 1 || stars > 5) {
      throw const CollectionJobException('Please select a valid rating.');
    }
    try {
      await _ratings.doc(jobId).set({
        'jobId': jobId,
        'logisticsProviderId': logisticsProviderId,
        'stars': stars,
        'comment': comment.trim(),
        'ratedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw CollectionJobException(_firebaseMessage(error));
    }
  }

  @override
  Future<JobIssueReport?> getIssueReport(String jobId) async {
    try {
      final document = await _issues.doc(jobId).get();
      final data = document.data();
      if (data == null) return null;
      return JobIssueReport(
        jobId: jobId,
        logisticsProviderId: data['logisticsProviderId']?.toString() ?? '',
        reason: data['reason']?.toString() ?? '',
        description: data['description']?.toString() ?? '',
        reportedAt: _date(data['reportedAt']) ?? DateTime.now(),
      );
    } on FirebaseException catch (error) {
      throw CollectionJobException(_firebaseMessage(error));
    }
  }

  @override
  Future<JobDeliveryRating?> getDeliveryRating(String jobId) async {
    try {
      final document = await _ratings.doc(jobId).get();
      final data = document.data();
      if (data == null) return null;
      return JobDeliveryRating(
        jobId: jobId,
        logisticsProviderId: data['logisticsProviderId']?.toString() ?? '',
        stars: (data['stars'] as num?)?.toInt() ?? 0,
        comment: data['comment']?.toString() ?? '',
        ratedAt: _date(data['ratedAt']) ?? DateTime.now(),
      );
    } on FirebaseException catch (error) {
      throw CollectionJobException(_firebaseMessage(error));
    }
  }

  CollectionJob _fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final pickup = _text(data, ['pickupLocation', 'pickupAddress']);
    final delivery = _text(data, ['deliveryLocation', 'dropoffAddress']);
    final status = _status(data['status']?.toString());
    final createdAt = _date(data['createdAt']) ?? DateTime.now();
    return CollectionJob(
      id: document.id,
      producePostId: _nullableText(data, ['producePostId', 'productId']),
      orderId: _nullableText(data, ['orderId']),
      farmerId: _text(data, ['farmerId', 'createdBy']),
      buyerId: _text(data, ['buyerId']),
      logisticsProviderId:
          _nullableText(data, ['logisticsProviderId', 'transporterId']),
      produceName: _text(
        data,
        ['produceName', 'productName', 'title'],
        fallback: 'Produce collection',
      ),
      quantity: _number(data, ['quantity', 'cargoWeightKg']),
      unit: _text(data, ['unit'], fallback: 'kg'),
      pickupLocation: pickup.isEmpty ? 'Pickup location not provided' : pickup,
      deliveryLocation:
          delivery.isEmpty ? 'Delivery location not provided' : delivery,
      collectionDate: _date(data['collectionDate']) ??
          _date(data['pickupTime']) ??
          createdAt,
      notes: _nullableText(data, ['notes', 'detail']),
      farmerName: _text(
        data,
        ['farmerName', 'pickupContactName'],
        fallback: 'Farmer details unavailable',
      ),
      farmerPhone: _text(data, ['farmerPhone', 'pickupContactPhone']),
      buyerName: _text(
        data,
        ['buyerName', 'deliveryContactName'],
        fallback: 'Buyer details unavailable',
      ),
      buyerPhone: _text(data, ['buyerPhone', 'deliveryContactPhone']),
      status: status,
      createdAt: createdAt,
      updatedAt: _date(data['updatedAt']) ?? createdAt,
      completedAt: _date(data['completedAt']) ?? _date(data['deliveredAt']),
      collectedAt: _date(data['collectedAt']) ?? _date(data['pickedUpAt']),
      inTransitAt: _date(data['inTransitAt']),
      acceptedAt:
          _date(data['acceptedAt']) ?? _date(data['acceptedByTransporterAt']),
      cancelledAt: _date(data['cancelledAt']),
      deliveryFeeMinor: _integer(data, ['deliveryFeeMinor']),
    );
  }

  CollectionJobStatus _status(String? value) {
    return switch (value) {
      'requested' || 'pending' || 'open' || 'OPEN' => CollectionJobStatus.open,
      'accepted' || 'ACCEPTED' => CollectionJobStatus.accepted,
      'pickedUp' || 'collected' || 'COLLECTED' => CollectionJobStatus.collected,
      'inTransit' ||
      'in_transit' ||
      'IN_TRANSIT' =>
        CollectionJobStatus.inTransit,
      'delivered' ||
      'completed' ||
      'COMPLETED' =>
        CollectionJobStatus.completed,
      'cancelled' || 'CANCELLED' => CollectionJobStatus.cancelled,
      _ => CollectionJobStatus.open,
    };
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  String _text(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    return _nullableText(data, keys) ?? fallback;
  }

  String? _nullableText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  double _number(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }

    return 0;
  }

  int? _integer(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  String _functionMessage(FirebaseFunctionsException error) {
    return switch (error.code) {
      'unauthenticated' => 'Please sign in again to continue.',
      'permission-denied' => 'Your transporter account cannot update this job.',
      'not-found' => 'This collection job no longer exists.',
      'failed-precondition' =>
        'This job was updated by someone else. Refresh and try again.',
      _ => error.message ?? 'Could not update the collection job.',
    };
  }

  String _firebaseMessage(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' =>
        'You do not have permission to view these collection jobs.',
      'unavailable' => 'The database is temporarily unavailable.',
      'failed-precondition' =>
        'A required Firestore index is not deployed yet.',
      _ => error.message ?? 'Could not load collection jobs.',
    };
  }
}
