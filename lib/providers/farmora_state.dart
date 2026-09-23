import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/services/firebase_auth_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/transport_job.dart';
import '../models/earnings_model.dart';
import '../models/verification_model.dart';
import '../models/cart_item.dart';
import '../models/notification_model.dart';
import '../models/offer.dart';
import '../services/firebase_service.dart' as kajana_service;

class FarmoraState extends ChangeNotifier {
  // Firebase services
  late final _authService = FirebaseAuthService();
  late final _firestoreService = kajana_service.FirestoreService();
  String _currentUserId = '';
  String get currentUserId => _currentUserId;
  bool _profileLoaded = false;
  bool get profileLoaded => _profileLoaded;

  // Stream subscriptions for real-time Firestore sync
  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<FarmoraOrder>>? _ordersSub;
  StreamSubscription<List<TransportJob>>? _jobsSub;
  StreamSubscription<List<VerificationDoc>>? _verificationSub;
  StreamSubscription<List<Map<String, dynamic>>>? _usersSub;
  StreamSubscription<List<FarmoraNotification>>? _notificationsSub;
  StreamSubscription<List<FarmoraOffer>>? _offersSub;
  StreamSubscription<String>? _deviceTokenSub;
  bool signedIn = false;
  String language = 'English';
  String country = 'Sri Lanka';
  String district = '';
  bool isVerified = false;
  String vehicleType = '';
  int capacityKg = 0;
  List<String> serviceDistricts = [];
  String displayName = '';
  String photoUrl = '';
  /// Default cart delivery fee in LKR major units (from platform settings).
  double defaultDeliveryFeeLkr = 350.0;
  Role role = Role.farmer;

  /// Locale driven by [language] preference (English / සිංහල / தமிழ் / en|si|ta).
  Locale get locale {
    final code = switch (language) {
      'සිංහල' || 'si' => 'si',
      'தமிழ்' || 'ta' => 'ta',
      _ => 'en',
    };
    return Locale(code);
  }

  // Search & Filter State
  String searchQuery = '';
  String selectedCategory = 'All';

  // Products
  final List<Product> _products = [];

  // Orders
  final List<FarmoraOrder> _orders = [];

  // Transport Jobs
  final List<TransportJob> _jobs = [];

  // Users
  final List<Map<String, dynamic>> _users = [];

  // Earnings Stats
  double _totalEarnings = 0.0;
  double _thisMonth = 0.0;
  double _thisWeek = 0.0;
  double _pendingPayments = 0.0;

  final List<MonthlyBarData> _monthlyBars = [];
  final List<EarningsTransaction> _transactions = [];

  // Verification Documents
  final List<VerificationDoc> _verificationDocs = [];

  // Notifications
  final List<FarmoraNotification> _notifications = [];

  // Offers (Buyer & Farmer Negotiations)
  final List<FarmoraOffer> _offers = [];

  // Constructor with demo data initialization
  FarmoraState() {
    _initDemoData();
  }

  // Getters
  List<Product> get products => List.unmodifiable(_products);
  List<FarmoraOrder> get orders => List.unmodifiable(_orders);
  List<TransportJob> get jobs => List.unmodifiable(_jobs);
  List<Map<String, dynamic>> get users => List.unmodifiable(_users);
  List<FarmoraNotification> get notifications => List.unmodifiable(_notifications);
  List<FarmoraOffer> get offers => List.unmodifiable(_offers);
  List<FarmoraOffer> get buyerOffers =>
      _offers.where((o) => _currentUserId.isEmpty || o.buyerId == _currentUserId || o.buyerId == 'buyer_demo').toList();
  List<FarmoraOffer> get farmerOffers =>
      _offers.where((o) => _currentUserId.isEmpty || o.farmerId == _currentUserId || o.farmerId == 'farmer_demo_1').toList();
  int get pendingOffersCount =>
      _offers.where((o) => o.status == 'pending' || o.status == 'countered').length;
  int get unreadNotificationsCount => _notifications.where((n) => !n.read).length;
  List<MonthlyBarData> get monthlyBars => List.unmodifiable(_monthlyBars);
  List<EarningsTransaction> get transactions =>
      List.unmodifiable(_transactions);
  List<VerificationDoc> get verificationDocs =>
      List.unmodifiable(_verificationDocs);

  double get totalEarnings => _totalEarnings;
  double get thisMonth => _thisMonth;
  double get thisWeek => _thisWeek;
  double get pendingPayments => _pendingPayments;

  String sortOrder = 'newest';
  double? minPrice;
  double? maxPrice;

  void setSortOrder(String v) {
    sortOrder = v;
    notifyListeners();
  }

  void setPriceRange({double? min, double? max}) {
    minPrice = min;
    maxPrice = max;
    notifyListeners();
  }

  List<Product> get filteredProducts {
    final list = _products.where((p) {
      final q = searchQuery.toLowerCase();
      final matchesSearch = searchQuery.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q);
      final matchesCategory = selectedCategory == 'All' ||
          p.category.toLowerCase() == selectedCategory.toLowerCase();
      final matchesMin = minPrice == null || p.effectivePricePerUnit >= minPrice!;
      final matchesMax = maxPrice == null || p.effectivePricePerUnit <= maxPrice!;
      return matchesSearch && matchesCategory && matchesMin && matchesMax;
    }).toList();
    switch (sortOrder) {
      case 'priceAsc':
        list.sort((a, b) => a.effectivePricePerUnit.compareTo(b.effectivePricePerUnit));
        break;
      case 'priceDesc':
        list.sort((a, b) => b.effectivePricePerUnit.compareTo(a.effectivePricePerUnit));
        break;
      case 'name':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        break;
    }
    return list;
  }

  List<Product> get activeProducts =>
      _products.where((p) => p.isActive).toList();

  List<FarmoraOrder> get pendingOrders =>
      _orders.where((o) => o.isPending).toList();
  List<FarmoraOrder> get acceptedOrders =>
      _orders.where((o) => o.isAccepted).toList();
  List<FarmoraOrder> get completedOrders =>
      _orders.where((o) => o.isCompleted).toList();

  // ── Cart (Buyer) ─────────────────────────────────────────
  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get cartItemCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal => _cartItems.fold(
      0.0, (sum, item) => sum + (item.product.effectivePricePerUnit * item.quantity));

  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex =
        _cartItems.indexWhere((c) => c.product.id == product.id);
    if (existingIndex != -1) {
      final existing = _cartItems[existingIndex];
      _cartItems[existingIndex] =
          existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      _cartItems.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((c) => c.product.id == productId);
    notifyListeners();
  }

  void updateCartQuantity(String productId, int quantity) {
    final index = _cartItems.indexWhere((c) => c.product.id == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  bool _placingOrder = false;
  bool get placingOrder => _placingOrder;
  String? _lastOrderKey;
  DateTime? _lastOrderAt;

  double get cartSubtotal => cartTotal;
  double get cartDeliveryFee => _cartItems.isEmpty ? 0.0 : defaultDeliveryFeeLkr;
  double get cartGrandTotal => cartSubtotal + cartDeliveryFee;

  String deliveryAddressDraft = '';

  Future<bool> placeOrder({String? deliveryAddress}) async {
    if (_cartItems.isEmpty || _placingOrder) return false;
    final address = (deliveryAddress ?? deliveryAddressDraft).trim();
    if (address.length < 5) return false;
    // Idempotency: same cart snapshot within 30s is treated as a repeated tap.
    final key = _cartItems.map((c) => '${c.product.id}:${c.quantity}').join('|');
    if (_lastOrderKey == key &&
        _lastOrderAt != null &&
        DateTime.now().difference(_lastOrderAt!).inSeconds < 30) {
      return false;
    }
    _placingOrder = true;
    notifyListeners();
    try {
      if (_currentUserId.isNotEmpty) {
        for (final item in _cartItems) {
          await _firestoreService.createSecureOrder(
            productId: item.product.id,
            quantity: item.quantity,
            deliveryFeeMinor: (cartDeliveryFee * 100).round(),
            deliveryAddress: address,
          );
        }
      }

      // Local optimistic order & job creation for instant UI update and demo mode
      for (final item in _cartItems) {
        final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}-${item.product.id.hashCode.abs() % 1000}';
        final subtotal = item.product.effectivePricePerUnit * item.quantity;
        final totalAmount = subtotal + cartDeliveryFee;
        final newOrder = FarmoraOrder(
          id: orderId,
          orderNumber: orderId,
          title: item.product.name,
          productName: item.product.name,
          quantity: '${item.quantity} ${item.product.unit}',
          totalAmount: 'LKR ${totalAmount.toStringAsFixed(2)}',
          totalAmountNumber: totalAmount,
          buyerName: displayName.isNotEmpty ? displayName : 'Demo Buyer',
          buyerCompany: 'Farmora Buyer Co.',
          deliveryAddress: address,
          detail: 'Direct order placed via Farmora Marketplace',
          status: 'Pending',
          progress: 0.2,
          color: item.product.color,
          timestamp: 'Just now',
          buyerId: _currentUserId.isNotEmpty ? _currentUserId : 'buyer_demo',
          farmerId: item.product.farmerId,
          subtotalMinor: (subtotal * 100).round(),
          deliveryFeeMinor: (cartDeliveryFee * 100).round(),
          totalMinor: (totalAmount * 100).round(),
          paymentStatus: 'Payment Required',
          escrowStatus: 'Held',
        );
        _orders.insert(0, newOrder);

        // Also create linked TransportJob so Transporters see the delivery job!
        final newJob = TransportJob(
          id: 'JOB-${DateTime.now().millisecondsSinceEpoch}-${item.product.id.hashCode.abs() % 1000}',
          orderId: orderId,
          title: '${item.product.name} Delivery',
          route: '${item.product.location} → $address',
          detail: '${item.quantity} ${item.product.unit} of ${item.product.name}',
          fee: 'LKR ${cartDeliveryFee.toStringAsFixed(2)}',
          pickup: item.product.location,
          dropoff: address,
          status: 'requested',
          buyerId: _currentUserId.isNotEmpty ? _currentUserId : 'buyer_demo',
          farmerId: item.product.farmerId,
        );
        _jobs.insert(0, newJob);
      }

      _lastOrderKey = key;
      _lastOrderAt = DateTime.now();
      _cartItems.clear();
      _recalculateStats();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    } finally {
      _placingOrder = false;
      notifyListeners();
    }
  }

  // Actions
  void signIn(Role r) {
    role = r;
    signedIn = true;
    notifyListeners();
    // If user is already authenticated via Firebase, init Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      initFromFirestore(user.uid);
    }
  }

  void signOut() {
    signedIn = false;
    _currentUserId = '';
    _profileLoaded = false;
    disposeFirestoreSubscriptions();
    _deviceTokenSub?.cancel();
    _deviceTokenSub = null;
    _authService.signOut();
    notifyListeners();
  }

  void setRole(Role r) {
    // A signed-in account's role is owned by its Firestore profile.
    if (_currentUserId.isNotEmpty) return;
    role = r;
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    if (_currentUserId.isNotEmpty) {
      final languageCode = switch (value) {
        'සිංහල' || 'si' => 'si',
        'தமிழ்' || 'ta' => 'ta',
        _ => 'en',
      };
      _firestoreService.updateUserLanguage(languageCode);
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void addProduct(Product p) {
    if (_currentUserId.isNotEmpty) {
      _firestoreService.createSecureProduct(p);
    } else {
      _products.insert(0, p);
      notifyListeners();
    }
  }

  void updateProduct(Product p) {
    final index = _products.indexWhere((prod) => prod.id == p.id);
    if (index != -1) {
      _products[index] = p;
      if (_currentUserId.isNotEmpty) {
        _firestoreService.updateProduct(p.id, p.toMap());
      }
      notifyListeners();
    }
  }

  void add(Product p) => addProduct(p);

  void toggleProductStock(String id) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final current = _products[index];
      final newStatus = current.status == 'Active' ? 'Empty' : 'Active';
      _products[index] = current.copyWith(status: newStatus);
      if (_currentUserId.isNotEmpty) {
        _firestoreService.updateProduct(id, {'status': newStatus});
      }
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    if (_currentUserId.isNotEmpty) {
      _firestoreService.deleteProduct(id);
    }
    notifyListeners();
  }

  void acceptOrder(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(status: 'Accepted', progress: 0.6);
      _recalculateStats();
      notifyListeners();
    }
    if (_currentUserId.isNotEmpty) {
      _firestoreService.updateOrderStatus(orderId, 'Accepted', 0.6);
    }
  }

  void completeOrder(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(status: 'Delivered', progress: 1.0);
      _recalculateStats();
      notifyListeners();
    }
    if (_currentUserId.isNotEmpty) {
      _firestoreService.updateOrderStatus(orderId, 'Delivered', 1.0);
    }
  }

  void declineOrder(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(status: 'Declined', progress: 0.0);
      _recalculateStats();
      notifyListeners();
    }
    if (_currentUserId.isNotEmpty) {
      _firestoreService.updateOrderStatus(orderId, 'Declined', 0.0);
    }
  }

  void cancelOrder(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(status: 'Cancelled', progress: 0.0);
      _recalculateStats();
      notifyListeners();
    }
    if (_currentUserId.isNotEmpty) {
      _firestoreService.updateOrderStatus(orderId, 'Cancelled', 0.0);
    }
  }

  // ── Offers & Negotiation CRUD ───────────────────────────
  Future<void> makeOffer({
    required String productId,
    required String productName,
    required String farmerId,
    required int quantity,
    required double price,
  }) async {
    final newOffer = FarmoraOffer(
      id: 'OFFER-${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      productName: productName,
      buyerId: _currentUserId.isNotEmpty ? _currentUserId : 'buyer_demo',
      farmerId: farmerId.isNotEmpty ? farmerId : 'farmer_demo_1',
      proposedQuantity: quantity,
      proposedPrice: price,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    _offers.insert(0, newOffer);
    notifyListeners();

    if (_currentUserId.isNotEmpty) {
      try {
        await _firestoreService.createOffer(
          productId: productId,
          proposedQuantity: quantity,
          proposedPrice: price,
        );
      } catch (e) {
        debugPrint('Firestore createOffer error: $e');
      }
    }
  }

  Future<void> acceptOffer(String offerId) async {
    final idx = _offers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      final off = _offers[idx];
      _offers[idx] = off.copyWith(status: 'accepted', updatedAt: DateTime.now());

      // When offer is accepted, create confirmed order!
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
      final totalAmount = off.proposedPrice * off.proposedQuantity;
      final newOrder = FarmoraOrder(
        id: orderId,
        orderNumber: orderId,
        title: off.productName,
        productName: off.productName,
        quantity: '${off.proposedQuantity} kg',
        totalAmount: 'LKR ${totalAmount.toStringAsFixed(2)}',
        totalAmountNumber: totalAmount,
        buyerName: displayName.isNotEmpty ? displayName : 'Demo Buyer',
        buyerCompany: 'Farmora Buyer Co.',
        deliveryAddress: deliveryAddressDraft.isNotEmpty ? deliveryAddressDraft : 'Colombo, Sri Lanka',
        detail: 'Contract created from accepted offer negotiation',
        status: 'Accepted',
        progress: 0.4,
        color: const Color(0xFF2E7D32),
        timestamp: 'Just now',
        buyerId: off.buyerId,
        farmerId: off.farmerId,
        subtotalMinor: (totalAmount * 100).round(),
        deliveryFeeMinor: 35000,
        totalMinor: ((totalAmount + 350) * 100).round(),
        paymentStatus: 'Payment Required',
        escrowStatus: 'Held',
      );
      _orders.insert(0, newOrder);
      _recalculateStats();
      notifyListeners();
    }
    if (_currentUserId.isNotEmpty) {
      await _firestoreService.acceptOffer(offerId: offerId);
    }
  }

  Future<void> rejectOffer(String offerId) async {
    final idx = _offers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      _offers[idx] = _offers[idx].copyWith(status: 'rejected', updatedAt: DateTime.now());
      notifyListeners();
    }
    if (_currentUserId.isNotEmpty) {
      await _firestoreService.rejectOffer(offerId);
    }
  }

  Future<void> counterOffer(String offerId, double counterPrice) async {
    final idx = _offers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      _offers[idx] = _offers[idx].copyWith(
        status: 'countered',
        proposedPrice: counterPrice,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
    if (_currentUserId.isNotEmpty) {
      await _firestoreService.updateOfferStatus(offerId, 'countered');
    }
  }

  Future<void> cancelOffer(String offerId) async {
    final idx = _offers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      _offers[idx] = _offers[idx].copyWith(status: 'cancelled', updatedAt: DateTime.now());
      notifyListeners();
    }
    if (_currentUserId.isNotEmpty) {
      await _firestoreService.rejectOffer(offerId);
    }
  }

  void acceptJob(String jobId) {
    if (_currentUserId.isNotEmpty) {
      _firestoreService.transitionTransport(jobId, 'accepted');
    }
  }

  void updateJobStatus(String jobId, String status) {
    if (_currentUserId.isNotEmpty) {
      _firestoreService.transitionTransport(jobId, status);
    }
  }

  Future<void> createTransportJob(TransportJob job) async {
    final orderId = job.orderId;
    if (orderId == null || orderId.isEmpty) {
      throw StateError('orderId required to request transport');
    }
    await _firestoreService.requestTransport(orderId: orderId);
  }

  Future<void> requestTransportForOrder(String orderId, {int? deliveryFeeMinor}) async {
    await _firestoreService.requestTransport(
      orderId: orderId,
      deliveryFeeMinor: deliveryFeeMinor,
    );
  }

  void updateTransportJob(String jobId, Map<String, dynamic> data) {
    _firestoreService.updateTransportJob(jobId, data);
  }

  void deleteTransportJob(String jobId) {
    _firestoreService.deleteTransportJob(jobId);
    _jobs.removeWhere((j) => j.id == jobId);
    notifyListeners();
  }

  Future<void> updateOrderAddress(String orderId, String newAddress) async {
    await _firestoreService.updateOrderAddressCallable(
      orderId: orderId,
      deliveryAddress: newAddress,
    );
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(deliveryAddress: newAddress);
      notifyListeners();
    }
  }

  Future<void> updateTransporterProfile({
    String? vehicleType,
    int? capacityKg,
    List<String>? serviceDistricts,
  }) async {
    await _firestoreService.updateTransporterProfile(
      vehicleType: vehicleType,
      capacityKg: capacityKg,
      serviceDistricts: serviceDistricts,
    );
    if (vehicleType != null) this.vehicleType = vehicleType;
    if (capacityKg != null) this.capacityKg = capacityKg;
    if (serviceDistricts != null) this.serviceDistricts = serviceDistricts;
    notifyListeners();
  }

  Future<void> setUserSuspended(String userId, bool suspended) async {
    await _firestoreService.setUserSuspended(userId: userId, suspended: suspended);
  }

  Future<void> releaseEscrow(String orderId) async {
    await _firestoreService.releaseEscrow(orderId: orderId);
  }

  Future<Map<String, dynamic>> exportUserData() async {
    return _firestoreService.exportUserData();
  }

  Future<void> deleteAccount() async {
    await _firestoreService.deleteAccount();
    signOut();
  }

  // ── Harvest video / QR / auto-delete / profile / trust ──
  Future<Map<String, String>?> uploadHarvestVideo({
    required String productId,
    required List<int> bytes,
    required String fileName,
  }) async {
    if (_currentUserId.isEmpty) return null;
    final result = await _firestoreService.uploadProductVideo(
      productId: productId,
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
    );
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _products[idx] = _products[idx].copyWith(
        videoPath: result['path'],
        videoUrl: result['url'],
        harvestStatus: HarvestStatus.harvested,
        harvestDate: DateTime.now(),
      );
      notifyListeners();
    }
    return result;
  }

  Future<String?> generateQrForProduct(String productId) async {
    if (_currentUserId.isEmpty) return null;
    final payload = await _firestoreService.generateProductQr(
      productId: productId,
      farmerId: _currentUserId,
    );
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _products[idx] = _products[idx].copyWith(
        qrCode: payload,
        packingDate: DateTime.now(),
        harvestStatus: HarvestStatus.packed,
      );
      notifyListeners();
    }
    return payload;
  }

  Future<void> deliverOrderAndCleanupVideo({
    required String orderId,
    required String productId,
    String? videoStoragePath,
    String? videoDownloadUrl,
  }) async {
    if (_currentUserId.isEmpty) return;
    await _firestoreService.markDeliveredAndCleanupVideo(
      orderId: orderId,
      productId: productId,
      videoStoragePath: videoStoragePath,
      videoDownloadUrl: videoDownloadUrl,
    );
  }

  Future<void> updateProfileLocation({
    required String newCountry,
    required String newDistrict,
  }) async {
    country = newCountry;
    district = newDistrict;
    notifyListeners();
    if (_currentUserId.isNotEmpty) {
      await _firestoreService.updateUserLocation(
        country: newCountry,
        district: newDistrict,
      );
    }
  }

  String trustLevelForProduct(Product p) {
    if (p.harvestStatus == HarvestStatus.delivered) return 'High';
    if (p.hasQrCode || p.hasVideo) return 'Medium';
    return p.trustLevel;
  }

  Future<void> seedDatabase() async {
    await _firestoreService.seedDatabase();
  }

  /// Initialize Firestore streams after user signs in.
  /// Loads data from Firestore in real-time while keeping mock data as fallback.
  Future<void> initFromFirestore(String uid) async {
    _currentUserId = uid;
    _profileLoaded = false;
    disposeFirestoreSubscriptions();

    // Load user profile and set role
    try {
      final profile = await _loadUserProfile(uid);
      if (profile == null) {
        await FirebaseAuth.instance.signOut();
        _currentUserId = '';
        notifyListeners();
        return;
      }

      final roleStr = profile['role'] as String?;
      final accountRole =
          Role.values.where((r) => r.name == roleStr).firstOrNull;
      if (accountRole == null) {
        await FirebaseAuth.instance.signOut();
        _currentUserId = '';
        notifyListeners();
        return;
      }
      role = accountRole;
      final rawLang =
          (profile['languageCode'] ?? profile['language'] ?? 'en').toString();
      language = switch (rawLang) {
        'si' || 'සිංහල' => 'සිංහල',
        'ta' || 'தமிழ்' => 'தமிழ்',
        'en' || 'English' => 'English',
        _ => rawLang,
      };
      country = (profile['country'] ?? 'Sri Lanka').toString();
      district = (profile['district'] ?? '').toString();
      displayName = (profile['name'] ?? profile['displayName'] ?? '').toString();
      photoUrl = (profile['photoUrl'] ?? '').toString();
      isVerified = profile['isVerified'] == true;
      vehicleType = (profile['vehicleType'] ?? '').toString();
      capacityKg = (profile['capacityKg'] as num?)?.toInt() ?? 0;
      serviceDistricts = (profile['serviceDistricts'] as List? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
      _profileLoaded = true;
      notifyListeners();
      _registerDeviceToken();
      _loadPlatformSettings();
    } catch (_) {
      await FirebaseAuth.instance.signOut();
      _currentUserId = '';
      notifyListeners();
      return;
    }
    final isAdmin = role == Role.admin;

    // Subscribe to products stream
    _productsSub?.cancel();
    final productsStream = role == Role.farmer
        ? _firestoreService.productsByFarmerStream(uid)
        : _firestoreService.productsStream();
    _productsSub = productsStream.listen((firestoreProducts) {
      _products.clear();
      _products.addAll(firestoreProducts);
      notifyListeners();
    });

    // Subscribe to users stream
    _usersSub?.cancel();
    if (isAdmin) {
      _usersSub = _firestoreService.usersStream().listen((firestoreUsers) {
        _users.clear();
        _users.addAll(firestoreUsers);
        notifyListeners();
      });
    }

    // Subscribe to orders stream
    _ordersSub?.cancel();
    final ordersStream = switch (role) {
      Role.admin => _firestoreService.ordersStream(),
      Role.farmer => _firestoreService.ordersByFarmerStream(uid),
      Role.buyer => _firestoreService.ordersByBuyerStream(uid),
      Role.transporter => _firestoreService.ordersByTransporterStream(uid),
    };
    _ordersSub = ordersStream.listen((firestoreOrders) {
      _orders.clear();
      _orders.addAll(firestoreOrders);
      _recalculateStats();
      notifyListeners();
    });

    // Subscribe to transport jobs stream
    _jobsSub?.cancel();
    final jobsStream = switch (role) {
      Role.admin => _firestoreService.jobsStream(),
      Role.transporter => _firestoreService.jobsForTransporterStream(uid),
      _ => _firestoreService.jobsStream(),
    };
    _jobsSub = jobsStream.listen((firestoreJobs) {
      _jobs.clear();
      _jobs.addAll(firestoreJobs);
      notifyListeners();
    });

    // Subscribe to verification docs (admin sees pending/all; others see own)
    _verificationSub?.cancel();
    final verificationStream = isAdmin
        ? _firestoreService.pendingVerificationDocsStream(pendingOnly: false)
        : _firestoreService.verificationDocsStream(uid);
    _verificationSub = verificationStream.listen((firestoreDocs) {
      _verificationDocs.clear();
      _verificationDocs.addAll(firestoreDocs);
      notifyListeners();
    });

    // Subscribe to notifications stream
    _notificationsSub?.cancel();
    _notificationsSub =
        _firestoreService.notificationsStream(uid).listen((notifs) {
      _notifications.clear();
      _notifications.addAll(notifs);
      notifyListeners();
    });

    // Subscribe to offers stream
    _offersSub?.cancel();
    final offersStream = role == Role.farmer
        ? _firestoreService.offersByFarmerStream(uid)
        : _firestoreService.offersByBuyerStream(uid);
    _offersSub = offersStream.listen((firestoreOffers) {
      _offers.clear();
      _offers.addAll(firestoreOffers);
      notifyListeners();
    });
  }

  /// Cancel all Firestore subscriptions
  void disposeFirestoreSubscriptions() {
    _productsSub?.cancel();
    _ordersSub?.cancel();
    _jobsSub?.cancel();
    _verificationSub?.cancel();
    _usersSub?.cancel();
    _notificationsSub?.cancel();
    _offersSub?.cancel();
  }

  void _initDemoData() {
    if (_products.isEmpty) {
      _products.addAll([
        const Product(
          id: 'prod-1',
          name: 'Organic Red Tomatoes',
          category: 'Vegetables',
          location: 'Nuwara Eliya',
          quantity: '150 kg',
          unit: 'kg',
          price: 'LKR 180 / kg',
          pricePerUnit: 180.0,
          emoji: '🍅',
          color: Color(0xFFFFEBEE),
          status: 'Active',
          isOrganic: true,
          description: 'Fresh highland organic ripe tomatoes harvested at peak freshness.',
          farmerId: 'farmer_demo_1',
        ),
        const Product(
          id: 'prod-2',
          name: 'Fresh Mountain Carrots',
          category: 'Vegetables',
          location: 'Nuwara Eliya',
          quantity: '300 kg',
          unit: 'kg',
          price: 'LKR 240 / kg',
          pricePerUnit: 240.0,
          emoji: '🥕',
          color: Color(0xFFFFF3E0),
          status: 'Active',
          isOrganic: true,
          description: 'Crunchy sweet farm fresh mountain carrots from Nuwara Eliya slopes.',
          farmerId: 'farmer_demo_1',
        ),
        const Product(
          id: 'prod-3',
          name: 'Ceylon Cinnamon Sticks',
          category: 'Spices',
          location: 'Matale',
          quantity: '50 kg',
          unit: 'kg',
          price: 'LKR 950 / kg',
          pricePerUnit: 950.0,
          emoji: '🪵',
          color: Color(0xFFEFEBE9),
          status: 'Active',
          isOrganic: true,
          description: 'Pure Alba-grade Ceylon cinnamon sticks with rich aroma and flavour.',
          farmerId: 'farmer_demo_2',
        ),
        const Product(
          id: 'prod-4',
          name: 'Cavendish Bananas',
          category: 'Fruits',
          location: 'Embilipitiya',
          quantity: '200 kg',
          unit: 'kg',
          price: 'LKR 160 / kg',
          pricePerUnit: 160.0,
          emoji: '🍌',
          color: Color(0xFFFFFDE7),
          status: 'Active',
          isOrganic: false,
          description: 'Naturally ripened Cavendish bananas, sweet and pesticide-free.',
          farmerId: 'farmer_demo_3',
        ),
        const Product(
          id: 'prod-5',
          name: 'Green Chillies',
          category: 'Vegetables',
          location: 'Dambulla',
          quantity: '80 kg',
          unit: 'kg',
          price: 'LKR 420 / kg',
          pricePerUnit: 420.0,
          emoji: '🌶️',
          color: Color(0xFFE8F5E9),
          status: 'Active',
          isOrganic: false,
          description: 'Spicy fresh green chillies direct from Dambulla agricultural hub.',
          farmerId: 'farmer_demo_2',
        ),
      ]);
    }

    if (_orders.isEmpty) {
      _orders.addAll([
        FarmoraOrder(
          id: 'ORD-1001',
          orderNumber: 'ORD-1001',
          title: 'Organic Red Tomatoes',
          productName: 'Organic Red Tomatoes',
          quantity: '25 kg',
          totalAmount: 'LKR 4,850.00',
          totalAmountNumber: 4850.0,
          buyerName: 'Cargills FoodCity',
          buyerCompany: 'Cargills Retail',
          deliveryAddress: 'No. 40, Colombo Road, Colombo 03',
          detail: 'Highland organic tomatoes batch A',
          status: 'In transit',
          progress: 0.7,
          color: const Color(0xFFE53935),
          timestamp: 'Today, 10:30 AM',
          buyerId: 'buyer_demo',
          farmerId: 'farmer_demo_1',
          paymentStatus: 'Paid (Escrow)',
          escrowStatus: 'Held',
        ),
        FarmoraOrder(
          id: 'ORD-1002',
          orderNumber: 'ORD-1002',
          title: 'Fresh Mountain Carrots',
          productName: 'Fresh Mountain Carrots',
          quantity: '50 kg',
          totalAmount: 'LKR 12,350.00',
          totalAmountNumber: 12350.0,
          buyerName: 'Keells Super',
          buyerCompany: 'Keells Holdings',
          deliveryAddress: 'No. 12, Kandy Road, Kadawatha',
          detail: 'A-grade fresh mountain carrots',
          status: 'Accepted',
          progress: 0.4,
          color: const Color(0xFFFB8C00),
          timestamp: 'Yesterday',
          buyerId: 'buyer_demo',
          farmerId: 'farmer_demo_1',
          paymentStatus: 'Payment Required',
          escrowStatus: 'Pending',
        ),
        FarmoraOrder(
          id: 'ORD-1003',
          orderNumber: 'ORD-1003',
          title: 'Ceylon Cinnamon Sticks',
          productName: 'Ceylon Cinnamon Sticks',
          quantity: '10 kg',
          totalAmount: 'LKR 9,850.00',
          totalAmountNumber: 9850.0,
          buyerName: 'Spices Lanka Ltd',
          buyerCompany: 'Spices Lanka',
          deliveryAddress: 'Export Zone, Katunayake',
          detail: 'Alba grade certified cinnamon',
          status: 'Delivered',
          progress: 1.0,
          color: const Color(0xFF43A047),
          timestamp: 'Sep 18, 2026',
          buyerId: 'buyer_demo',
          farmerId: 'farmer_demo_2',
          paymentStatus: 'Released',
          escrowStatus: 'Released',
        ),
      ]);
      _recalculateStats();
    }

    if (_jobs.isEmpty) {
      _jobs.addAll([
        const TransportJob(
          id: 'JOB-201',
          orderId: 'ORD-1001',
          title: 'Tomatoes Delivery',
          route: 'Nuwara Eliya → Colombo 03',
          detail: '25 kg fresh produce in crates',
          fee: 'LKR 1,500.00',
          status: 'inTransit',
          accepted: true,
          pickup: 'Nuwara Eliya',
          dropoff: 'Colombo 03',
          buyerId: 'buyer_demo',
          farmerId: 'farmer_demo_1',
        ),
        const TransportJob(
          id: 'JOB-202',
          orderId: 'ORD-1002',
          title: 'Carrots Dispatch',
          route: 'Nuwara Eliya → Kadawatha',
          detail: '50 kg mountain carrots',
          fee: 'LKR 2,200.00',
          status: 'requested',
          accepted: false,
          pickup: 'Nuwara Eliya',
          dropoff: 'Kadawatha',
          buyerId: 'buyer_demo',
          farmerId: 'farmer_demo_1',
        ),
      ]);
    }

    if (_offers.isEmpty) {
      _offers.addAll([
        FarmoraOffer(
          id: 'OFFER-301',
          productId: 'prod-1',
          productName: 'Organic Red Tomatoes',
          buyerId: 'buyer_demo',
          farmerId: 'farmer_demo_1',
          proposedQuantity: 80,
          proposedPrice: 165.0,
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        FarmoraOffer(
          id: 'OFFER-302',
          productId: 'prod-2',
          productName: 'Fresh Mountain Carrots',
          buyerId: 'buyer_demo',
          farmerId: 'farmer_demo_1',
          proposedQuantity: 120,
          proposedPrice: 220.0,
          status: 'countered',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        FarmoraOffer(
          id: 'OFFER-303',
          productId: 'prod-3',
          productName: 'Ceylon Cinnamon Sticks',
          buyerId: 'buyer_demo',
          farmerId: 'farmer_demo_2',
          proposedQuantity: 15,
          proposedPrice: 900.0,
          status: 'accepted',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ]);
    }
  }

  Future<void> sendInAppNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String? referenceId,
  }) async {
    await _firestoreService.sendInAppNotification(
      userId: userId,
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
    );
  }

  Future<void> markNotificationRead(String id) async {
    await _firestoreService.markNotificationRead(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(read: true);
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (_currentUserId.isNotEmpty) {
      await _firestoreService.markAllNotificationsRead(_currentUserId);
    }
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
    notifyListeners();
  }

  Future<void> _registerDeviceToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      final platform = kIsWeb
          ? 'web'
          : defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android';
      await _firestoreService.registerDeviceToken(
        token: token,
        platform: platform,
      );
      _deviceTokenSub?.cancel();
      _deviceTokenSub = messaging.onTokenRefresh.listen((nextToken) {
        _firestoreService.registerDeviceToken(
          token: nextToken,
          platform: platform,
        );
      });
    } catch (_) {
      // Push setup is optional until each platform's messaging credentials exist.
    }
  }

  void _recalculateStats() {
    _totalEarnings = 0.0;
    _thisMonth = 0.0;
    _thisWeek = 0.0;
    _pendingPayments = 0.0;

    final Map<String, double> monthlySums = {};
    _transactions.clear();

    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    for (final order in _orders) {
      if (order.isPending) {
        _pendingPayments += order.total;
      }

      // Earnings only from delivered/completed orders that are paid (LKR).
      final paid = order.paymentStatus == 'paid' ||
          order.paymentStatus == 'released';
      if (!order.isCompleted || !paid) continue;

      _totalEarnings += order.total;
      _transactions.add(EarningsTransaction(
        id: 'tx-${order.id}',
        orderNumber: order.orderNumber,
        date: order.timestamp,
        amount: order.total,
      ));

      final orderMonth = order.createdAt.millisecondsSinceEpoch > 0
          ? order.createdAt
          : now;
      final monthStr = months[orderMonth.month - 1];
      monthlySums[monthStr] = (monthlySums[monthStr] ?? 0.0) + order.total;
      if (orderMonth.year == now.year && orderMonth.month == now.month) {
        _thisMonth += order.total;
      }
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      if (!orderMonth.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day))) {
        _thisWeek += order.total;
      }
    }

    final maxAmount = monthlySums.values.fold<double>(0, (a, b) => a > b ? a : b);
    _monthlyBars.clear();
    monthlySums.forEach((month, amount) {
      _monthlyBars.add(MonthlyBarData(
        month: month,
        amount: amount,
        heightRatio: maxAmount > 0 ? amount / maxAmount : 0,
        isHighlighted: true,
      ));
    });
  }

  void updateVerificationDoc(String docId,
      {String? fileName,
      String? fileSizeInfo,
      String? imagePreview,
      VerificationStatus? status,
      String? errorMessage}) {
    final index = _verificationDocs.indexWhere((d) => d.id == docId);
    if (index != -1) {
      _verificationDocs[index] = _verificationDocs[index].copyWith(
        fileName: fileName,
        fileSizeInfo: fileSizeInfo,
        imagePreview: imagePreview,
        status: status ?? VerificationStatus.approved,
        errorMessage: errorMessage,
      );
    }
    notifyListeners();
  }

  Future<void> _loadPlatformSettings() async {
    try {
      final settings = await _firestoreService.getPlatformSettings();
      final feeMinor = (settings['defaultDeliveryFeeMinor'] as num?)?.toInt();
      if (feeMinor != null && feeMinor >= 0) {
        defaultDeliveryFeeLkr = feeMinor / 100.0;
        notifyListeners();
      }
    } catch (_) {
      // Keep last known / default fee.
    }
  }

  Future<Map<String, dynamic>?> _loadUserProfile(String uid) async {
    return await _authService.loadUserProfile(uid);
  }

  // ── Suka auth methods ────────────────────────────────
  String? authError;

  Future<bool> sendPhoneOtp(String phone) async {
    authError = null;
    try {
      await _authService.sendPhoneOtp(phone);
      notifyListeners();
      return true;
    } catch (error) {
      authError = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPhoneOtpLogin(String code) async {
    authError = null;
    try {
      final result = await _authService.loginWithPhoneOtp(code);
      role = result.role;
      signedIn = true;
      notifyListeners();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) initFromFirestore(user.uid);
      return true;
    } catch (error) {
      authError = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithBackend(
      {required String phone, required String password}) async {
    authError = null;
    try {
      final result = await _authService.login(phone: phone, password: password);
      role = result.role;
      signedIn = true;
      notifyListeners();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        initFromFirestore(user.uid);
      }
      return true;
    } catch (e) {
      authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithBackend(
      {required String name,
      required String phone,
      required String password,
      required Role role,
      String? district}) async {
    authError = null;
    try {
      final result = await _authService.register(
          name: name,
          phone: phone,
          password: password,
          role: role,
          district: district);
      this.role = result.role;
      signedIn = true;
      notifyListeners();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        initFromFirestore(user.uid);
      }
      return true;
    } catch (e) {
      authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    authError = null;
    try {
      final result = await _authService.loginWithGoogle();
      role = result.role;
      signedIn = true;
      notifyListeners();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        initFromFirestore(user.uid);
      }
      return true;
    } catch (e) {
      authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithGoogle(
      {required String name,
      required String phone,
      required Role role,
      String? district}) async {
    authError = null;
    try {
      final result = await _authService.registerWithGoogle(
          name: name, phone: phone, role: role);
      this.role = result.role;
      signedIn = true;
      notifyListeners();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        initFromFirestore(user.uid);
      }
      return true;
    } catch (e) {
      authError = e.toString();
      notifyListeners();
      return false;
    }
  }
}
