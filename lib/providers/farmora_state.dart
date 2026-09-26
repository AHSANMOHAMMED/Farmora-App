import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctionsException;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/services/firebase_auth_service.dart';
import 'dart:async';
import 'dart:math';
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
import '../models/market_price_index.dart';
import '../models/review_model.dart';
import '../models/audit_log_model.dart';
import '../models/settlement_model.dart';
import '../services/delivery_location_service.dart';
import '../services/firebase_service.dart' as kajana_service;
import '../services/service_errors.dart';
import '../services/user_location_service.dart';
import '../models/bank_details.dart';
import '../services/payment_service.dart';
import '../services/earnings_calculator.dart';
import '../core/utils/app_errors.dart';
import '../core/localization/app_format.dart';
import '../core/localization/l10n.dart';
import '../core/localization/language_prefs.dart';
import '../core/utils/image_upload.dart';
import '../models/conversation_model.dart';
import 'package:intl/intl.dart';

class FarmoraState extends ChangeNotifier {
  // Firebase services
  late final _authService = FirebaseAuthService();
  late final _firestoreService = kajana_service.FirestoreService();
  late final _paymentService = PaymentService();
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
  StreamSubscription<List<Review>>? _reviewsSub;
  StreamSubscription<List<AuditLog>>? _auditLogsSub;
  StreamSubscription<List<SettlementPayout>>? _settlementsSub;
  StreamSubscription<List<MarketPriceIndex>>? _marketPricesSub;
  StreamSubscription<String>? _deviceTokenSub;
  StreamSubscription<BankDetails>? _bankDetailsSub;
  bool _ordersLoading = false;
  bool signedIn = false;

  String _language = AppLanguage.english.nativeName;
  int _languageVersion = 0;

  /// Chosen language as its native name: 'English', 'தமிழ்' or 'සිංහල'.
  /// Setting it (a code or a name) switches the whole app at once: it keeps
  /// [L10n.current] in step and notifies the MaterialApp. It does not save
  /// the choice — use [setLanguage] for a user choice.
  String get language => _language;
  set language(String value) {
    _language = AppLanguage.from(value).nativeName;
    _languageVersion++;
    L10n.updateLocale(locale);
    notifyListeners();
  }

  /// 'en', 'ta' or 'si' — the value stored on the device and the profile.
  String get languageCode => AppLanguage.from(_language).code;

  String country = 'Sri Lanka';
  String district = '';
  bool isVerified = false;
  String vehicleType = '';
  int capacityKg = 0;
  List<String> serviceDistricts = [];
  String displayName = '';
  String photoUrl = '';
  String phone = '';
  String farmName = '';
  String farmSize = '';
  List<String> mainCrops = [];

  /// When the account was created (users/{uid}.createdAt); null if unknown.
  DateTime? memberSince;

  /// Default cart delivery fee in LKR major units (from platform settings).
  double defaultDeliveryFeeLkr = 350.0;
  Role role = Role.farmer;

  /// Locale driven by [language].
  Locale get locale => Locale(languageCode);

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

  // Market Price Intelligence (Sri Lankan Pola Benchmarks)
  final List<MarketPriceIndex> _marketPrices = [];

  // Reviews & Platform Moderation
  final List<Review> _reviews = [];

  // Security & Compliance Audit Trail
  final List<AuditLog> _auditLogs = [];

  // Treasury & Bank Escrow Settlements
  final List<SettlementPayout> _settlements = [];

  // Server Maintenance & Platform Config
  bool _maintenanceMode = false;
  String _maintenanceNotice =
      'Platform scheduled maintenance in progress. Marketplace trades will resume shortly.';
  double _commissionRate = 5.0; // percent
  int _escrowReleaseHours = 48;
  String _minAppVersion = '1.0.0';

  // Farmer payout account for Bank Deposit orders.
  BankDetails _myBankDetails = BankDetails.empty;
  BankDetails get myBankDetails => _myBankDetails;
  bool get hasBankDetails => _myBankDetails.isComplete;

  /// [initialLanguageCode] is the language saved on the device (loaded
  /// before runApp) so the first frame is already in that language.
  FarmoraState({String? initialLanguageCode}) {
    _language = AppLanguage.from(initialLanguageCode).nativeName;
    L10n.updateLocale(locale);
  }

  /// Applies the language saved on the device, unless the language was
  /// changed in the meantime (user choice or profile load).
  Future<void> restoreSavedLanguage() async {
    final version = _languageVersion;
    final code = await LanguagePrefs.load();
    if (code == null || version != _languageVersion) return;
    if (code != languageCode) language = code;
  }

  // Getters
  List<Product> get products => List.unmodifiable(_products);
  List<FarmoraOrder> get orders => List.unmodifiable(_orders);
  List<TransportJob> get jobs => List.unmodifiable(_jobs);
  List<Map<String, dynamic>> get users => List.unmodifiable(_users);
  List<FarmoraNotification> get notifications =>
      List.unmodifiable(_notifications);
  List<FarmoraOffer> get offers => List.unmodifiable(_offers);
  List<MarketPriceIndex> get marketPrices => List.unmodifiable(_marketPrices);
  List<Review> get reviews => List.unmodifiable(_reviews);
  List<AuditLog> get auditLogs => List.unmodifiable(_auditLogs);
  List<SettlementPayout> get settlements => List.unmodifiable(_settlements);
  bool get maintenanceMode => _maintenanceMode;
  String get maintenanceNotice => _maintenanceNotice;
  double get commissionRate => _commissionRate;
  int get escrowReleaseHours => _escrowReleaseHours;
  String get minAppVersion => _minAppVersion;
  List<FarmoraOffer> get buyerOffers =>
      _offers.where((o) => o.buyerId == _currentUserId).toList();
  List<FarmoraOffer> get farmerOffers =>
      _offers.where((o) => o.farmerId == _currentUserId).toList();
  int get pendingOffersCount => _offers
      .where((o) => o.status == 'pending' || o.status == 'countered')
      .length;
  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.read).length;
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
      final matchesMin =
          minPrice == null || p.effectivePricePerUnit >= minPrice!;
      final matchesMax =
          maxPrice == null || p.effectivePricePerUnit <= maxPrice!;
      return matchesSearch && matchesCategory && matchesMin && matchesMax;
    }).toList();
    switch (sortOrder) {
      case 'priceAsc':
        list.sort((a, b) =>
            a.effectivePricePerUnit.compareTo(b.effectivePricePerUnit));
        break;
      case 'priceDesc':
        list.sort((a, b) =>
            b.effectivePricePerUnit.compareTo(a.effectivePricePerUnit));
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
  bool get isOrdersLoading => _ordersLoading;

  // ── Cart (Buyer) ─────────────────────────────────────────
  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get cartItemCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal => _cartItems.fold(
      0.0,
      (sum, item) =>
          sum + (item.product.effectivePricePerUnit * item.quantity));

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
  String? _checkoutAttemptFingerprint;
  String? _checkoutAttemptKey;
  DateTime? _lastOrderAt;

  double get cartSubtotal => cartTotal;
  double get cartDeliveryFee =>
      _cartItems.isEmpty ? 0.0 : defaultDeliveryFeeLkr;
  double get cartGrandTotal => cartSubtotal + cartDeliveryFee;

  String deliveryAddressDraft = '';
  String paymentMethodDraft = PaymentMethod.cod;
  String? _lastOrderError;
  String? get lastOrderError => _lastOrderError;

  void setPaymentMethodDraft(String method) {
    if (paymentMethodDraft == method) return;
    paymentMethodDraft = method;
    notifyListeners();
  }

  Future<bool> placeOrder({
    String? deliveryAddress,
    String? transporterId,
    String? paymentMethod,
  }) async {
    if (_currentUserId.isEmpty || _cartItems.isEmpty || _placingOrder) {
      return false;
    }
    if (transporterId == null || transporterId.isEmpty) return false;
    final method = paymentMethod ?? paymentMethodDraft;
    final address = (deliveryAddress ?? deliveryAddressDraft).trim();
    if (address.length < 5) return false;
    // Idempotency: same cart snapshot within 30s is treated as a repeated tap.
    final key =
        _cartItems.map((c) => '${c.product.id}:${c.quantity}').join('|');
    final fingerprint = '$key|$address|$method';
    if (_checkoutAttemptFingerprint != fingerprint) {
      final random = Random.secure();
      _checkoutAttemptFingerprint = fingerprint;
      _checkoutAttemptKey = List.generate(
        4,
        (_) => random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0'),
      ).join();
    }
    if (_lastOrderKey == fingerprint &&
        _lastOrderAt != null &&
        DateTime.now().difference(_lastOrderAt!).inSeconds < 30) {
      return false;
    }
    _placingOrder = true;
    _lastOrderError = null;
    notifyListeners();
    try {
      // The server owns order/job IDs, stock validation, and persistence. The
      // Firestore subscriptions update the UI after each successful write.
      for (final item in _cartItems) {
        await _firestoreService.createSecureOrder(
          productId: item.product.id,
          quantity: item.quantity,
          deliveryFeeMinor: (cartDeliveryFee * 100).round(),
          transporterId: transporterId,
          deliveryAddress: address,
          idempotencyKey: '${_checkoutAttemptKey!}_${item.product.id}',
          paymentMethod: method,
        );
      }

      _lastOrderKey = fingerprint;
      _lastOrderAt = DateTime.now();
      _cartItems.clear();
      _checkoutAttemptFingerprint = null;
      _checkoutAttemptKey = null;
      paymentMethodDraft = PaymentMethod.cod;
      _recalculateStats();
      notifyListeners();
      return true;
    } catch (e) {
      _lastOrderError = _orderErrorMessage(e);
      return false;
    } finally {
      _placingOrder = false;
      notifyListeners();
    }
  }

  /// Localized reason for a failed checkout. Spark-mode errors already carry
  /// a localized message ([AppException]); the createOrder Cloud Function
  /// returns English text, so its known cases are mapped here.
  String _orderErrorMessage(Object e) {
    // userMessage also logs/reports the technical error.
    final generic = userMessage(e, action: 'place the order');
    if (e is FirebaseFunctionsException) {
      final l = L10n.current;
      final msg = (e.message ?? '').toLowerCase();
      if (msg.contains('product is unavailable') || msg.contains('stock')) {
        return l.svcProductNotFound;
      }
      if (msg.contains('bank deposit')) return l.svcFarmerNoBankDeposit;
    }
    return generic;
  }

  // Actions
  Future<void> signOut() async {
    signedIn = false;
    _currentUserId = '';
    _profileLoaded = false;
    isVerified = false;
    disposeFirestoreSubscriptions();
    _deviceTokenSub?.cancel();
    _deviceTokenSub = null;
    // Stop any live location broadcast — privacy requires it.
    DeliveryLocationService.instance.stopAll();
    UserLocationService.instance.stopSharing();
    await _authService.signOut();
    notifyListeners();
  }

  void setRole(Role r) {
    // A signed-in account's role is owned by its Firestore profile.
    if (_currentUserId.isNotEmpty) return;
    role = r;
    _recalculateStats();
    notifyListeners();
  }

  /// The user picked a language: the app switches immediately and the
  /// choice is saved on the device. When signed in it is also saved on the
  /// profile; that write is awaited and rethrows on failure so the caller
  /// can tell the user (the app stays in the new language either way).
  Future<void> setLanguage(String value) async {
    language = value;
    final code = languageCode;
    await LanguagePrefs.save(code);
    final writer = debugProfileLanguageWriter;
    if (writer != null) {
      await writer(code);
    } else if (_currentUserId.isNotEmpty) {
      await _firestoreService.updateUserLanguage(code);
    }
  }

  /// Tests only: puts [p] in the local catalogue without touching Firestore.
  /// Real products are created through `createSecureProduct`.
  @visibleForTesting
  void addProduct(Product p) {
    _products.removeWhere((item) => item.id == p.id);
    _products.insert(0, p);
    notifyListeners();
  }

  /// Tests only: stands in for a signed-in user's profile write in
  /// [setLanguage] (e.g. to simulate a failure).
  @visibleForTesting
  Future<void> Function(String code)? debugProfileLanguageWriter;

  /// Profile language wins over the device choice; a profile without one
  /// gets the device choice.
  Future<void> _syncLanguageWithProfile(Map<String, dynamic> profile) async {
    final raw = (profile['languageCode'] ?? profile['language'])?.toString();
    if (AppLanguage.isKnown(raw)) {
      language = raw!;
      await LanguagePrefs.save(languageCode);
      return;
    }
    try {
      await _firestoreService.updateUserLanguage(languageCode);
    } catch (e) {
      debugPrint('Saving language on the profile failed: $e');
    }
  }

  /// Update the signed-in user's profile on Firestore, then locally.
  /// Falls back to local-only updates when not authenticated. Throws if the
  /// Firestore write fails so the caller can show an error.
  Future<void> updateProfile({
    String? name,
    String? newDistrict,
    String? newCountry,
    String? photoUrl,
    String? farmName,
    String? farmSize,
    List<String>? mainCrops,
  }) async {
    String? clean(String? v) =>
        (v != null && v.trim().isNotEmpty) ? v.trim() : null;
    final cleanName = clean(name);
    final cleanDistrict = clean(newDistrict);
    final cleanCountry = clean(newCountry);
    final cleanCrops =
        mainCrops?.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();

    if (_currentUserId.isNotEmpty) {
      await _firestoreService.updateUserProfile(
        name: cleanName,
        district: cleanDistrict,
        country: cleanCountry,
        photoUrl: photoUrl,
        farmName: farmName?.trim(),
        farmSize: farmSize?.trim(),
        mainCrops: cleanCrops,
      );
    }

    if (cleanName != null) displayName = cleanName;
    if (cleanCountry != null) country = cleanCountry;
    if (cleanDistrict != null) district = cleanDistrict;
    if (photoUrl != null) this.photoUrl = photoUrl;
    if (farmName != null) this.farmName = farmName.trim();
    if (farmSize != null) this.farmSize = farmSize.trim();
    if (cleanCrops != null) this.mainCrops = cleanCrops;
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

  Future<void> updateProduct(Product p) async {
    if (_currentUserId.isEmpty) throw StateError('Authentication required.');
    await _firestoreService.updateProduct(p.id, p.toMap());
    final index = _products.indexWhere((prod) => prod.id == p.id);
    if (index != -1) {
      _products[index] = p;
      notifyListeners();
    }
  }

  Future<void> toggleProductStock(String id) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final current = _products[index];
      final newStatus = current.status == 'Active' ? 'Empty' : 'Active';
      await _firestoreService.updateProduct(id, {'status': newStatus});
      _products[index] = current.copyWith(status: newStatus);
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    await _firestoreService.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
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
    // Harvest-trust flow: the product video is auto-deleted after delivery.
    _cleanupVideoForDeliveredOrder(orderId);
  }

  /// Fire-and-forget cleanup of the harvest video linked to a delivered
  /// order. Resolves the product id from the order (or by product name when
  /// the order predates the productId field).
  Future<void> _cleanupVideoForDeliveredOrder(String orderId) async {
    final orderIdx = _orders.indexWhere((o) => o.id == orderId);
    if (orderIdx == -1 || _currentUserId.isEmpty) return;
    final order = _orders[orderIdx];

    String productId = order.productId;
    if (productId.isEmpty && order.productName.isNotEmpty) {
      productId = _products
              .where((p) =>
                  p.name == order.productName &&
                  (order.farmerId.isEmpty || p.farmerId == order.farmerId))
              .map((p) => p.id)
              .firstOrNull ??
          '';
    }
    if (productId.isEmpty) return;

    final productIdx = _products.indexWhere((p) => p.id == productId);
    final videoPath = productIdx != -1 ? _products[productIdx].videoPath : null;
    final videoUrl = productIdx != -1 ? _products[productIdx].videoUrl : null;
    if ((videoPath == null || videoPath.isEmpty) &&
        (videoUrl == null || videoUrl.isEmpty)) {
      return; // No video linked — nothing to clean up.
    }

    try {
      await deliverOrderAndCleanupVideo(
        orderId: orderId,
        productId: productId,
        videoStoragePath: videoPath,
        videoDownloadUrl: videoUrl,
      );
      if (productIdx != -1) {
        _products[productIdx] = _products[productIdx].copyWith(
          videoPath: '',
          videoUrl: '',
          harvestStatus: HarvestStatus.delivered,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Harvest video cleanup note: $e');
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

  // ── Payments (COD / Bank Deposit) ───────────────────────

  Future<void> saveBankDetails(BankDetails details) async {
    if (_currentUserId.isNotEmpty) {
      await _paymentService.saveBankDetails(details);
    }
    _myBankDetails = details;
    notifyListeners();
  }

  Future<BankDetails> bankDetailsForFarmer(String farmerId) async {
    if (_currentUserId.isEmpty || farmerId.isEmpty) return BankDetails.empty;
    return _paymentService.getBankDetails(farmerId);
  }

  /// Bank Deposit is offered only when every farmer in the cart has an account.
  Future<bool> cartSupportsBankDeposit() async {
    if (_cartItems.isEmpty || _currentUserId.isEmpty) return false;
    final farmerIds = _cartItems.map((c) => c.product.farmerId).toSet();
    for (final farmerId in farmerIds) {
      if (!(await bankDetailsForFarmer(farmerId)).isComplete) return false;
    }
    return true;
  }

  Future<void> markCashReceived(String orderId) => _applyPayment(
        orderId,
        remote: () => _paymentService.markCashReceived(orderId),
        allowed: (o) => o.canMarkCashReceived,
        local: (o) => o.copyWith(paymentStatus: 'paid', paidAt: DateTime.now()),
      );

  Future<void> confirmBankPayment(String orderId) => _applyPayment(
        orderId,
        remote: () => _paymentService.confirmBankPayment(orderId),
        allowed: (o) => o.canReviewProof,
        local: (o) => o.copyWith(paymentStatus: 'paid', paidAt: DateTime.now()),
      );

  Future<void> rejectBankPayment(String orderId, String reason) =>
      _applyPayment(
        orderId,
        remote: () => _paymentService.rejectBankPayment(orderId, reason),
        allowed: (o) => o.canReviewProof,
        local: (o) => o.copyWith(
            paymentStatus: 'rejected', rejectionReason: reason.trim()),
      );

  /// Uploads a bank-deposit slip photo for [orderId] to Storage.
  Future<kajana_service.StoredImage> uploadPaymentSlip({
    required String orderId,
    required PickedImage image,
    void Function(double progress)? onProgress,
  }) =>
      _firestoreService.uploadPaymentSlip(
        orderId: orderId,
        image: image,
        onProgress: onProgress,
      );

  /// Links an uploaded slip to the order so the farmer can review it.
  Future<void> recordPaymentProof(
          String orderId, kajana_service.StoredImage slip) =>
      _paymentService.submitPaymentProof(
        orderId: orderId,
        proofImageUrl: slip.url,
        proofImagePath: slip.path,
      );

  /// Buyer: upload a deposit slip, attach it to the order, and share it in
  /// the order chat. The order update is the source of truth; if only the
  /// chat post fails the receipt still counts and [chatError] is returned.
  Future<String?> submitPaymentSlip({
    required FarmoraOrder order,
    required PickedImage image,
    void Function(double progress)? onProgress,
  }) async {
    if (!order.canSubmitProof) {
      throw UserStateError(L10n.current.stateReceiptNotNeeded);
    }
    if (_currentUserId.isEmpty) {
      throw UserStateError(L10n.current.stateSignInToUploadReceipt);
    }
    final slip = await uploadPaymentSlip(
      orderId: order.id,
      image: image,
      onProgress: onProgress,
    );
    await recordPaymentProof(order.id, slip);
    if (order.farmerId.isEmpty) return null;
    try {
      final conversation = await _firestoreService.ensureConversation(
        orderId: order.id,
        peerId: order.farmerId,
      );
      await _firestoreService.sendChatMessage(
        conversation: conversation,
        recipientId: order.farmerId,
        attachment: ChatAttachment(
          url: slip.url,
          path: slip.path,
          kind: ChatAttachmentKind.paymentProof,
        ),
      );
      return null;
    } catch (e, st) {
      return userMessage(e, action: 'share the receipt in chat', stack: st);
    }
  }

  /// Signed in: write to Firestore and let the orders stream refresh the UI.
  /// Demo mode: apply the same transition locally.
  Future<void> _applyPayment(
    String orderId, {
    required Future<void> Function() remote,
    required bool Function(FarmoraOrder order) allowed,
    required FarmoraOrder Function(FarmoraOrder order) local,
  }) async {
    if (_currentUserId.isNotEmpty) {
      await remote();
      return;
    }
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1 || !allowed(_orders[idx])) {
      throw UserStateError(L10n.current.statePaymentActionUnavailable);
    }
    _orders[idx] = local(_orders[idx]);
    _recalculateStats();
    notifyListeners();
  }

  // ── Offers & Negotiation CRUD ───────────────────────────
  Future<void> makeOffer({
    required String productId,
    required String productName,
    required String farmerId,
    required int quantity,
    required double price,
  }) async {
    if (_currentUserId.isEmpty) throw StateError('Authentication required.');
    final offerId = await _firestoreService.createOffer(
      productId: productId,
      proposedQuantity: quantity,
      proposedPrice: price,
    );
    final newOffer = FarmoraOffer(
      id: offerId,
      productId: productId,
      productName: productName,
      buyerId: _currentUserId,
      farmerId: farmerId,
      proposedQuantity: quantity,
      proposedPrice: price,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    _offers.insert(0, newOffer);
    notifyListeners();
  }

  Future<void> acceptOffer(String offerId) async {
    if (_currentUserId.isEmpty) throw StateError('Authentication required.');
    await _firestoreService.acceptOffer(
      offerId: offerId,
      deliveryFeeMinor: (defaultDeliveryFeeLkr * 100).round(),
      deliveryAddress: role == Role.buyer ? deliveryAddressDraft.trim() : null,
    );
    final idx = _offers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      _offers[idx] = _offers[idx].copyWith(
        status: 'accepted',
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> rejectOffer(String offerId) async {
    if (_currentUserId.isEmpty) throw StateError('Authentication required.');
    await _firestoreService.rejectOffer(offerId);
    final idx = _offers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      _offers[idx] =
          _offers[idx].copyWith(status: 'rejected', updatedAt: DateTime.now());
      notifyListeners();
    }
  }

  Future<void> counterOffer(String offerId, double counterPrice) async {
    if (_currentUserId.isEmpty) throw StateError('Authentication required.');
    await _firestoreService.counterOffer(
      offerId: offerId,
      counterPrice: counterPrice,
    );
    final idx = _offers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      _offers[idx] = _offers[idx].copyWith(
        status: 'countered',
        proposedPrice: counterPrice,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> cancelOffer(String offerId) async {
    await rejectOffer(offerId);
  }

  Future<void> acceptJob(String jobId) async {
    if (_currentUserId.isEmpty) {
      throw StateError('Authentication required.');
    }
    await _firestoreService.transitionTransport(jobId, 'accepted');
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

  Future<void> requestTransportForOrder(String orderId,
      {int? deliveryFeeMinor}) async {
    if (_currentUserId.isEmpty) throw StateError('Authentication required.');
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
    final idx = _users.indexWhere((u) => (u['uid'] ?? u['id']) == userId);
    if (idx != -1) {
      final updated = Map<String, dynamic>.from(_users[idx]);
      updated['isSuspended'] = suspended;
      _users[idx] = updated;
      notifyListeners();
    }
    try {
      await _firestoreService.setUserSuspended(
          userId: userId, suspended: suspended);
    } catch (e) {
      debugPrint('Firebase suspend user notice: $e');
    }
  }

  Future<void> releaseEscrow(String orderId) async {
    await _firestoreService.releaseEscrow(orderId: orderId);
  }

  Future<Map<String, dynamic>> exportUserData() async {
    return _firestoreService.exportUserData();
  }

  Future<void> deleteAccount() async {
    await _firestoreService.deleteAccount();
    await signOut();
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
        signedIn = false;
        isVerified = false;
        notifyListeners();
        return;
      }

      final roleStr = profile['role'] as String?;
      final accountRole =
          Role.values.where((r) => r.name == roleStr).firstOrNull;
      if (accountRole == null) {
        await FirebaseAuth.instance.signOut();
        _currentUserId = '';
        signedIn = false;
        isVerified = false;
        notifyListeners();
        return;
      }
      role = accountRole;
      await _syncLanguageWithProfile(profile);
      _applyProfileFields(profile);
      _profileLoaded = true;
      notifyListeners();
      _registerDeviceToken();
      _loadPlatformSettings();
    } catch (_) {
      await FirebaseAuth.instance.signOut();
      _currentUserId = '';
      signedIn = false;
      isVerified = false;
      notifyListeners();
      return;
    }
    final isAdmin = role == Role.admin;

    // Subscribe to products stream
    _productsSub?.cancel();
    // Runtime catalog data is owned by Firestore.
    _products.clear();
    notifyListeners();
    final productsStream = role == Role.farmer
        ? _firestoreService.productsByFarmerStream(uid)
        : _firestoreService.productsStream();
    _productsSub = productsStream.listen(
      (firestoreProducts) {
        _products.clear();
        _products.addAll(firestoreProducts);
        notifyListeners();
      },
      onError: (e) {
        _products.clear();
        debugPrint('Firestore products stream error: $e');
        notifyListeners();
      },
    );

    // Subscribe to users stream
    _usersSub?.cancel();
    if (isAdmin) {
      _usersSub = _firestoreService.usersStream().listen(
        (firestoreUsers) {
          _users.clear();
          _users.addAll(firestoreUsers);
          notifyListeners();
        },
        onError: (e) => debugPrint('Firestore users stream error: $e'),
      );
    }

    // Subscribe to orders stream
    _ordersSub?.cancel();
    _ordersLoading = true;
    notifyListeners();
    final ordersStream = switch (role) {
      Role.admin => _firestoreService.ordersStream(),
      Role.farmer => _firestoreService.ordersByFarmerStream(uid),
      Role.buyer => _firestoreService.ordersByBuyerStream(uid),
      Role.transporter => _firestoreService.ordersByTransporterStream(uid),
    };
    _ordersSub = ordersStream.listen(
      (firestoreOrders) {
        _orders.clear();
        _orders.addAll(firestoreOrders);
        _recalculateStats();
        _ordersLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _ordersLoading = false;
        debugPrint('Firestore orders stream error: $e');
        notifyListeners();
      },
    );

    // Subscribe to transport jobs stream
    _jobsSub?.cancel();
    final jobsStream = switch (role) {
      Role.admin => _firestoreService.jobsStream(),
      Role.transporter => _firestoreService.jobsForTransporterStream(uid),
      Role.farmer => _firestoreService.jobsByFarmerStream(uid),
      _ => const Stream<List<TransportJob>>.empty(),
    };
    _jobsSub = jobsStream.listen(
      (firestoreJobs) {
        _jobs.clear();
        _jobs.addAll(firestoreJobs);
        notifyListeners();
      },
      onError: (e) => debugPrint('Firestore jobs stream error: $e'),
    );

    // Subscribe to verification docs (admin sees pending/all; others see own)
    _verificationSub?.cancel();
    final verificationStream = isAdmin
        ? _firestoreService.pendingVerificationDocsStream(pendingOnly: false)
        : _firestoreService.verificationDocsStream(uid);
    _verificationSub = verificationStream.listen(
      (firestoreDocs) {
        _verificationDocs.clear();
        _verificationDocs.addAll(firestoreDocs);
        notifyListeners();
      },
      onError: (e) => debugPrint('Firestore verification stream error: $e'),
    );

    // Subscribe to notifications stream
    _notificationsSub?.cancel();
    _notificationsSub = _firestoreService.notificationsStream(uid).listen(
      (notifs) {
        _notifications.clear();
        _notifications.addAll(notifs);
        notifyListeners();
      },
      onError: (e) => debugPrint('Firestore notifications stream error: $e'),
    );

    // Subscribe to offers stream
    _offersSub?.cancel();
    final offersStream = role == Role.farmer
        ? _firestoreService.offersByFarmerStream(uid)
        : _firestoreService.offersByBuyerStream(uid);
    _offersSub = offersStream.listen(
      (firestoreOffers) {
        _offers.clear();
        _offers.addAll(firestoreOffers);
        notifyListeners();
      },
      onError: (e) => debugPrint('Firestore offers stream error: $e'),
    );

    // ── Admin-scoped live data: reviews, audit trail, settlements, market prices ──
    if (role == Role.admin) {
      _reviewsSub?.cancel();
      _reviewsSub = _firestoreService.adminReviewsStream().listen(
        (firestoreReviews) {
          _reviews
            ..clear()
            ..addAll(firestoreReviews);
          notifyListeners();
        },
        onError: (e) => debugPrint('Firestore reviews stream error: $e'),
      );

      _auditLogsSub?.cancel();
      _auditLogsSub = _firestoreService.auditLogsStream().listen(
        (firestoreLogs) {
          if (firestoreLogs.isEmpty) return;
          _auditLogs
            ..clear()
            ..addAll(firestoreLogs);
          notifyListeners();
        },
        onError: (e) => debugPrint('Firestore audit stream error: $e'),
      );

      _settlementsSub?.cancel();
      _settlementsSub = _firestoreService.settlementsStream().listen(
        (firestoreSettlements) {
          if (firestoreSettlements.isEmpty) return;
          _settlements
            ..clear()
            ..addAll(firestoreSettlements);
          notifyListeners();
        },
        onError: (e) => debugPrint('Firestore settlements stream error: $e'),
      );

      _marketPricesSub?.cancel();
      _marketPricesSub = _firestoreService.marketPricesStream().listen(
        (firestorePrices) {
          if (firestorePrices.isEmpty) return;
          _marketPrices
            ..clear()
            ..addAll(firestorePrices);
          notifyListeners();
        },
        onError: (e) => debugPrint('Firestore market prices stream error: $e'),
      );
    }

    _bankDetailsSub?.cancel();
    if (role == Role.farmer) {
      _bankDetailsSub = _paymentService.bankDetailsStream(uid).listen(
        (details) {
          _myBankDetails = details;
          notifyListeners();
        },
        onError: (e) => debugPrint('Firestore bank details stream error: $e'),
      );
    }
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
    _reviewsSub?.cancel();
    _auditLogsSub?.cancel();
    _settlementsSub?.cancel();
    _marketPricesSub?.cancel();
    _bankDetailsSub?.cancel();
    _myBankDetails = BankDetails.empty;
  }

  Future<void> sendInAppNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String? referenceId,
  }) async {
    try {
      await _firestoreService.sendInAppNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        referenceId: referenceId,
      );
    } catch (e) {
      debugPrint('sendInAppNotification error: $e');
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await _firestoreService.markNotificationRead(id);
    } catch (e) {
      debugPrint('markNotificationRead error: $e');
    }
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

  /// Farmer whose earnings are shown: the signed-in farmer, or the demo farmer.
  /// Admins and other roles see totals across all loaded orders.
  String? get _earningsFarmerId => role != Role.farmer
      ? null
      : (_currentUserId.isNotEmpty ? _currentUserId : 'farmer_demo_1');

  EarningsCalculator get earnings =>
      EarningsCalculator(_orders, farmerId: _earningsFarmerId);

  void _recalculateStats() {
    final calc = earnings;
    _totalEarnings = calc.totalEarnings;
    _thisMonth = calc.thisMonth;
    _thisWeek = calc.thisWeek;
    _pendingPayments = calc.pendingPayments;

    _transactions
      ..clear()
      ..addAll(calc.paidOrders.map((order) {
        final date = EarningsCalculator.earnedAt(order);
        return EarningsTransaction(
          id: 'tx-${order.id}',
          orderNumber:
              order.orderNumber.isNotEmpty ? order.orderNumber : order.id,
          date: date != null
              ? DateFormat('d MMM yyyy').format(date)
              : order.timestamp,
          amount: order.total,
        );
      }));

    final bars = calc.monthly(months: 6);
    final maxAmount =
        bars.fold<double>(0, (m, b) => b.amount > m ? b.amount : m);
    _monthlyBars
      ..clear()
      ..addAll(bars.map((b) => MonthlyBarData(
            month: DateFormat('MMM').format(b.month),
            amount: b.amount,
            heightRatio: maxAmount > 0 ? b.amount / maxAmount : 0,
            isHighlighted: b == bars.last,
          )));
  }

  /// One-shot re-read of the farmer's orders (pull-to-refresh). Throws on
  /// failure so the caller can show the error.
  Future<void> refreshOrders() async {
    if (_currentUserId.isEmpty || role != Role.farmer) {
      _recalculateStats();
      notifyListeners();
      return;
    }
    final fresh =
        await _firestoreService.ordersByFarmerStream(_currentUserId).first;
    _orders
      ..clear()
      ..addAll(fresh);
    _recalculateStats();
    notifyListeners();
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
      }
      final maintenance = settings['maintenanceMode'];
      if (maintenance is bool) {
        _maintenanceMode = maintenance;
      }
      final notice = settings['maintenanceNotice'];
      if (notice is String && notice.isNotEmpty) {
        _maintenanceNotice = notice;
      }
      final feeBps = (settings['platformFeeBps'] as num?)?.toInt();
      if (feeBps != null && feeBps >= 0) {
        _commissionRate = feeBps / 100.0;
      }
      final escrowHours = (settings['escrowReleaseHours'] as num?)?.toInt();
      if (escrowHours != null && escrowHours > 0) {
        _escrowReleaseHours = escrowHours;
      }
      final minVersion = settings['minAppVersion'];
      if (minVersion is String && minVersion.isNotEmpty) {
        _minAppVersion = minVersion;
      }
      notifyListeners();
    } catch (_) {
      // Keep last known / defaults.
    }
  }

  Future<Map<String, dynamic>?> _loadUserProfile(String uid) async {
    return await _authService.loadUserProfile(uid);
  }

  /// Copies the editable/display fields of a users/{uid} document into state.
  void _applyProfileFields(Map<String, dynamic> profile) {
    country = (profile['country'] ?? 'Sri Lanka').toString();
    district = (profile['district'] ?? '').toString();
    displayName = (profile['name'] ?? profile['displayName'] ?? '').toString();
    photoUrl = (profile['photoUrl'] ?? '').toString();
    phone = (profile['phone'] ?? '').toString();
    isVerified = profile['isVerified'] == true;
    vehicleType = (profile['vehicleType'] ?? '').toString();
    capacityKg = (profile['capacityKg'] as num?)?.toInt() ?? 0;
    serviceDistricts = (profile['serviceDistricts'] as List? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    farmName = (profile['farmName'] ?? '').toString();
    farmSize = (profile['farmSize'] ?? '').toString();
    mainCrops = (profile['mainCrops'] as List? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final created = profile['createdAt'];
    memberSince = switch (created) {
      Timestamp t => t.toDate(),
      DateTime d => d,
      String s => DateTime.tryParse(s),
      _ => memberSince,
    };
  }

  /// Re-reads the signed-in user's profile (pull-to-refresh). Throws when the
  /// profile cannot be loaded so the caller can show an error.
  Future<void> refreshProfile() async {
    if (_currentUserId.isEmpty) return;
    final profile = await _loadUserProfile(_currentUserId);
    if (profile == null) {
      throw AppException(L10n.current.stateProfileNotFound);
    }
    await _syncLanguageWithProfile(profile);
    _applyProfileFields(profile);
    notifyListeners();
  }

  /// Uploads a new profile photo (users/{uid}/…) and updates the profile.
  Future<void> changeProfilePhoto(PickedImage image) async {
    if (_currentUserId.isEmpty) {
      throw AppException(L10n.current.stateSignInToChangePhoto);
    }
    final url = await _firestoreService.uploadProfilePhoto(
      bytes: image.bytes,
      fileName: image.name,
      contentType: image.contentType,
    );
    photoUrl = url;
    notifyListeners();
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

  // ── Admin Platform & Market Management ──────────────────────────────
  void updateMarketPrice(
    String id, {
    required double minPrice,
    required double maxPrice,
    required String trend,
  }) {
    final idx = _marketPrices.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final existing = _marketPrices[idx];
      final updated = existing.copyWith(
        minPricePerKg: minPrice,
        maxPricePerKg: maxPrice,
        averagePricePerKg: (minPrice + maxPrice) / 2,
        trend: trend,
        updatedAt: DateTime.now(),
      );
      _marketPrices[idx] = updated;
      notifyListeners();
      _persistToFirestore(() => _firestoreService.upsertMarketPrice(updated));
      logAuditEvent(
        actionType: 'MARKET_PRICE_UPDATE',
        targetEntity: 'MarketPrice',
        targetId: id,
        details:
            'Updated ${existing.cropName}: LKR $minPrice–$maxPrice/kg, trend $trend.',
        severity: 'info',
      );
    }
  }

  void addMarketPrice(MarketPriceIndex item) {
    _marketPrices.insert(0, item);
    notifyListeners();
    _persistToFirestore(() => _firestoreService.upsertMarketPrice(item));
    logAuditEvent(
      actionType: 'MARKET_PRICE_CREATE',
      targetEntity: 'MarketPrice',
      targetId: item.id,
      details:
          'Added benchmark ${item.cropName} (${item.district}): LKR ${item.minPricePerKg}–${item.maxPricePerKg}/kg.',
      severity: 'info',
    );
  }

  /// Remove a market price benchmark locally and in Firestore.
  void removeMarketPrice(String priceId) {
    _marketPrices.removeWhere((p) => p.id == priceId);
    notifyListeners();
    _persistToFirestore(() => _firestoreService.deleteMarketPrice(priceId));
    logAuditEvent(
      actionType: 'MARKET_PRICE_DELETE',
      targetEntity: 'MarketPrice',
      targetId: priceId,
      details: 'Removed market price benchmark.',
      severity: 'info',
    );
  }

  MarketPriceIndex? getMarketPriceForCrop(String cropName) {
    final clean = cropName.toLowerCase().trim();
    for (final p in _marketPrices) {
      if (clean.contains(p.cropName.toLowerCase()) ||
          p.cropName.toLowerCase().contains(clean)) {
        return p;
      }
    }
    return null;
  }

  Future<void> resolveDisputeArbitration({
    required String orderId,
    required String resolution,
    required String adminNotes,
    double refundPercent = 100.0,
  }) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final o = _orders[idx];
      String newStatus = o.status;
      String newPaymentStatus = o.paymentStatus;

      if (resolution == 'refund_buyer') {
        newStatus = 'cancelled';
        newPaymentStatus = 'refunded';
      } else if (resolution == 'release_farmer') {
        newStatus = 'completed';
        newPaymentStatus = 'released';
      } else {
        newStatus = 'completed';
        newPaymentStatus = 'settled_split';
      }

      _orders[idx] = o.copyWith(
        status: newStatus,
        paymentStatus: newPaymentStatus,
      );

      _transactions.add(EarningsTransaction(
        id: 'tx-arb-${DateTime.now().millisecondsSinceEpoch}',
        orderNumber: o.orderNumber,
        date: DateTime.now().toIso8601String().substring(0, 10),
        amount: o.total,
      ));

      // Stored notification text cannot carry parameters (see firestore.rules
      // for notifications), so it is written in the admin's app language.
      final l = L10n.current;
      final resolutionLabel = switch (resolution) {
        'refund_buyer' => l.stateResolutionRefundBuyer,
        'release_farmer' => l.stateResolutionReleaseFarmer,
        'split_settlement' => l.stateResolutionSplit,
        _ => resolution,
      };
      final disputeBody =
          l.stateDisputeResolvedBody(resolutionLabel, adminNotes);
      if (o.buyerId.isNotEmpty) {
        sendInAppNotification(
          userId: o.buyerId,
          title: l.stateDisputeResolvedTitle(o.orderNumber),
          body: disputeBody,
          type: 'order',
          referenceId: o.id,
        );
      }
      if (o.farmerId.isNotEmpty) {
        sendInAppNotification(
          userId: o.farmerId,
          title: l.stateDisputeSettledTitle(o.orderNumber),
          body: disputeBody,
          type: 'order',
          referenceId: o.id,
        );
      }

      try {
        await _firestoreService.resolveDispute(
          orderId: orderId,
          resolution: resolution,
          adminNotes: adminNotes,
          refundPercent: refundPercent,
        );
      } catch (e) {
        debugPrint('Firestore dispute resolve error: $e');
      }

      logAuditEvent(
        actionType: 'DISPUTE_ARBITRATION',
        targetEntity: 'Order',
        targetId: orderId,
        details:
            'Arbitrated dispute with outcome "$resolution". Notes: $adminNotes',
        severity: 'critical',
      );

      notifyListeners();
    }
  }

  Future<void> broadcastPlatformAdvisory({
    required String title,
    required String message,
    required String targetRole,
    String priority = 'normal',
  }) async {
    for (final u in _users) {
      final uRole = (u['role'] ?? '').toString().toLowerCase();
      final uid = (u['uid'] ?? u['id'] ?? '').toString();
      if (uid.isNotEmpty && (targetRole == 'all' || uRole == targetRole)) {
        sendInAppNotification(
          userId: uid,
          title: '📢 $title',
          body: message,
          type: 'general',
        );
      }
    }

    _notifications.insert(
      0,
      FarmoraNotification(
        id: 'advisory-${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUserId.isNotEmpty ? _currentUserId : 'admin',
        title: '📢 $title',
        body: message,
        type: 'general',
        read: false,
        createdAt: DateTime.now(),
      ),
    );

    try {
      await _firestoreService.publishAdvisory(
        title: title,
        message: message,
        targetRole: targetRole,
        priority: priority,
      );
    } catch (e) {
      debugPrint('Firestore broadcast advisory error: $e');
    }

    notifyListeners();
  }

  // ── Admin: Review & Feedback Moderation ───────────────────────
  Future<void> moderateReview({
    required String reviewId,
    required ReviewStatus status,
    String? note,
  }) async {
    final idx = _reviews.indexWhere((r) => r.id == reviewId);
    if (idx != -1) {
      _reviews[idx] = _reviews[idx].copyWith(
        status: status,
        moderatedAt: DateTime.now(),
        moderationNote: note,
      );
      notifyListeners();
    }
    try {
      await _firestoreService.moderateReview(
        reviewId: reviewId,
        status: status.name,
        note: note,
      );
    } catch (e) {
      debugPrint('Firebase review moderation notice: $e');
    }
    logAuditEvent(
      actionType: 'REVIEW_MODERATION',
      targetEntity: 'Review',
      targetId: reviewId,
      details: 'Review status set to ${status.name}. Note: ${note ?? "None"}',
      severity: status == ReviewStatus.rejected ? 'warning' : 'info',
    );
  }

  Future<void> deleteReview({required String reviewId}) async {
    _reviews.removeWhere((r) => r.id == reviewId);
    notifyListeners();
    try {
      await _firestoreService.deleteReview(reviewId: reviewId);
    } catch (e) {
      debugPrint('Firebase delete review notice: $e');
    }
    logAuditEvent(
      actionType: 'REVIEW_DELETE',
      targetEntity: 'Review',
      targetId: reviewId,
      details: 'Permanently deleted user review.',
      severity: 'warning',
    );
  }

  void addReview(Review review) {
    _reviews.insert(0, review);
    notifyListeners();
  }

  // ── Admin: User Management Actions ────────────────────────────
  Future<void> setUserVerified({
    required String userId,
    required bool verified,
  }) async {
    final idx = _users.indexWhere((u) => (u['uid'] ?? u['id']) == userId);
    if (idx != -1) {
      final updated = Map<String, dynamic>.from(_users[idx]);
      updated['isVerified'] = verified;
      _users[idx] = updated;
      notifyListeners();
    }
    try {
      await _firestoreService.setUserVerified(
          userId: userId, verified: verified);
    } catch (e) {
      debugPrint('Firebase verify user notice: $e');
    }
    logAuditEvent(
      actionType: 'USER_VERIFY',
      targetEntity: 'User',
      targetId: userId,
      details: verified
          ? 'Granted verified trust badge'
          : 'Revoked verified trust badge',
      severity: 'info',
    );
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    final idx = _users.indexWhere((u) => (u['uid'] ?? u['id']) == userId);
    if (idx != -1) {
      final updated = Map<String, dynamic>.from(_users[idx]);
      updated['role'] = role;
      _users[idx] = updated;
      notifyListeners();
    }
    try {
      await _firestoreService.updateUserRole(userId: userId, role: role);
    } catch (e) {
      debugPrint('Firebase update role notice: $e');
    }
    logAuditEvent(
      actionType: 'ROLE_UPDATE',
      targetEntity: 'User',
      targetId: userId,
      details: 'Role changed to "$role"',
      severity: 'warning',
    );
  }

  // ── Admin: Server Maintenance & Platform Config ───────────────

  /// Persist secondary audit/config records without blocking their caller.
  void _persistToFirestore(Future<void> Function() action) {
    try {
      action().catchError((e) => debugPrint('Firestore persist skipped: $e'));
    } catch (e) {
      debugPrint('Firestore persist skipped: $e');
    }
  }

  void setMaintenanceMode({required bool enabled, String? notice}) {
    _maintenanceMode = enabled;
    if (notice != null && notice.trim().isNotEmpty) {
      _maintenanceNotice = notice;
    }
    notifyListeners();
    try {
      _firestoreService.updatePlatformSettings({
        'maintenanceMode': enabled,
        'maintenanceNotice': _maintenanceNotice,
      }).catchError((e) => debugPrint('Settings sync notice: $e'));
    } catch (e) {
      debugPrint('Settings sync notice: $e');
    }
    logAuditEvent(
      actionType: 'MAINTENANCE_TOGGLE',
      targetEntity: 'PlatformSettings',
      targetId: 'maintenanceMode',
      details:
          'Maintenance mode ${enabled ? 'ENABLED' : 'disabled'}. Notice: $_maintenanceNotice',
      severity: enabled ? 'critical' : 'info',
    );
  }

  void setCommissionRate(double rate) {
    _commissionRate = rate.clamp(0.0, 50.0);
    notifyListeners();
    try {
      _firestoreService.updatePlatformSettings({
        'platformFeeBps': (_commissionRate * 100).toInt(),
      }).catchError((e) => debugPrint('Settings sync notice: $e'));
    } catch (e) {
      debugPrint('Settings sync notice: $e');
    }
    logAuditEvent(
      actionType: 'COMMISSION_UPDATE',
      targetEntity: 'PlatformSettings',
      targetId: 'platformFeeBps',
      details:
          'Platform commission set to ${_commissionRate.toStringAsFixed(2)}%.',
      severity: 'warning',
    );
  }

  void setEscrowReleaseHours(int hours) {
    _escrowReleaseHours = hours.clamp(1, 720);
    notifyListeners();
    try {
      _firestoreService.updatePlatformSettings({
        'escrowReleaseHours': _escrowReleaseHours,
      }).catchError((e) => debugPrint('Settings sync notice: $e'));
    } catch (e) {
      debugPrint('Settings sync notice: $e');
    }
    logAuditEvent(
      actionType: 'ESCROW_WINDOW_UPDATE',
      targetEntity: 'PlatformSettings',
      targetId: 'escrowReleaseHours',
      details: 'Escrow auto-release window set to $_escrowReleaseHours hours.',
      severity: 'info',
    );
  }

  void setMinAppVersion(String version) {
    final v = version.trim();
    if (v.isEmpty) return;
    _minAppVersion = v;
    notifyListeners();
    try {
      _firestoreService.updatePlatformSettings({
        'minAppVersion': v,
      }).catchError((e) => debugPrint('Settings sync notice: $e'));
    } catch (e) {
      debugPrint('Settings sync notice: $e');
    }
    logAuditEvent(
      actionType: 'MIN_VERSION_UPDATE',
      targetEntity: 'PlatformSettings',
      targetId: 'minAppVersion',
      details: 'Minimum supported app version set to $v.',
      severity: 'warning',
    );
  }

  void clearLocalCache() {
    logAuditEvent(
      actionType: 'CACHE_PURGE',
      targetEntity: 'System',
      targetId: 'local_cache',
      details: 'Admin triggered local device and client cache purge.',
      severity: 'info',
    );
    notifyListeners();
  }

  // ── Admin: Audit Trail & Compliance ───────────────────────────
  void logAuditEvent({
    required String actionType,
    required String targetEntity,
    required String targetId,
    required String details,
    String severity = 'info',
  }) {
    if (_currentUserId.isEmpty) return;
    final log = AuditLog(
      id: 'aud-${DateTime.now().millisecondsSinceEpoch}',
      actorId: _currentUserId,
      actorName: displayName,
      actorRole: role.name,
      actionType: actionType,
      targetEntity: targetEntity,
      targetId: targetId,
      details: details,
      severity: severity,
      timestamp: DateTime.now(),
    );
    _auditLogs.insert(0, log);
    notifyListeners();
    // Persist append-only audit record (never breaks the triggering action).
    _persistToFirestore(() => _firestoreService.writeAuditLog(log));
  }

  // ── Admin: Treasury & Bank Escrow Settlements ─────────────────
  Future<void> approveSettlement(
    String settlementId, {
    required String transactionReference,
  }) async {
    final reference = transactionReference.trim();
    if (reference.length < 4 || reference.length > 100) {
      throw UserArgumentError(L10n.current.stateSettlementReferenceRequired);
    }
    final idx = _settlements.indexWhere((s) => s.id == settlementId);
    if (idx != -1) {
      final s = _settlements[idx];
      _settlements[idx] = s.copyWith(
        status: 'settled',
        settledAt: DateTime.now(),
        transactionReference: reference,
      );
      notifyListeners();
      _persistToFirestore(() => _firestoreService.updateSettlementStatus(
            settlementId,
            status: 'settled',
            transactionReference: reference,
          ));
      logAuditEvent(
        actionType: 'SETTLEMENT_APPROVED',
        targetEntity: 'Settlement',
        targetId: settlementId,
        details:
            'Disbursed LKR ${s.netAmount.toStringAsFixed(2)} to ${s.recipientName} via ${s.bankName}. Ref: $reference',
        severity: 'info',
      );
    }
  }

  Future<void> holdSettlement(String settlementId, String reason) async {
    final idx = _settlements.indexWhere((s) => s.id == settlementId);
    if (idx != -1) {
      final s = _settlements[idx];
      _settlements[idx] = s.copyWith(
        status: 'on_hold',
        holdReason: reason,
      );
      notifyListeners();
      _persistToFirestore(() => _firestoreService.updateSettlementStatus(
            settlementId,
            status: 'on_hold',
            holdReason: reason,
          ));
      logAuditEvent(
        actionType: 'SETTLEMENT_HOLD',
        targetEntity: 'Settlement',
        targetId: settlementId,
        details:
            'Placed payout on hold for ${s.recipientName}. Reason: $reason',
        severity: 'warning',
      );
    }
  }

  Future<void> retrySettlement(String settlementId) async {
    final idx = _settlements.indexWhere((s) => s.id == settlementId);
    if (idx != -1) {
      _settlements[idx] = _settlements[idx].copyWith(
        status: 'processing',
        clearHoldReason: true,
      );
      notifyListeners();
      _persistToFirestore(() => _firestoreService.updateSettlementStatus(
            settlementId,
            status: 'processing',
            clearHoldReason: true,
          ));
      logAuditEvent(
        actionType: 'SETTLEMENT_RETRY',
        targetEntity: 'Settlement',
        targetId: settlementId,
        details: 'Retried wire transfer batch dispatch.',
        severity: 'info',
      );
    }
  }

  // ── Farmer: Payout / Bank Withdrawal ─────────────────────────
  Future<void> requestFarmerWithdrawal({
    required double amount,
    required String bankName,
    required String accountNumber,
    String payoutMethod = 'CEFT',
  }) async {
    if (_currentUserId.isEmpty) throw StateError('Authentication required.');
    if (amount <= 0 || amount > _totalEarnings) {
      throw UserArgumentError(L10n.current.stateInvalidWithdrawalAmount(
          AppFormat.lkr(_totalEarnings, decimals: 2)));
    }
    final fee = amount * (_commissionRate / 100.0);
    final net = amount - fee;
    final settlementId = 'STL-${DateTime.now().millisecondsSinceEpoch}';
    final payout = SettlementPayout(
      id: settlementId,
      orderId: 'WITHDRAWAL-${DateTime.now().millisecondsSinceEpoch}',
      orderNumber:
          'WD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      recipientId: _currentUserId,
      recipientName: displayName,
      recipientRole: 'farmer',
      bankName: bankName,
      accountNumber: accountNumber,
      grossAmount: amount,
      platformFee: fee,
      netAmount: net,
      payoutMethod: payoutMethod,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    _settlements.insert(0, payout);
    _totalEarnings = (_totalEarnings - amount).clamp(0.0, double.infinity);
    _transactions.insert(
      0,
      EarningsTransaction(
        id: settlementId,
        date: DateTime.now().toIso8601String().substring(0, 10),
        orderNumber: payout.orderNumber,
        amount: -amount,
        isCredit: false,
      ),
    );
    notifyListeners();
    logAuditEvent(
      actionType: 'FARMER_WITHDRAWAL_REQUESTED',
      targetEntity: 'Settlement',
      targetId: settlementId,
      details:
          'Farmer requested payout of LKR ${amount.toStringAsFixed(2)} to $bankName ($accountNumber).',
      severity: 'info',
    );
    if (_currentUserId.isNotEmpty) {
      // Persist the full payout so admins see it live in Treasury.
      _persistToFirestore(() => _firestoreService.createSettlement(payout));
    }
  }
}
