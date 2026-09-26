import 'dart:async';

import '../../../core/localization/l10n.dart';
import '../domain/collection_job.dart';
import 'collection_job_repository.dart';

/// In-memory repository for local development and tests.
///
/// Seeds 13 jobs spanning every [CollectionJobStatus] so each CRUD path and
/// timeline state can be verified without Firebase. Mutations update the
/// in-memory store immediately and re-emit [watchJobs] streams, and per-job
/// issue reports / delivery ratings survive controller restarts.
class MockCollectionJobRepository implements CollectionJobRepository {
  MockCollectionJobRepository({List<CollectionJob>? seedJobs})
      : _jobs = List<CollectionJob>.from(seedJobs ?? _sampleJobs());

  final List<CollectionJob> _jobs;
  final Map<String, JobIssueReport> _issues = {};
  final Map<String, JobDeliveryRating> _ratings = {};
  final _jobsSubject = StreamController<List<CollectionJob>>.broadcast();

  void _emit() {
    if (!_jobsSubject.hasListener) return;
    _jobsSubject.add(List.unmodifiable(_jobs));
  }

  @override
  Stream<List<CollectionJob>> watchJobs(String logisticsProviderId) async* {
    // Mirror Firestore behaviour: emit the current snapshot immediately,
    // then re-emit whenever a mutation changes the store.
    yield await getJobs(logisticsProviderId);
    await for (final _ in _jobsSubject.stream) {
      yield await getJobs(logisticsProviderId);
    }
  }

  @override
  Future<List<CollectionJob>> getJobs(String logisticsProviderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final jobs = _jobs
        .where((job) =>
            job.status == CollectionJobStatus.open ||
            job.logisticsProviderId == logisticsProviderId)
        .toList()
      ..sort((a, b) => a.collectionDate.compareTo(b.collectionDate));
    return jobs;
  }

  @override
  Future<CollectionJob> getJob(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _find(id);
  }

  @override
  Future<CollectionJob> acceptJob({
    required String jobId,
    required String logisticsProviderId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index < 0) throw CollectionJobException(L10n.current.jobNotFound);
    final job = _jobs[index];
    if (job.status != CollectionJobStatus.open ||
        job.logisticsProviderId != null) {
      throw CollectionJobException(L10n.current.jobAlreadyAccepted);
    }
    final now = DateTime.now();
    _jobs[index] = job.copyWith(
      logisticsProviderId: logisticsProviderId,
      status: CollectionJobStatus.accepted,
      acceptedAt: now,
      updatedAt: now,
    );
    _emit();
    return _jobs[index];
  }

  @override
  bool isTargetedRequest(String jobId) {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    return index >= 0 &&
        _jobs[index].status == CollectionJobStatus.open &&
        _jobs[index].logisticsProviderId != null;
  }

  @override
  Future<void> declineJob({
    required String jobId,
    required String logisticsProviderId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index < 0) throw CollectionJobException(L10n.current.jobNotFound);
    final job = _jobs[index];
    if (job.status != CollectionJobStatus.open ||
        job.logisticsProviderId != logisticsProviderId) {
      throw CollectionJobException(L10n.current.jobNoLongerAvailable);
    }
    _jobs.removeAt(index);
    _emit();
  }

  @override
  Future<CollectionJob> updateStatus({
    required String jobId,
    required String logisticsProviderId,
    required CollectionJobStatus status,
    String? reason,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index < 0) throw CollectionJobException(L10n.current.jobNotFound);
    final job = _jobs[index];
    if (job.logisticsProviderId != logisticsProviderId) {
      throw CollectionJobException(L10n.current.jobNotAssigned);
    }

    final allowed = switch (job.status) {
      CollectionJobStatus.accepted => status == CollectionJobStatus.collected ||
          status == CollectionJobStatus.cancelled,
      CollectionJobStatus.collected =>
        status == CollectionJobStatus.inTransit ||
            status == CollectionJobStatus.completed ||
            status == CollectionJobStatus.cancelled,
      CollectionJobStatus.inTransit => status == CollectionJobStatus.completed,
      _ => false,
    };
    if (!allowed) {
      throw CollectionJobException(
        L10n.current.jobCannotChangeStatus(job.status.label, status.label),
      );
    }

    final now = DateTime.now();
    final updated = job.copyWith(
      status: status,
      updatedAt: now,
      acceptedAt: job.acceptedAt,
      completedAt: status == CollectionJobStatus.completed ? now : null,
      collectedAt:
          status == CollectionJobStatus.collected ? now : job.collectedAt,
      inTransitAt:
          status == CollectionJobStatus.inTransit ? now : job.inTransitAt,
      cancelledAt: status == CollectionJobStatus.cancelled ? now : null,
    );
    _jobs[index] = updated;
    _emit();
    return updated;
  }

  @override
  Future<void> reportIssue({
    required String jobId,
    required String logisticsProviderId,
    required String reason,
    String description = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final job = _find(jobId);
    if (job.logisticsProviderId != logisticsProviderId) {
      throw CollectionJobException(L10n.current.jobNotAssigned);
    }
    _issues[jobId] = JobIssueReport(
      jobId: jobId,
      logisticsProviderId: logisticsProviderId,
      reason: reason,
      description: description.trim(),
      reportedAt: DateTime.now(),
    );
    _emit();
  }

  @override
  Future<void> rateDelivery({
    required String jobId,
    required String logisticsProviderId,
    required int stars,
    String comment = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final job = _find(jobId);
    if (job.logisticsProviderId != logisticsProviderId) {
      throw CollectionJobException(L10n.current.jobNotAssigned);
    }
    if (stars < 1 || stars > 5) {
      throw CollectionJobException(L10n.current.jobInvalidRating);
    }
    _ratings[jobId] = JobDeliveryRating(
      jobId: jobId,
      logisticsProviderId: logisticsProviderId,
      stars: stars,
      comment: comment.trim(),
      ratedAt: DateTime.now(),
    );
    _emit();
  }

  @override
  Future<JobIssueReport?> getIssueReport(String jobId) async {
    return _issues[jobId];
  }

  @override
  Future<JobDeliveryRating?> getDeliveryRating(String jobId) async {
    return _ratings[jobId];
  }

  CollectionJob _find(String id) {
    try {
      return _jobs.firstWhere((job) => job.id == id);
    } on StateError {
      throw CollectionJobException(L10n.current.jobNotFound);
    }
  }

  static List<CollectionJob> _sampleJobs() {
    final now = DateTime.now();
    CollectionJob job({
      required String id,
      required String produce,
      required double quantity,
      required String unit,
      required String pickup,
      required String delivery,
      required int dayOffset,
      required int hour,
      required String farmer,
      required String buyer,
      required String notes,
      CollectionJobStatus status = CollectionJobStatus.open,
      String? providerId,
      int createdDaysAgo = 0,
      int? acceptedHoursAgo,
      int? collectedHoursAgo,
      int? inTransitHoursAgo,
      int? completedDaysAgo,
      int? cancelledHoursAgo,
      int? deliveryFeeMinor,
    }) {
      final created = now.subtract(Duration(days: createdDaysAgo, hours: 2));
      DateTime? past(int? hours) =>
          hours == null ? null : now.subtract(Duration(hours: hours));
      return CollectionJob(
        id: id,
        producePostId: 'post-$id',
        orderId: 'order-$id',
        farmerId: 'farmer-$id',
        buyerId: 'buyer-$id',
        logisticsProviderId: providerId,
        produceName: produce,
        quantity: quantity,
        unit: unit,
        pickupLocation: pickup,
        deliveryLocation: delivery,
        collectionDate:
            DateTime(now.year, now.month, now.day + dayOffset, hour),
        notes: notes,
        farmerName: farmer,
        farmerPhone: '+94 77 123 ${id.padLeft(4, '0')}',
        buyerName: buyer,
        buyerPhone: '+94 71 456 ${id.padLeft(4, '0')}',
        status: status,
        createdAt: created,
        updatedAt: created,
        acceptedAt: past(acceptedHoursAgo),
        collectedAt: past(collectedHoursAgo),
        inTransitAt: past(inTransitHoursAgo),
        completedAt: completedDaysAgo == null
            ? null
            : now.subtract(Duration(days: completedDaysAgo)),
        cancelledAt: past(cancelledHoursAgo),
        deliveryFeeMinor: deliveryFeeMinor,
      );
    }

    // ---- Open jobs (8) -------------------------------------------------
    return [
      job(
        id: '101',
        produce: 'Ceylon Tomatoes',
        quantity: 350,
        unit: 'kg',
        pickup: 'Dambulla, Matale',
        delivery: 'Pettah Market, Colombo 11',
        dayOffset: 1,
        hour: 7,
        farmer: 'Nimal Bandara',
        buyer: 'Lanka Fresh Traders',
        notes: 'Grade A tomatoes in 20 ventilated crates. Handle with care.',
        deliveryFeeMinor: 450000,
      ),
      job(
        id: '102',
        produce: 'Red Onions',
        quantity: 800,
        unit: 'kg',
        pickup: 'Kalpitiya, Puttalam',
        delivery: 'Economic Centre, Narahenpita',
        dayOffset: 2,
        hour: 6,
        farmer: 'Suresh Fernando',
        buyer: 'Green Basket (Pvt) Ltd',
        notes: 'Packed in 40 mesh bags. Covered vehicle preferred.',
        deliveryFeeMinor: 650000,
      ),
      job(
        id: '103',
        produce: 'Ambul Bananas',
        quantity: 120,
        unit: 'bunches',
        pickup: 'Embilipitiya, Ratnapura',
        delivery: 'Galle Municipal Market',
        dayOffset: 1,
        hour: 9,
        farmer: 'Kamal Jayasinghe',
        buyer: 'Southern Fruit Mart',
        notes: 'Do not stack more than three layers.',
        deliveryFeeMinor: 300000,
      ),
      job(
        id: '104',
        produce: 'Green Beans',
        quantity: 180,
        unit: 'kg',
        pickup: 'Nuwara Eliya',
        delivery: 'Kandy City Centre',
        dayOffset: 3,
        hour: 8,
        farmer: 'Malar Selvi',
        buyer: 'Hill Country Foods',
        notes: 'Fresh harvest; collection before 9:00 AM is essential.',
        deliveryFeeMinor: 400000,
      ),
      job(
        id: '105',
        produce: 'Keeri Samba Rice',
        quantity: 1000,
        unit: 'kg',
        pickup: 'Polonnaruwa',
        delivery: 'Kurunegala Wholesale Market',
        dayOffset: 4,
        hour: 10,
        farmer: 'Sunil Wijeratne',
        buyer: 'Wayamba Grocers',
        notes: '20 sealed 50 kg sacks. Keep dry during transport.',
        deliveryFeeMinor: 900000,
      ),
      job(
        id: '106',
        produce: 'Green Chilli',
        quantity: 90,
        unit: 'kg',
        pickup: 'Jaffna',
        delivery: 'Vavuniya Market',
        dayOffset: 0,
        hour: 17,
        farmer: 'Thavarajah Raj',
        buyer: 'Northern Spices',
        notes: 'Same-day collection required — very perishable.',
        deliveryFeeMinor: 250000,
      ),
      job(
        id: '107',
        produce: 'Watermelon',
        quantity: 2,
        unit: 'tons',
        pickup: 'Kilinochchi',
        delivery: 'Colombo 15 Wholesale',
        dayOffset: 5,
        hour: 6,
        farmer: 'Mahendran Siva',
        buyer: 'Metro Fruit Traders',
        notes: 'Bulk load — only large lorries.',
        deliveryFeeMinor: 1800000,
      ),
      job(
        id: '108',
        produce: 'Ash Plantains',
        quantity: 240,
        unit: 'kg',
        pickup: 'Puttalam',
        delivery: 'Kurunegala',
        dayOffset: 2,
        hour: 11,
        farmer: 'Ibrahim Rizwan',
        buyer: 'Wayamba Fresh',
        notes: 'Load is light for a lorry; good for a van.',
        deliveryFeeMinor: 220000,
      ),
      // ---- Accepted (1) --------------------------------------------------
      job(
        id: '090',
        produce: 'Carrots',
        quantity: 260,
        unit: 'kg',
        pickup: 'Ragala, Nuwara Eliya',
        delivery: 'Kandy Wholesale Market',
        dayOffset: 0,
        hour: 13,
        farmer: 'Arul Nathan',
        buyer: 'Central Produce Hub',
        notes: 'Washed and packed in crates.',
        status: CollectionJobStatus.accepted,
        providerId: 'demo-transporter',
        createdDaysAgo: 1,
        acceptedHoursAgo: 20,
        deliveryFeeMinor: 380000,
      ),
      // ---- Collected (1) -------------------------------------------------
      job(
        id: '089',
        produce: 'Pineapples',
        quantity: 220,
        unit: 'fruits',
        pickup: 'Gampaha',
        delivery: 'Negombo',
        dayOffset: 0,
        hour: 15,
        farmer: 'Ajith Kumara',
        buyer: 'Coastal Hotels Supply',
        notes: 'Collected and ready at the loading bay.',
        status: CollectionJobStatus.collected,
        providerId: 'demo-transporter',
        createdDaysAgo: 2,
        acceptedHoursAgo: 26,
        collectedHoursAgo: 4,
        deliveryFeeMinor: 180000,
      ),
      // ---- In transit (1) ------------------------------------------------
      job(
        id: '088',
        produce: 'Cabbage',
        quantity: 420,
        unit: 'kg',
        pickup: 'Nuwara Eliya',
        delivery: 'Colombo 05',
        dayOffset: 0,
        hour: 18,
        farmer: 'Dilani Herath',
        buyer: 'City Grocers',
        notes: 'On the road — expect delivery before 7 PM.',
        status: CollectionJobStatus.inTransit,
        providerId: 'demo-transporter',
        createdDaysAgo: 2,
        acceptedHoursAgo: 30,
        collectedHoursAgo: 6,
        inTransitHoursAgo: 3,
        deliveryFeeMinor: 520000,
      ),
      // ---- Completed (2) -------------------------------------------------
      job(
        id: '075',
        produce: 'Coconuts',
        quantity: 500,
        unit: 'nuts',
        pickup: 'Kuliyapitiya',
        delivery: 'Colombo 03',
        dayOffset: -5,
        hour: 8,
        farmer: 'Ruwan Perera',
        buyer: 'Island Foods',
        notes: 'Delivery completed without damage.',
        status: CollectionJobStatus.completed,
        providerId: 'demo-transporter',
        createdDaysAgo: 8,
        acceptedHoursAgo: 24 * 7 + 12,
        collectedHoursAgo: 24 * 5 + 10,
        inTransitHoursAgo: 24 * 5 + 6,
        completedDaysAgo: 5,
        deliveryFeeMinor: 600000,
      ),
      job(
        id: '074',
        produce: 'Red Rice',
        quantity: 600,
        unit: 'kg',
        pickup: 'Anamaduwa',
        delivery: 'Chilaw Market',
        dayOffset: -12,
        hour: 9,
        farmer: 'Wimalasena Silva',
        buyer: 'Puttalam Organics',
        notes: 'Organic certified produce.',
        status: CollectionJobStatus.completed,
        providerId: 'demo-transporter',
        createdDaysAgo: 15,
        acceptedHoursAgo: 24 * 13,
        collectedHoursAgo: 24 * 12 + 8,
        inTransitHoursAgo: 24 * 12 + 4,
        completedDaysAgo: 12,
        deliveryFeeMinor: 480000,
      ),
      // ---- Cancelled (1) -------------------------------------------------
      job(
        id: '070',
        produce: 'Papaya',
        quantity: 140,
        unit: 'kg',
        pickup: 'Anuradhapura',
        delivery: 'Dambulla',
        dayOffset: -9,
        hour: 9,
        farmer: 'Chamara Ekanayake',
        buyer: 'Fresh First',
        notes: 'Cancelled by the buyer before collection.',
        status: CollectionJobStatus.cancelled,
        providerId: 'demo-transporter',
        createdDaysAgo: 11,
        acceptedHoursAgo: 24 * 10,
        cancelledHoursAgo: 24 * 9 + 4,
        deliveryFeeMinor: null,
      ),
    ];
  }
}
