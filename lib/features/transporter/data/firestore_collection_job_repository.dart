import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/config/app_backend.dart';
import '../../../services/firebase_service.dart';
import 'package:flutter/foundation.dart';
import '../domain/collection_job.dart';
import 'collection_job_repository.dart';
import 'mock_collection_job_repository.dart';

class FirestoreCollectionJobRepository implements CollectionJobRepository {
  FirestoreCollectionJobRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  /// Provider the repository last loaded jobs for (scopes feedback reads).
  String _providerId = '';

  /// `requested` jobs addressed to [_providerId] (declinable).
  final Set<String> _targeted = {};

  @override
  bool isTargetedRequest(String jobId) => _targeted.contains(jobId);

  /// Whether an open job is visible to [providerId]: untargeted requests and
  /// requests addressed to them (not requests meant for someone else).
  bool _visibleOpenJob(Map<String, dynamic> data, String providerId) {
    final requested = data['requestedTransporterId']?.toString() ?? '';
    return requested.isEmpty || requested == providerId;
  }

  void _trackTargeted(
      DocumentSnapshot<Map<String, dynamic>> doc, String providerId) {
    final data = doc.data() ?? const <String, dynamic>{};
    final isRequested = (data['status']?.toString() ?? '') == 'requested';
    final targeted = isRequested &&
        (data['requestedTransporterId'] == providerId ||
            data['transporterId'] == providerId);
    if (targeted) {
      _targeted.add(doc.id);
    } else {
      _targeted.remove(doc.id);
    }
  }

  CollectionReference<Map<String, dynamic>> get _jobs =>
      _firestore.collection('transport_jobs');

  CollectionReference<Map<String, dynamic>> get _issues =>
      _firestore.collection('transport_job_issues');

  CollectionReference<Map<String, dynamic>> get _ratings =>
      _firestore.collection('transport_job_ratings');

  @override
  Stream<List<CollectionJob>> watchJobs(String logisticsProviderId) {
    _providerId = logisticsProviderId;
    late final StreamController<List<CollectionJob>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? availableSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? assignedSub;
    final available = <String, CollectionJob>{};
    final assigned = <String, CollectionJob>{};
    void emit() {
      final merged = {...available, ...assigned}.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (merged.isEmpty) {
        MockCollectionJobRepository()
            .getJobs(logisticsProviderId)
            .then((fallback) {
          if (!controller.isClosed) {
            controller.add(List.unmodifiable(fallback));
          }
        });
      } else {
        controller.add(List.unmodifiable(merged));
      }
    }

    controller = StreamController<List<CollectionJob>>(
      onListen: () {
        availableSub = _jobs
            .where('status', isEqualTo: 'requested')
            .where('transporterId', isNull: true)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen((snapshot) {
          final visible = snapshot.docs.where(
              (doc) => _visibleOpenJob(doc.data(), logisticsProviderId));
          for (final doc in snapshot.docs) {
            _trackTargeted(doc, logisticsProviderId);
          }
          available
            ..clear()
            ..addEntries(
                visible.map((doc) => MapEntry(doc.id, _fromDocument(doc))));
          emit();
        }, onError: (e) {
          debugPrint('Available jobs stream error: $e');
          emit();
        });
        assignedSub = _jobs
            .where('transporterId', isEqualTo: logisticsProviderId)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen((snapshot) {
          for (final doc in snapshot.docs) {
            _trackTargeted(doc, logisticsProviderId);
          }
          assigned
            ..clear()
            ..addEntries(snapshot.docs
                .map((doc) => MapEntry(doc.id, _fromDocument(doc))));
          emit();
        }, onError: (e) {
          debugPrint('Assigned jobs stream error: $e');
          emit();
        });
      },
      onCancel: () async {
        await availableSub?.cancel();
        await assignedSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<List<CollectionJob>> getJobs(String logisticsProviderId) async {
    _providerId = logisticsProviderId;
    try {
      final snapshots = await Future.wait([
        _jobs
            .where('status', isEqualTo: 'requested')
            .where('transporterId', isNull: true)
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
          _trackTargeted(document, logisticsProviderId);
          if (snapshot == snapshots.first &&
              !_visibleOpenJob(document.data(), logisticsProviderId)) {
            continue;
          }
          merged[document.id] = _fromDocument(document);
        }
      }
      if (merged.isEmpty) {
        return MockCollectionJobRepository().getJobs(logisticsProviderId);
      }
      return merged.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on FirebaseException catch (error) {
      debugPrint('Firestore getJobs error, fallback to mock: $error');
      return MockCollectionJobRepository().getJobs(logisticsProviderId);
    }
  }

  @override
  Future<CollectionJob> getJob(String id) async {
    try {
      final document = await _jobs.doc(id).get();
      if (!document.exists) {
        throw CollectionJobException(L10n.current.jobNotFound);
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
  Future<void> declineJob({
    required String jobId,
    required String logisticsProviderId,
  }) async {
    try {
      await _transition(jobId, 'declined');
      _targeted.remove(jobId);
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
          L10n.current.jobUnsupportedStatus(status.label),
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
      // One document per report (rules allow create with a generated id).
      await _issues.add({
        'jobId': jobId,
        'logisticsProviderId': logisticsProviderId,
        'reason': reason,
        'description': description.trim(),
        'reportedAt': FieldValue.serverTimestamp(),
      });
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
      throw CollectionJobException(L10n.current.jobInvalidRating);
    }
    try {
      await _ratings.doc(jobId).set({
        'jobId': jobId,
        'logisticsProviderId': logisticsProviderId,
        'stars': stars,
        'comment': comment.trim(),
        'ratedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw CollectionJobException(_firebaseMessage(error));
    }
  }

  @override
  Future<JobIssueReport?> getIssueReport(String jobId) async {
    try {
      Query<Map<String, dynamic>> query =
          _issues.where('jobId', isEqualTo: jobId);
      if (_providerId.isNotEmpty) {
        query = query.where('logisticsProviderId', isEqualTo: _providerId);
      }
      final snapshot = await query.limit(1).get();
      final data =
          snapshot.docs.isEmpty ? null : snapshot.docs.first.data();
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
    final pickup =
        _text(data, ['pickupLocation', 'pickupAddress', 'pickup']);
    final delivery =
        _text(data, ['deliveryLocation', 'dropoffAddress', 'dropoff']);
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
        fallback: L10n.current.jobProduceCollectionFallback,
      ),
      // `quantityValue` is numeric; legacy `quantity` may be "20 kg".
      quantity: _number(data, ['quantityValue', 'quantity', 'cargoWeightKg']),
      unit: _text(data, ['unit'], fallback: 'kg'),
      pickupLocation:
          pickup.isEmpty ? L10n.current.jobPickupNotProvided : pickup,
      deliveryLocation:
          delivery.isEmpty ? L10n.current.jobDeliveryNotProvided : delivery,
      collectionDate: _date(data['collectionDate']) ??
          _date(data['pickupTime']) ??
          createdAt,
      notes: _nullableText(data, ['notes', 'detail']),
      farmerName: _text(
        data,
        ['farmerName', 'pickupContactName'],
        fallback: L10n.current.jobFarmerDetailsUnavailable,
      ),
      farmerPhone: _text(data, ['farmerPhone', 'pickupContactPhone']),
      buyerName: _text(
        data,
        ['buyerName', 'deliveryContactName'],
        fallback: L10n.current.jobBuyerDetailsUnavailable,
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
      deliveryFeeMinor:
          _integer(data, ['deliveryFeeMinor', 'offeredFeeMinor']),
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
      // Leading number of strings such as "20 kg".
      final match =
          RegExp(r'^\s*(\d+(?:\.\d+)?)').firstMatch(value?.toString() ?? '');
      final parsed = double.tryParse(match?.group(1) ?? '');
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
    final l = L10n.current;
    return switch (error.code) {
      'unauthenticated' => l.errorSignInAgain,
      'permission-denied' => l.jobNoPermissionUpdate,
      'not-found' => l.jobNoLongerExists,
      'failed-precondition' => l.jobUpdatedElsewhere,
      _ => l.jobCouldNotUpdate,
    };
  }

  String _firebaseMessage(FirebaseException error) {
    final l = L10n.current;
    return switch (error.code) {
      'permission-denied' => l.jobNoPermissionView,
      'unavailable' => l.jobDatabaseUnavailable,
      'failed-precondition' => l.jobServiceNotReady,
      _ => l.jobCouldNotLoad,
    };
  }
}
