import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../services/chat_outbox_service.dart';
import 'package:flutter/foundation.dart';
import '../core/services/firebase_auth_service.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/config/app_backend.dart';
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
  bool isProductsLoading = false;
  bool isOrdersLoading = false;
  bool isJobsLoading = false;

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
    _initDemoData();
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
  List<FarmoraOffer> get buyerOffers => _offers
      .where((o) =>
          _currentUserId.isEmpty ||
          o.buyerId == _currentUserId ||
          o.buyerId == 'buyer_demo')
      .toList();
  List<FarmoraOffer> get farmerOffers => _offers
      .where((o) =>
          _currentUserId.isEmpty ||
          o.farmerId == _currentUserId ||
          o.farmerId == 'farmer_demo_1')
      .toList();
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
  DateTime? _lastOrderAt;
  String? _checkoutAttemptFingerprint;
  String? _checkoutAttemptKey;

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
    String? paymentMethod,
    String? transporterId,
  }) async {
    if (_cartItems.isEmpty || _placingOrder) return false;
    final method = paymentMethod ?? paymentMethodDraft;
    final address = (deliveryAddress ?? deliveryAddressDraft).trim();
    if (address.length < 5) return false;
    // Idempotency: same cart snapshot within 30s is treated as a repeated tap.
    final key =
        _cartItems.map((c) => '${c.product.id}:${c.quantity}').join('|');
    final fingerprint = '$key|$address|$method|$transporterId';
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
      if (_currentUserId.isNotEmpty) {
        for (var itemIndex = 0; itemIndex < _cartItems.length; itemIndex++) {
          final item = _cartItems[itemIndex];
          await _firestoreService.createSecureOrder(
            productId: item.product.id,
            quantity: item.quantity,
            deliveryFeeMinor:
                itemIndex == 0 ? (cartDeliveryFee * 100).round() : 0,
            deliveryAddress: address,
            idempotencyKey: '${_checkoutAttemptKey!}_${item.product.id}',
            paymentMethod: method,
            transporterId: transporterId,
          );
        }
      }

      // Firebase-backed orders arrive through the scoped Firestore listener.
      // Only create local records in unauthenticated demonstration mode.
      if (_currentUserId.isEmpty) {
        for (var itemIndex = 0; itemIndex < _cartItems.length; itemIndex++) {
          final item = _cartItems[itemIndex];
          final itemDeliveryFee = itemIndex == 0 ? cartDeliveryFee : 0.0;
          final orderId =
              'ORD-${DateTime.now().millisecondsSinceEpoch}-${item.product.id.hashCode.abs() % 1000}';
          final subtotal = item.product.effectivePricePerUnit * item.quantity;
          final totalAmount = subtotal + itemDeliveryFee;
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
            productId: item.product.id,
            subtotalMinor: (subtotal * 100).round(),
            deliveryFeeMinor: (itemDeliveryFee * 100).round(),
            totalMinor: (totalAmount * 100).round(),
            paymentMethod: method,
            paymentStatus: 'pending',
            escrowStatus: 'Held',
          );
          _orders.insert(0, newOrder);

          // Also create linked TransportJob so Transporters see the delivery job!
          final newJob = TransportJob(
            id: 'JOB-${DateTime.now().millisecondsSinceEpoch}-${item.product.id.hashCode.abs() % 1000}',
            orderId: orderId,
            title: '${item.product.name} Delivery',
            route: '${item.product.location} → $address',
            detail:
                '${item.quantity} ${item.product.unit} of ${item.product.name}',
            fee: 'LKR ${itemDeliveryFee.toStringAsFixed(2)}',
            pickup: item.product.location,
            dropoff: address,
            status: 'requested',
            buyerId: _currentUserId.isNotEmpty ? _currentUserId : 'buyer_demo',
            farmerId: item.product.farmerId,
          );
          _jobs.insert(0, newJob);
        }
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
  void signIn(Role r) {
    role = r;
    signedIn = true;
    _recalculateStats();
    notifyListeners();
    // If user is already authenticated via Firebase, init Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      initFromFirestore(user.uid);
    }
  }

  Future<void> signOut() async {
    signedIn = false;
    _currentUserId = '';
    _profileLoaded = false;
    disposeFirestoreSubscriptions();
    _deviceTokenSub?.cancel();
    _deviceTokenSub = null;
    // Stop any live location broadcast — privacy requires it.
    DeliveryLocationService.instance.stopAll();
    await UserLocationService.instance.stopSharing();
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

  void addProduct(Product p) {
    final finalProduct = p.id.isEmpty
        ? p.copyWith(id: 'prod_${DateTime.now().millisecondsSinceEpoch}')
        : p;
    _products.removeWhere((item) => item.id == finalProduct.id);
    _products.insert(0, finalProduct);
    notifyListeners();

    if (_currentUserId.isNotEmpty) {
      _firestoreService.createSecureProduct(finalProduct).catchError((e) {
        debugPrint('Firestore createProduct note: $e');
        return '';
      });
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
      _offers[idx] =
          off.copyWith(status: 'accepted', updatedAt: DateTime.now());

      // When offer is accepted, create confirmed order!
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
      final totalAmount = off.proposedPrice * off.proposedQuantity;
      final newOrder = FarmoraOrder(
        id: orderId,
        orderNumber: orderId,
        title: off.productName,
        productName: off.productName,
        productId: off.productId,
        quantity: '${off.proposedQuantity} kg',
        totalAmount: 'LKR ${totalAmount.toStringAsFixed(2)}',
        totalAmountNumber: totalAmount,
        buyerName: displayName.isNotEmpty ? displayName : 'Demo Buyer',
        buyerCompany: 'Farmora Buyer Co.',
        deliveryAddress: deliveryAddressDraft.isNotEmpty
            ? deliveryAddressDraft
            : 'Colombo, Sri Lanka',
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
      _offers[idx] =
          _offers[idx].copyWith(status: 'rejected', updatedAt: DateTime.now());
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
      await _firestoreService.updateOfferStatus(
        offerId,
        'countered',
        proposedPrice: counterPrice,
      );
    }
  }

  Future<void> cancelOffer(String offerId) async {
    final idx = _offers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      _offers[idx] =
          _offers[idx].copyWith(status: 'cancelled', updatedAt: DateTime.now());
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

  Future<void> requestTransportForOrder(String orderId,
      {int? deliveryFeeMinor}) async {
    final feeMinor = deliveryFeeMinor ?? 35000;
    final orderIdx = _orders.indexWhere((o) => o.id == orderId);
    if (orderIdx != -1) {
      final ord = _orders[orderIdx];
      final existingJobIdx = _jobs.indexWhere((j) => j.orderId == orderId);
      if (existingJobIdx == -1) {
        final job = TransportJob(
          id: 'JOB-${DateTime.now().millisecondsSinceEpoch}',
          title:
              'Delivery for ${ord.productName.isNotEmpty ? ord.productName : ord.title}',
          route:
              'Farm Gate → ${ord.deliveryAddress.isNotEmpty ? ord.deliveryAddress : "Buyer Facility"}',
          detail: ord.quantity.isNotEmpty ? ord.quantity : 'Standard Load',
          fee: 'LKR ${(feeMinor / 100).toStringAsFixed(0)}',
          status: 'requested',
          accepted: false,
          pickup: 'Farm Gate',
          dropoff: ord.deliveryAddress.isNotEmpty
              ? ord.deliveryAddress
              : 'Buyer Facility',
          orderId: orderId,
          farmerId: ord.farmerId.isNotEmpty
              ? ord.farmerId
              : (_currentUserId.isNotEmpty ? _currentUserId : 'farmer_demo_1'),
          buyerId: ord.buyerId,
        );
        _jobs.insert(0, job);
      }
      _orders[orderIdx] = ord.copyWith(
        deliveryStatus: 'requested',
        deliveryFeeMinor: feeMinor,
      );
      notifyListeners();
    }
    try {
      await _firestoreService.requestTransport(
        orderId: orderId,
        deliveryFeeMinor: deliveryFeeMinor,
      );
    } catch (e) {
      debugPrint('Firestore requestTransport note: $e');
    }
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

  Future<void> retryOfflineMessages() async {
    final pending = await ChatOutboxService.getPending();
    for (final msg in pending) {
      try {
        await _firestoreService.sendEncryptedMessage(
          orderId: msg.orderId,
          recipientId: msg.recipientId,
          ciphertext: msg.ciphertext,
        );
        await ChatOutboxService.remove(msg);
      } catch (e) {
        debugPrint('Still offline or error sending message: $e');
      }
    }
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
      await _syncLanguageWithProfile(profile);
      _applyProfileFields(profile);
      _clearDemoDataForSignedInUser();
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

    retryOfflineMessages();
    // Subscribe to products stream
    _productsSub?.cancel();
    final productsStream = role == Role.farmer
        ? _firestoreService.productsByFarmerStream(uid)
        : _firestoreService.productsStream();
    isProductsLoading = true;
    notifyListeners();
    _productsSub = productsStream.listen(
      (firestoreProducts) {
        _products.clear();
        _products.addAll(firestoreProducts);
        isProductsLoading = false;
        notifyListeners();
      },
      onError: (e) {
        isProductsLoading = false;
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
        notifyListeners();
      },
      onError: (e) => debugPrint('Firestore orders stream error: $e'),
    );

    // Subscribe to transport jobs stream
    _jobsSub?.cancel();
    final jobsStream = switch (role) {
      Role.admin => _firestoreService.jobsStream(),
      Role.transporter => _firestoreService.jobsForTransporterStream(uid),
      _ => _firestoreService.jobsStream(),
    };
    isJobsLoading = true;
    _jobsSub = jobsStream.listen(
      (firestoreJobs) {
        _jobs.clear();
        _jobs.addAll(firestoreJobs);
        isJobsLoading = false;
        notifyListeners();
      },
      onError: (e) {
        isJobsLoading = false;
        debugPrint('Firestore jobs stream error: $e');
        notifyListeners();
      },
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

  List<FarmoraOrder> _demoPaymentHistory(DateTime now) {
    FarmoraOrder demo(String id, String product, double amount, String method,
        String payment, int createdDaysAgo, int? paidDaysAgo) {
      return FarmoraOrder(
        id: id,
        orderNumber: id,
        title: product,
        productName: product,
        quantity: '20 kg',
        totalAmount: 'LKR ${amount.toStringAsFixed(2)}',
        totalAmountNumber: amount,
        buyerName: 'Demo Buyer',
        detail: 'Demo order history',
        status: 'Delivered',
        progress: 1.0,
        color: const Color(0xFF43A047),
        buyerId: 'buyer_demo',
        farmerId: 'farmer_demo_1',
        createdAt: now.subtract(Duration(days: createdDaysAgo)),
        paymentMethod: method,
        paymentStatus: payment,
        paidAt: paidDaysAgo == null
            ? null
            : now.subtract(Duration(days: paidDaysAgo)),
      );
    }

    return [
      demo('ORD-0986', 'Butternut Pumpkin', 5300, PaymentMethod.bankDeposit,
          'proof_submitted', 2, null),
      demo('ORD-0991', 'Green Beans', 6400, PaymentMethod.cod, 'paid', 5, 3),
      demo(
          'ORD-0978', 'Leeks', 8750, PaymentMethod.bankDeposit, 'paid', 35, 32),
      demo('ORD-0965', 'Potatoes', 15200, PaymentMethod.cod, 'paid', 70, 66),
      demo('ORD-0952', 'Red Onions', 11800, PaymentMethod.bankDeposit, 'paid',
          100, 97),
      demo('ORD-0940', 'Cabbage', 7300, PaymentMethod.cod, 'paid', 130, 128),
    ];
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
          description:
              'Fresh highland organic ripe tomatoes harvested at peak freshness.',
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
          description:
              'Crunchy sweet farm fresh mountain carrots from Nuwara Eliya slopes.',
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
          description:
              'Pure Alba-grade Ceylon cinnamon sticks with rich aroma and flavour.',
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
          description:
              'Naturally ripened Cavendish bananas, sweet and pesticide-free.',
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
          description:
              'Spicy fresh green chillies direct from Dambulla agricultural hub.',
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
        // Payment history for the demo farmer so Earnings has real data.
        ..._demoPaymentHistory(DateTime.now()),
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

    if (_marketPrices.isEmpty) {
      _marketPrices.addAll([
        MarketPriceIndex(
          id: 'mpi-1',
          cropName: 'Organic Red Tomatoes',
          category: 'Vegetables',
          district: 'Dambulla',
          minPricePerKg: 150.0,
          maxPricePerKg: 200.0,
          averagePricePerKg: 175.0,
          trend: 'up',
          updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        MarketPriceIndex(
          id: 'mpi-2',
          cropName: 'Fresh Mountain Carrots',
          category: 'Vegetables',
          district: 'Nuwara Eliya',
          minPricePerKg: 210.0,
          maxPricePerKg: 260.0,
          averagePricePerKg: 235.0,
          trend: 'stable',
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        MarketPriceIndex(
          id: 'mpi-3',
          cropName: 'Ceylon Cinnamon Sticks',
          category: 'Spices',
          district: 'Matara',
          minPricePerKg: 850.0,
          maxPricePerKg: 1100.0,
          averagePricePerKg: 950.0,
          trend: 'up',
          updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        MarketPriceIndex(
          id: 'mpi-4',
          cropName: 'Green Chillies',
          category: 'Vegetables',
          district: 'Pettah',
          minPricePerKg: 380.0,
          maxPricePerKg: 460.0,
          averagePricePerKg: 420.0,
          trend: 'down',
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        MarketPriceIndex(
          id: 'mpi-5',
          cropName: 'Red Dambulla Onions',
          category: 'Vegetables',
          district: 'Dambulla',
          minPricePerKg: 280.0,
          maxPricePerKg: 340.0,
          averagePricePerKg: 310.0,
          trend: 'stable',
          updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        MarketPriceIndex(
          id: 'mpi-6',
          cropName: 'Cavendish / Red Banana',
          category: 'Fruits',
          district: 'Embilipitiya',
          minPricePerKg: 130.0,
          maxPricePerKg: 180.0,
          averagePricePerKg: 155.0,
          trend: 'up',
          updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
      ]);
    }

    if (_reviews.isEmpty) {
      _reviews.addAll([
        Review(
          id: 'rev-1',
          orderId: 'ord-101',
          orderNumber: 'ORD-7821',
          reviewerId: 'buyer_demo',
          reviewerName: 'Pettah Wholesale Stores',
          subjectId: 'farmer_demo_1',
          subjectName: 'Sunil Bandara (Farmer)',
          rating: 5,
          comment:
              'Excellent quality Nuwara Eliya mountain carrots. Well packed in standard crates with zero transport damage.',
          status: ReviewStatus.approved,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          moderatedAt: DateTime.now().subtract(const Duration(days: 1)),
          moderationNote: 'Verified order and delivery inspection.',
        ),
        Review(
          id: 'rev-2',
          orderId: 'ord-102',
          orderNumber: 'ORD-7822',
          reviewerId: 'buyer_demo_2',
          reviewerName: 'Kandy Green Grocers',
          subjectId: 'farmer_demo_2',
          subjectName: 'Kamal Perera (Farmer)',
          rating: 4,
          comment:
              'Cinnamon bark aroma and grade are authentic Ceylon Alba. Delivered right on schedule.',
          status: ReviewStatus.approved,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          moderatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Review(
          id: 'rev-3',
          orderId: 'ord-103',
          orderNumber: 'ORD-7824',
          reviewerId: 'buyer_demo_3',
          reviewerName: 'Galle Fresh Mart',
          subjectId: 'transporter_demo_1',
          subjectName: 'Rohan Jayasinghe (Transporter)',
          rating: 2,
          comment:
              'Tomatoes had minor bruising due to lack of thermal buffering during mid-day transit.',
          status: ReviewStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 18)),
        ),
        Review(
          id: 'rev-4',
          orderId: 'ord-104',
          orderNumber: 'ORD-7825',
          reviewerId: 'buyer_demo_4',
          reviewerName: 'Lanka Super Foods',
          subjectId: 'farmer_demo_3',
          subjectName: 'Unknown Seller',
          rating: 1,
          comment: 'Delivery delayed by 36 hours. Cabbage leaves were wilted.',
          status: ReviewStatus.rejected,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
          moderatedAt: DateTime.now().subtract(const Duration(days: 3)),
          moderationNote: 'Formal dispute arbitration opened.',
        ),
      ]);
    }

    if (_users.isEmpty) {
      _users.addAll([
        {
          'uid': 'usr-farmer-1',
          'id': 'usr-farmer-1',
          'name': 'Sunil Bandara',
          'role': 'farmer',
          'phone': '+94 77 123 4567',
          'email': 'sunil.bandara@farmora.lk',
          'district': 'Nuwara Eliya',
          'isVerified': true,
          'isSuspended': false,
        },
        {
          'uid': 'usr-buyer-1',
          'id': 'usr-buyer-1',
          'name': 'Pettah Wholesale Stores',
          'role': 'buyer',
          'phone': '+94 11 234 5678',
          'email': 'trades@pettahwholesale.lk',
          'district': 'Colombo',
          'isVerified': true,
          'isSuspended': false,
        },
        {
          'uid': 'usr-trans-1',
          'id': 'usr-trans-1',
          'name': 'Rohan Jayasinghe',
          'role': 'transporter',
          'phone': '+94 71 345 6789',
          'email': 'rohan.trans@farmora.lk',
          'district': 'Dambulla',
          'isVerified': false,
          'isSuspended': false,
        },
        {
          'uid': 'usr-admin-1',
          'id': 'usr-admin-1',
          'name': 'Platform SuperAdmin',
          'role': 'admin',
          'phone': '+94 11 999 8888',
          'email': 'admin@farmora.lk',
          'district': 'Colombo',
          'isVerified': true,
          'isSuspended': false,
        },
      ]);
    }

    if (_auditLogs.isEmpty) {
      _auditLogs.addAll([
        AuditLog(
          id: 'aud-001',
          actorId: 'usr-admin-1',
          actorName: 'Platform SuperAdmin',
          actorRole: 'admin',
          actionType: 'ESCROW_RELEASE',
          targetEntity: 'Order',
          targetId: 'ORD-1001',
          details:
              'Escrow released upon confirmed buyer delivery confirmation. LKR 4,850.00 disbursed to farmer.',
          severity: 'info',
          timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        AuditLog(
          id: 'aud-002',
          actorId: 'usr-admin-1',
          actorName: 'Platform SuperAdmin',
          actorRole: 'admin',
          actionType: 'USER_VERIFY',
          targetEntity: 'User',
          targetId: 'usr-farmer-1',
          details:
              'NIC & Agrarian Services registration certificate verified. Granted verified producer badge.',
          severity: 'info',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        AuditLog(
          id: 'aud-003',
          actorId: 'usr-admin-1',
          actorName: 'Platform SuperAdmin',
          actorRole: 'admin',
          actionType: 'COMMISSION_UPDATE',
          targetEntity: 'PlatformFee',
          targetId: 'commission_rate',
          details:
              'Updated wholesale platform commission rate from 4.5% to 5.0%.',
          severity: 'warning',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        AuditLog(
          id: 'aud-004',
          actorId: 'usr-admin-1',
          actorName: 'Platform SuperAdmin',
          actorRole: 'admin',
          actionType: 'DISPUTE_ARBITRATION',
          targetEntity: 'Order',
          targetId: 'ORD-7825',
          details:
              'Arbitrated transit spoilage dispute. 50% refund issued to buyer, 50% compensation to seller.',
          severity: 'critical',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ]);
    }

    if (_settlements.isEmpty) {
      _settlements.addAll([
        SettlementPayout(
          id: 'stl-101',
          orderId: 'ord-1001',
          orderNumber: 'ORD-1001',
          recipientId: 'usr-farmer-1',
          recipientName: 'Sunil Bandara',
          recipientRole: 'farmer',
          bankName: 'Bank of Ceylon (BOC)',
          accountNumber: '7829-1092-4821',
          grossAmount: 4850.0,
          platformFee: 242.5,
          netAmount: 4607.5,
          payoutMethod: 'CEFT',
          status: 'settled',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          settledAt: DateTime.now().subtract(const Duration(hours: 3)),
          transactionReference: 'BOC-CEFT-9847291',
        ),
        SettlementPayout(
          id: 'stl-102',
          orderId: 'ord-1002',
          orderNumber: 'ORD-1002',
          recipientId: 'farmer_demo_1',
          recipientName: 'Sunil Bandara',
          recipientRole: 'farmer',
          bankName: 'Commercial Bank of Ceylon',
          accountNumber: '8102-3948-2910',
          grossAmount: 12500.0,
          platformFee: 625.0,
          netAmount: 11875.0,
          payoutMethod: 'CEFT',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        SettlementPayout(
          id: 'stl-103',
          orderId: 'ord-1003',
          orderNumber: 'ORD-1003',
          recipientId: 'usr-trans-1',
          recipientName: 'Rohan Jayasinghe',
          recipientRole: 'transporter',
          bankName: 'Hatton National Bank (HNB)',
          accountNumber: '0092-4829-1092',
          grossAmount: 3500.0,
          platformFee: 175.0,
          netAmount: 3325.0,
          payoutMethod: 'SLIP',
          status: 'processing',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        SettlementPayout(
          id: 'stl-104',
          orderId: 'ord-1004',
          orderNumber: 'ORD-1004',
          recipientId: 'farmer_demo_2',
          recipientName: 'Matale Spice Cooperative',
          recipientRole: 'farmer',
          bankName: 'Sampath Bank',
          accountNumber: '1092-5829-3829',
          grossAmount: 24000.0,
          platformFee: 1200.0,
          netAmount: 22800.0,
          payoutMethod: 'CEFT',
          status: 'on_hold',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          holdReason: 'Recipient bank details under verification review.',
        ),
      ]);
    }
  }

  void _clearDemoDataForSignedInUser() {
    _products.clear();
    _orders.clear();
    _jobs.clear();
    _users.clear();
    _verificationDocs.clear();
    _notifications.clear();
    _offers.clear();
    _marketPrices.clear();
    _reviews.clear();
    _auditLogs.clear();
    _settlements.clear();
    _monthlyBars.clear();
    _transactions.clear();
    _totalEarnings = 0;
    _thisMonth = 0;
    _thisWeek = 0;
    _pendingPayments = 0;
    _cartItems.clear();
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
    if (_currentUserId.isNotEmpty) {
      await _firestoreService.resolveDispute(
        orderId: orderId,
        resolution: resolution,
        adminNotes: adminNotes,
        refundPercent: refundPercent,
      );
    }

    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final o = _orders[idx];
      final newStatus =
          resolution == 'refund_buyer' ? 'cancelled' : 'completed';
      final newPaymentStatus = _currentUserId.isEmpty
          ? switch (resolution) {
              'refund_buyer' => 'refunded',
              'release_farmer' => 'released',
              _ => 'settled_split',
            }
          : switch (resolution) {
              'refund_buyer' => 'refund_pending',
              'release_farmer' => 'settlement_pending',
              _ => 'split_settlement_pending',
            };

      _orders[idx] = o.copyWith(
        status: newStatus,
        paymentStatus: newPaymentStatus,
      );

      final settlementShare = switch (resolution) {
        'refund_buyer' => 0.0,
        'split_settlement' => o.total / 2,
        _ => o.total,
      };
      if (settlementShare > 0) {
        _transactions.add(EarningsTransaction(
          id: 'tx-arb-${DateTime.now().millisecondsSinceEpoch}',
          orderNumber: o.orderNumber,
          date: DateTime.now().toIso8601String().substring(0, 10),
          amount: settlementShare,
        ));
      }

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

  /// Best-effort Firestore persistence. Silently skips persistence when
  /// Firebase is unavailable (demo/test mode) so local state keeps working.
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
    final log = AuditLog(
      id: 'aud-${DateTime.now().millisecondsSinceEpoch}',
      actorId: _currentUserId.isNotEmpty ? _currentUserId : 'usr-admin-1',
      actorName: 'Platform SuperAdmin',
      actorRole: 'admin',
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
      if (_currentUserId.isNotEmpty) {
        await _firestoreService.updateSettlementStatus(
          settlementId,
          status: 'settled',
          transactionReference: reference,
        );
      }
      _settlements[idx] = s.copyWith(
        status: 'settled',
        settledAt: DateTime.now(),
        transactionReference: reference,
      );
      notifyListeners();
      logAuditEvent(
        actionType: 'SETTLEMENT_APPROVED',
        targetEntity: 'Settlement',
        targetId: settlementId,
        details:
            'Recorded the completed transfer of LKR ${s.netAmount.toStringAsFixed(2)} to ${s.recipientName} via ${s.bankName}. Ref: $reference',
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
    if (_currentUserId.isNotEmpty && kUseCloudFunctions) {
      try {
        final result = await FirebaseFunctions.instance
            .httpsCallable('requestWithdrawal')
            .call({
          'amount': amount,
          'bankName': bankName,
          'accountNumber': accountNumber,
          'payoutMethod': payoutMethod,
        });

        final newSettlementId = result.data['settlementId'] as String? ??
            'STL-${DateTime.now().millisecondsSinceEpoch}';

        final fee = amount * (_commissionRate / 100.0);
        final net = amount - fee;
        final payout = SettlementPayout(
          id: newSettlementId,
          orderId: 'WITHDRAWAL-${DateTime.now().millisecondsSinceEpoch}',
          orderNumber:
              'WD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          recipientId: _currentUserId,
          recipientName: displayName.isNotEmpty ? displayName : 'Farmer',
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

        notifyListeners();
        logAuditEvent(
          actionType: 'FARMER_WITHDRAWAL_REQUESTED',
          targetEntity: 'Settlement',
          targetId: newSettlementId,
          details:
              'Farmer requested payout of LKR ${amount.toStringAsFixed(2)} to $bankName ($accountNumber).',
          severity: 'info',
        );
      } catch (e) {
        throw UserStateError(L10n.current.stateWithdrawalFailed);
      }
    } else {
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
        recipientId:
            _currentUserId.isNotEmpty ? _currentUserId : 'farmer_demo_1',
        recipientName:
            displayName.isNotEmpty ? displayName : 'Ahsan (Green Fields Farm)',
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
        _persistToFirestore(() => _firestoreService.createSettlement(payout));
      }
    }
  }
}
