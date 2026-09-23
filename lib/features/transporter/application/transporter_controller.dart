import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/collection_job_repository.dart';
import '../data/transporter_account_repository.dart';
import '../domain/collection_job.dart';
import '../domain/transporter_notification.dart';
import '../domain/transporter_profile.dart';

class TransporterActionResult {
  final bool success;
  final String message;

  const TransporterActionResult._(this.success, this.message);
  const TransporterActionResult.success(String message) : this._(true, message);
  const TransporterActionResult.failure(String message)
      : this._(false, message);
}

class TransporterController extends ChangeNotifier {
  TransporterController({
    required CollectionJobRepository repository,
    TransporterAccountRepository? accountRepository,
    String? providerId,
  })  : _repository = repository,
        _accountRepository = accountRepository ??
            const _UnavailableTransporterAccountRepository() {
    if (providerId != null && providerId.isNotEmpty) {
      bindProvider(providerId);
    } else {
      loadJobs();
    }
  }

  final CollectionJobRepository _repository;
  final TransporterAccountRepository _accountRepository;
  final List<CollectionJob> _jobs = [];
  final List<TransporterNotification> _notifications = [];
  final Map<String, ({int stars, String comment})> _ratings = {};
  final Set<String> _reportedIssues = {};
  StreamSubscription<List<CollectionJob>>? _jobsSubscription;
  StreamSubscription<List<TransporterNotification>>? _notificationsSubscription;
  StreamSubscription<dynamic>? _profileSubscription;
  int _bindingGeneration = 0;

  String providerId = '';
  bool isLoading = false;
  bool isRefreshing = false;
  String? loadError;
  String searchQuery = '';
  String selectedLocation = 'All locations';
  String selectedDelivery = 'All destinations';
  String selectedProduce = 'All produce';
  CollectionJobStatus? selectedStatus;
  DateTime? selectedDate;
  bool suitableOnly = false;

  String profileName = '';
  String phoneNumber = '';
  String? profilePhotoUrl;
  String vehicleType = '';
  String vehicleRegistration = '';
  double? vehicleCapacity;
  String vehicleCapacityUnit = 'kg';
  String vehicleDescription = '';
  bool isAvailable = false;

  List<CollectionJob> get allJobs => List.unmodifiable(_jobs);

  List<CollectionJob> get availableJobs => _jobs
      .where((job) => job.status == CollectionJobStatus.open)
      .where(_matchesFilters)
      .toList();

  List<CollectionJob> get unfilteredAvailableJobs =>
      _jobs.where((job) => job.status == CollectionJobStatus.open).toList();

  List<CollectionJob> get activeJobs => _jobs
      .where(
          (job) => job.logisticsProviderId == providerId && job.status.isActive)
      .toList();

  List<CollectionJob> get completedJobs => _jobs
      .where((job) =>
          job.logisticsProviderId == providerId &&
          job.status == CollectionJobStatus.completed)
      .toList()
    ..sort((a, b) =>
        (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt));

  List<CollectionJob> get cancelledJobs => _jobs
      .where((job) =>
          job.logisticsProviderId == providerId &&
          job.status == CollectionJobStatus.cancelled)
      .toList();

  List<TransporterNotification> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadNotificationCount =>
      _notifications.where((notification) => !notification.isRead).length;

  int get totalEarningsMinor => completedJobs.fold(
        0,
        (sum, job) => sum + (job.deliveryFeeMinor ?? 0),
      );

  int get thisWeekEarningsMinor => completedJobs
      .where((job) =>
          (job.completedAt ?? job.updatedAt)
              .isAfter(DateTime.now().subtract(const Duration(days: 7))))
      .fold(0, (sum, job) => sum + (job.deliveryFeeMinor ?? 0));

  int get todayEarningsMinor => completedJobs
      .where((job) {
        final date = job.completedAt ?? job.updatedAt;
        final now = DateTime.now();
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      })
      .fold(0, (sum, job) => sum + (job.deliveryFeeMinor ?? 0));

  List<String> get locationOptions {
    final values = unfilteredAvailableJobs
        .map((job) => job.pickupLocation.split(',').first.trim())
        .toSet()
        .toList()
      ..sort();
    if (selectedLocation != 'All locations' &&
        !values.contains(selectedLocation)) {
      values.add(selectedLocation);
      values.sort();
    }
    return ['All locations', ...values];
  }

  List<String> get produceOptions {
    final values = unfilteredAvailableJobs
        .map((job) => job.produceName)
        .toSet()
        .toList()
      ..sort();
    if (selectedProduce != 'All produce' && !values.contains(selectedProduce)) {
      values.add(selectedProduce);
      values.sort();
    }
    return ['All produce', ...values];
  }

  List<String> get deliveryOptions {
    final values = unfilteredAvailableJobs
        .map((job) => job.deliveryLocation.split(',').first.trim())
        .toSet()
        .toList()
      ..sort();
    return ['All destinations', ...values];
  }

  CollectionJob? jobById(String id) {
    for (final job in _jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  void bindProvider(String uid) {
    if (uid.isEmpty || (uid == providerId && _jobsSubscription != null)) return;
    final generation = ++_bindingGeneration;
    providerId = uid;
    isLoading = true;
    loadError = null;
    _jobs.clear();
    _notifications.clear();
    notifyListeners();

    _jobsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _profileSubscription?.cancel();

    _jobsSubscription = _repository.watchJobs(uid).listen(
      (jobs) {
        if (generation != _bindingGeneration) return;
        _jobs
          ..clear()
          ..addAll(jobs);
        isLoading = false;
        loadError = null;
        notifyListeners();
      },
      onError: (Object error) {
        if (generation != _bindingGeneration) return;
        isLoading = false;
        loadError = _friendlyError(error);
        notifyListeners();
      },
    );
    _notificationsSubscription =
        _accountRepository.watchNotifications(uid).listen(
      (items) {
        if (generation != _bindingGeneration) return;
        _notifications
          ..clear()
          ..addAll(items);
        notifyListeners();
      },
      onError: (_) {},
    );
    _profileSubscription = _accountRepository.watchProfile(uid).listen(
      (profile) {
        if (generation != _bindingGeneration) return;
        profileName = profile.name;
        phoneNumber = profile.phone;
        profilePhotoUrl = profile.photoUrl;
        vehicleType = profile.vehicleType;
        vehicleRegistration = profile.vehicleRegistration;
        vehicleCapacity = profile.vehicleCapacity;
        vehicleCapacityUnit = profile.vehicleCapacityUnit;
        vehicleDescription = profile.vehicleDescription;
        isAvailable = profile.isAvailable;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  Future<void> loadJobs({bool refresh = false}) async {
    if (isRefreshing) return;
    if (refresh) {
      isRefreshing = true;
    } else {
      isLoading = true;
    }
    loadError = null;
    notifyListeners();
    try {
      final jobs = await _repository.getJobs(providerId);
      _jobs
        ..clear()
        ..addAll(jobs);
    } catch (error) {
      loadError = _friendlyError(error);
    } finally {
      isLoading = false;
      isRefreshing = false;
      notifyListeners();
    }
  }

  void updateSearch(String value) {
    searchQuery = value.trim();
    notifyListeners();
  }

  void updateLocation(String? value) {
    selectedLocation = value ?? 'All locations';
    notifyListeners();
  }

  void updateProduce(String? value) {
    selectedProduce = value ?? 'All produce';
    notifyListeners();
  }

  void updateDelivery(String? value) {
    selectedDelivery = value ?? 'All destinations';
    notifyListeners();
  }

  void updateStatus(CollectionJobStatus? value) {
    selectedStatus = value;
    notifyListeners();
  }

  void updateSuitableOnly(bool value) {
    suitableOnly = value;
    notifyListeners();
  }

  void updateDate(DateTime? value) {
    selectedDate = value;
    notifyListeners();
  }

  void clearFilters() {
    searchQuery = '';
    selectedLocation = 'All locations';
    selectedDelivery = 'All destinations';
    selectedProduce = 'All produce';
    selectedStatus = null;
    selectedDate = null;
    suitableOnly = false;
    notifyListeners();
  }

  Future<TransporterActionResult> acceptJob(String jobId) async {
    final localJob = jobById(jobId);
    if (providerId.isEmpty) {
      return const TransporterActionResult.failure(
        'Please sign in again to accept this job.',
      );
    }
    if (localJob == null || localJob.status != CollectionJobStatus.open) {
      return const TransporterActionResult.failure(
        'This job is no longer available.',
      );
    }
    try {
      final updated = await _repository.acceptJob(
        jobId: jobId,
        logisticsProviderId: providerId,
      );
      _replaceJob(updated);
      _addLocalNotification(
        type: TransporterNotificationType.accepted,
        title: 'Job accepted successfully',
        message: '${updated.produceName} has been added to your active jobs.',
        jobId: updated.id,
      );
      notifyListeners();
      return const TransporterActionResult.success(
        'Job accepted and added to My Jobs.',
      );
    } catch (error) {
      return TransporterActionResult.failure(_friendlyError(error));
    }
  }

  Future<TransporterActionResult> markCollected(String jobId) =>
      _transitionJob(jobId, CollectionJobStatus.collected);

  Future<TransporterActionResult> completeDelivery(String jobId) =>
      _transitionJob(jobId, CollectionJobStatus.completed);

  Future<TransporterActionResult> startDelivery(String jobId) =>
      _transitionJob(jobId, CollectionJobStatus.inTransit);

  Future<TransporterActionResult> cancelJob(
    String jobId,
    String reason,
  ) =>
      _transitionJob(jobId, CollectionJobStatus.cancelled, reason: reason);

  Future<TransporterActionResult> reportIssue({
    required String jobId,
    required String reason,
    String description = '',
  }) async {
    if (jobById(jobId) == null || !activeJobs.any((job) => job.id == jobId)) {
      return const TransporterActionResult.failure(
        'Only active deliveries can have an issue reported.',
      );
    }
    _reportedIssues.add(jobId);
    return const TransporterActionResult.success(
      'Issue reported. Farmora support will follow up shortly.',
    );
  }

  Future<TransporterActionResult> rateDelivery({
    required String jobId,
    required int stars,
    String comment = '',
  }) async {
    if (stars < 1 || stars > 5 || !completedJobs.any((job) => job.id == jobId)) {
      return const TransporterActionResult.failure('Please select a valid rating.');
    }
    _ratings[jobId] = (stars: stars, comment: comment.trim());
    return const TransporterActionResult.success('Thank you for your feedback.');
  }

  Future<TransporterActionResult> _transitionJob(
    String jobId,
    CollectionJobStatus nextStatus,
    {String? reason}
  ) async {
    try {
      final updated = await _repository.updateStatus(
        jobId: jobId,
        logisticsProviderId: providerId,
        status: nextStatus,
        reason: reason,
      );
      _replaceJob(updated);
      if (nextStatus == CollectionJobStatus.completed) {
        _addLocalNotification(
          type: TransporterNotificationType.completed,
          title: 'Delivery completed',
          message: '${updated.produceName} was delivered successfully.',
          jobId: updated.id,
        );
      }
      notifyListeners();
      return TransporterActionResult.success(
        switch (nextStatus) {
          CollectionJobStatus.collected => 'Pickup confirmed.',
          CollectionJobStatus.inTransit => 'Delivery started.',
          CollectionJobStatus.cancelled => 'Job cancelled.',
          _ => 'Delivery completed successfully.',
        },
      );
    } catch (error) {
      return TransporterActionResult.failure(_friendlyError(error));
    }
  }

  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0 || _notifications[index].isRead) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
    try {
      await _accountRepository.markNotificationRead(id);
    } catch (_) {
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsRead() async {
    final previous = List<TransporterNotification>.from(_notifications);
    for (var index = 0; index < _notifications.length; index++) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
    notifyListeners();
    try {
      await _accountRepository.markAllNotificationsRead(providerId);
    } catch (_) {
      _notifications
        ..clear()
        ..addAll(previous);
      notifyListeners();
    }
  }

  Future<TransporterActionResult> setAvailability(bool value) async {
    final previous = isAvailable;
    isAvailable = value;
    notifyListeners();
    try {
      await _accountRepository.updateProfile(
        name: profileName,
        phone: phoneNumber,
        vehicleType: vehicleType,
        vehicleRegistration: vehicleRegistration,
        vehicleCapacity: vehicleCapacity,
        vehicleCapacityUnit: vehicleCapacityUnit,
        vehicleDescription: vehicleDescription,
        isAvailable: value,
      );
      return const TransporterActionResult.success('Availability updated.');
    } catch (error) {
      isAvailable = previous;
      notifyListeners();
      return TransporterActionResult.failure(_friendlyError(error));
    }
  }

  Future<TransporterActionResult> updateProfile({
    required String name,
    required String phone,
    required String vehicle,
    required String registration,
    required double? capacity,
    required String capacityUnit,
    required String description,
  }) async {
    if (name.trim().isEmpty || phone.trim().isEmpty) {
      return const TransporterActionResult.failure(
        'Name and phone number are required.',
      );
    }
    if (registration.trim().isEmpty) {
      return const TransporterActionResult.failure(
        'Vehicle registration number is required.',
      );
    }
    try {
      await _accountRepository.updateProfile(
        name: name.trim(),
        phone: phone.trim(),
        vehicleType: vehicle.trim(),
        vehicleRegistration: registration.trim().toUpperCase(),
        vehicleCapacity: capacity,
        vehicleCapacityUnit: capacityUnit,
        vehicleDescription: description.trim(),
        isAvailable: isAvailable,
      );
      return const TransporterActionResult.success(
        'Profile updated successfully.',
      );
    } catch (error) {
      return TransporterActionResult.failure(_friendlyError(error));
    }
  }

  bool _matchesFilters(CollectionJob job) {
    final query = searchQuery.toLowerCase();
    final matchesSearch = query.isEmpty ||
        job.produceName.toLowerCase().contains(query) ||
        job.pickupLocation.toLowerCase().contains(query) ||
        job.deliveryLocation.toLowerCase().contains(query);
    final matchesLocation = selectedLocation == 'All locations' ||
        job.pickupLocation
            .toLowerCase()
            .contains(selectedLocation.toLowerCase());
    final matchesDelivery = selectedDelivery == 'All destinations' ||
        job.deliveryLocation
            .toLowerCase()
            .contains(selectedDelivery.toLowerCase());
    final matchesProduce =
        selectedProduce == 'All produce' || job.produceName == selectedProduce;
    final matchesDate = selectedDate == null ||
        (job.collectionDate.year == selectedDate!.year &&
            job.collectionDate.month == selectedDate!.month &&
            job.collectionDate.day == selectedDate!.day);
    final matchesStatus =
        selectedStatus == null || job.status == selectedStatus;
    final matchesCapacity = !suitableOnly ||
        vehicleCapacity == null ||
        _capacityInKg(job) <= _capacityInKgForVehicle;
    return matchesSearch &&
        matchesLocation &&
        matchesDelivery &&
        matchesProduce &&
        matchesDate &&
        matchesStatus &&
        matchesCapacity;
  }

  double get _capacityInKgForVehicle =>
      (vehicleCapacity ?? double.infinity) *
      (vehicleCapacityUnit == 'tons' ? 1000 : 1);

  double _capacityInKg(CollectionJob job) {
    return job.unit.toLowerCase().contains('ton')
        ? job.quantity * 1000
        : job.quantity;
  }

  void _replaceJob(CollectionJob updated) {
    final index = _jobs.indexWhere((job) => job.id == updated.id);
    if (index >= 0) {
      _jobs[index] = updated;
    } else {
      _jobs.add(updated);
    }
  }

  void _addLocalNotification({
    required TransporterNotificationType type,
    required String title,
    required String message,
    required String jobId,
  }) {
    if (_notifications.any(
      (notification) =>
          notification.jobId == jobId && notification.type == type,
    )) {
      return;
    }
    _notifications.insert(
      0,
      TransporterNotification(
        id: 'local-$jobId-${type.name}',
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        jobId: jobId,
      ),
    );
  }

  String _friendlyError(Object error) {
    if (error is CollectionJobException) return error.message;
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.isEmpty
        ? 'Something went wrong. Please try again.'
        : message;
  }

  @override
  void dispose() {
    _bindingGeneration++;
    _jobsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}

class _UnavailableTransporterAccountRepository
    implements TransporterAccountRepository {
  const _UnavailableTransporterAccountRepository();

  @override
  Stream<TransporterProfile> watchProfile(String providerId) =>
      const Stream.empty();

  @override
  Stream<List<TransporterNotification>> watchNotifications(String providerId) =>
      const Stream.empty();

  @override
  Future<void> markNotificationRead(String notificationId) async {}

  @override
  Future<void> markAllNotificationsRead(String providerId) async {}

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
  }) async {}
}
