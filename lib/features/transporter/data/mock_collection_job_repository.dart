import '../domain/collection_job.dart';
import 'collection_job_repository.dart';

class MockCollectionJobRepository implements CollectionJobRepository {
  MockCollectionJobRepository({List<CollectionJob>? seedJobs})
      : _jobs = List<CollectionJob>.from(seedJobs ?? _sampleJobs());

  final List<CollectionJob> _jobs;

  @override
  Stream<List<CollectionJob>> watchJobs(String logisticsProviderId) async* {
    yield await getJobs(logisticsProviderId);
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
    if (index < 0) throw const CollectionJobException('Job not found.');
    final job = _jobs[index];
    if (job.status != CollectionJobStatus.open ||
        job.logisticsProviderId != null) {
      throw const CollectionJobException(
        'This job has already been accepted by another provider.',
      );
    }
    final updated = job.copyWith(
      logisticsProviderId: logisticsProviderId,
      status: CollectionJobStatus.accepted,
      updatedAt: DateTime.now(),
    );
    _jobs[index] = updated;
    return updated;
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
    if (index < 0) throw const CollectionJobException('Job not found.');
    final job = _jobs[index];
    if (job.logisticsProviderId != logisticsProviderId) {
      throw const CollectionJobException('You are not assigned to this job.');
    }

    final allowed = switch (job.status) {
      CollectionJobStatus.accepted =>
        status == CollectionJobStatus.collected ||
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
        'Cannot change ${job.status.label} to ${status.label}.',
      );
    }

    final now = DateTime.now();
    final updated = job.copyWith(
      status: status,
      updatedAt: now,
      completedAt: status == CollectionJobStatus.completed ? now : null,
      collectedAt:
          status == CollectionJobStatus.collected ? now : job.collectedAt,
      inTransitAt:
          status == CollectionJobStatus.inTransit ? now : job.inTransitAt,
    );
    _jobs[index] = updated;
    return updated;
  }

  CollectionJob _find(String id) {
    try {
      return _jobs.firstWhere((job) => job.id == id);
    } on StateError {
      throw const CollectionJobException('Job not found.');
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
      int? completedDaysAgo,
    }) {
      final created = now.subtract(Duration(days: createdDaysAgo, hours: 2));
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
        completedAt: completedDaysAgo == null
            ? null
            : now.subtract(Duration(days: completedDaysAgo)),
      );
    }

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
      ),
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
      ),
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
      ),
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
        completedDaysAgo: 5,
      ),
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
      ),
    ];
  }
}
