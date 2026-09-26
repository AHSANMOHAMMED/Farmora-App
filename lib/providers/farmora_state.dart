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
import '../models/admin_stats.dart';
import '../models/dispute_model.dart';
import '../services/chat_crypto.dart';
import '../services/chat_outbox_service.dart';
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
import '../core/constants/demo_catalog_data.dart';
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
  StreamSubscription<List<Dispute>>? _disputesSub;
  StreamSubscription<List<FarmoraConversation>>? _conversationsSub;
  StreamSubscription<Map<String, dynamic>?>? _profileSub;
  String? _fcmToken;
  _AppLifecycleHook? _lifecycleHook;
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

  /// Why the last sign-in was refused or the session ended (suspended /
  /// deleted account, inactivity timeout). Cleared on the next sign-in.
  String? authBlockedReason;

  /// `users/{uid}.notificationPrefs` ({orderUpdates, messages, promos,
  /// quietHoursStart, quietHoursEnd}).
  Map<String, dynamic> notificationPrefs = const {};

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

  // Order chats the user takes part in (newest first)
  final List<FarmoraConversation> _conversations = [];

  // Admin: open/resolved disputes (newest first)
  final List<Dispute> _disputes = [];

  // Admin: aggregate platform totals
  AdminStats _adminStats = AdminStats.empty;
  bool _adminStatsLoading = false;

  // Server Maintenance & Platform Config
  bool _settingsLoaded = false;
  int _sessionTimeoutMinutes = 60;
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

  /// Seeds authentic Sri Lankan agricultural produce, orders, jobs, and market prices.
  void _initDemoData() {
    _products.clear();
    _products.addAll(DemoCatalogData.sampleProducts);
    _orders.clear();
    _orders.addAll(DemoCatalogData.sampleOrders);
    _jobs.clear();
    _jobs.addAll(DemoCatalogData.sampleJobs);
    _offers.clear();
    _offers.addAll(DemoCatalogData.sampleOffers);
    _marketPrices.clear();
    _marketPrices.addAll(DemoCatalogData.sampleMarketPrices);
    _recalculateStats();
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
  List<Dispute> get disputes => List.unmodifiable(_disputes);
  List<FarmoraConversation> get conversations =>
      List.unmodifiable(_conversations);

  /// Unread chat messages across all conversations (for badges).
  int get unreadMessagesCount => _conversations.fold(
      0, (sum, c) => sum + c.unreadFor(_currentUserId));
  AdminStats get adminStats => _adminStats;
  bool get adminStatsLoading => _adminStatsLoading;
  bool get settingsLoaded => _settingsLoaded;

  /// Inactivity sign-out after this many minutes (0 disables it).
  int get sessionTimeoutMinutes => _sessionTimeoutMinutes;
  bool get maintenanceMode => _maintenanceMode;
  String get maintenanceNotice => _maintenanceNotice;

  /// Platform commission in basis points (500 = 5%).
  int get platformFeeBps => (_commissionRate * 100).round();
  double get commissionRate => _commissionRate;
  int get escrowReleaseHours => _escrowReleaseHours;
  String get minAppVersion => _minAppVersion;
  List<FarmoraOffer> get buyerOffers => _offers
      .where((o) =>
          o.buyerId == _currentUserId ||
          (_currentUserId.isEmpty && o.buyerId == 'buyer_demo'))
      .toList();
  List<FarmoraOffer> get farmerOffers => _offers
      .where((o) =>
          o.farmerId == _currentUserId ||
          (_currentUserId.isEmpty && o.farmerId == 'farmer_demo_1'))
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

  /// Units of [product] a buyer can order: `quantityAvailable`, else the
  /// number in the legacy `quantity` text (mirrors the buyer screens'
  /// `buyerAvailableQty`).
  static int _availableUnits(Product product) {
    if (product.quantityAvailable > 0) return product.quantityAvailable;
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(product.quantity);
    return match == null ? 0 : (double.tryParse(match.group(0)!) ?? 0).floor();
  }

  /// Caps [quantity] at the product's stock. Unknown stock (0) is not capped;
  /// the backend still validates stock when the order is placed.
  static int _capToStock(Product product, int quantity) {
    final available = _availableUnits(product);
    return available > 0 && quantity > available ? available : quantity;
  }

  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex =
        _cartItems.indexWhere((c) => c.product.id == product.id);
    if (existingIndex != -1) {
      final existing = _cartItems[existingIndex];
      _cartItems[existingIndex] = existing.copyWith(
          quantity: _capToStock(product, existing.quantity + quantity));
    } else {
      _cartItems.add(CartItem(
          product: product, quantity: _capToStock(product, quantity)));
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
        final item = _cartItems[index];
        _cartItems[index] =
            item.copyWith(quantity: _capToStock(item.product, quantity));
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

  /// One delivery fee per farmer in the cart (each farmer ships separately).
  double get cartDeliveryFee =>
      defaultDeliveryFeeLkr *
      _cartItems.map((c) => c.product.farmerId).toSet().length;
  double get cartGrandTotal => cartSubtotal + cartDeliveryFee;

  String deliveryAddressDraft = '';
  String paymentMethodDraft = PaymentMethod.cod;
  String? _lastOrderError;
  String? get lastOrderError => _lastOrderError;

  /// Clears a stale checkout error (e.g. when the cart screen is reopened).
  void clearLastOrderError() {
    if (_lastOrderError == null) return;
    _lastOrderError = null;
    notifyListeners();
  }

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
    if (_cartItems.isEmpty || _placingOrder) {
      return false;
    }
    if (transporterId == null || transporterId.isEmpty) {
      _lastOrderError = 'Choose a transporter for this delivery.';
      notifyListeners();
      return false;
    }
    final method = paymentMethod ?? paymentMethodDraft;
    final address = (deliveryAddress ?? deliveryAddressDraft).trim();
    if (address.length < 5) {
      _lastOrderError = 'Enter a complete delivery address.';
      notifyListeners();
      return false;
    }
    // Idempotency: same cart snapshot within 30s is treated as a repeated tap.
    final key =
        _cartItems.map((c) => '${c.product.id}:${c.quantity}').join('|');
    final fingerprint = '$key|$address|$method';
    if (_checkoutAttemptFingerprint != fingerprint) {
      final random = Random.secure();
      _checkoutAttemptFingerprint = fingerprint;
      _checkoutAttemptKey = List.generate(
        4,
        (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'),
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
        try {
          final feeMinor = (defaultDeliveryFeeLkr * 100).round();
          final farmersCharged = <String>{};
          for (final item in _cartItems) {
            final firstForFarmer = farmersCharged.add(item.product.farmerId);
            await _firestoreService.createSecureOrder(
              productId: item.product.id,
              quantity: item.quantity,
              deliveryFeeMinor: firstForFarmer ? feeMinor : 0,
              transporterId: transporterId,
              deliveryAddress: address,
              idempotencyKey: '${_checkoutAttemptKey!}_${item.product.id}',
              paymentMethod: method,
            );
          }
        } catch (backendError) {
          debugPrint('Backend order error, applying optimistic fallback: $backendError');
          _applyLocalOrderPlacement(address, transporterId, method);
        }
      } else {
        _applyLocalOrderPlacement(address, transporterId, method);
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

  void _applyLocalOrderPlacement(
      String address, String transporterId, String method) {
    final now = DateTime.now();
    final timeStr = DateFormat('yyyyMMdd-HHmm').format(now);
    int idx = 1;
    for (final item in _cartItems) {
      final orderNum = 'ORD-$timeStr-${Random().nextInt(900) + 100}';
      final orderId = 'order_local_${now.millisecondsSinceEpoch}_$idx';
      final total = item.product.effectivePricePerUnit * item.quantity;
      final newOrder = FarmoraOrder(
        id: orderId,
        orderNumber: orderNum,
        title: '${item.product.name} Order',
        productName: item.product.name,
        quantity: '${item.quantity} ${item.product.unit}',
        grade: 'Grade A',
        unitPrice:
            'LKR ${item.product.effectivePricePerUnit.toStringAsFixed(2)} / ${item.product.unit}',
        totalAmount: 'LKR ${total.toStringAsFixed(2)}',
        totalAmountNumber: total,
        buyerName: displayName.isNotEmpty ? displayName : 'Saman Perera',
        buyerCompany: 'Perera Wholesale Lanka',
        buyerAvatar: 'assets/images/user_avatar.png',
        buyerPhone: phone.isNotEmpty ? phone : '+94 77 123 4567',
        deliveryAddress: address,
        detail:
            'Fresh harvest delivery from ${item.product.location} to $address',
        status: 'Pending',
        progress: 0.1,
        color: const Color(0xFFE8F5E9),
        buyerId: _currentUserId.isNotEmpty ? _currentUserId : 'buyer_demo',
        farmerId: item.product.farmerId,
        transporterId: transporterId,
        productId: item.product.id,
        createdAt: now,
        paymentMethod: method,
      );
      _orders.insert(0, newOrder);

      final newJob = TransportJob(
        id: 'job_local_${now.millisecondsSinceEpoch}_$idx',
        title: '${item.product.name} Transport (${item.quantity} ${item.product.unit})',
        route: '${item.product.location} → $address',
        detail:
            'Deliver ${item.quantity} ${item.product.unit} fresh produce to buyer',
        fee: 'LKR ${defaultDeliveryFeeLkr.toStringAsFixed(2)}',
        accepted: false,
        status: 'requested',
        orderId: orderId,
        transporterId: transporterId,
        pickup: item.product.location,
        dropoff: address,
        buyerId: _currentUserId.isNotEmpty ? _currentUserId : 'buyer_demo',
        farmerId: item.product.farmerId,
        deliveryFeeMinor: (defaultDeliveryFeeLkr * 100).round(),
        quantityValue: item.quantity.toDouble(),
        unit: item.product.unit,
        productName: item.product.name,
        farmerName: item.product.farmerId == 'farmer_demo_1'
            ? 'Sunil Bandara'
            : 'Local Farmer',
        buyerName: displayName.isNotEmpty ? displayName : 'Saman Perera',
        orderNumber: orderNum,
        createdAt: now,
      );
      _jobs.insert(0, newJob);

      final pIdx = _products.indexWhere((p) => p.id == item.product.id);
      if (pIdx != -1) {
        final existing = _products[pIdx];
        final remaining = max(0, existing.quantityAvailable - item.quantity);
        _products[pIdx] = existing.copyWith(
          quantityAvailable: remaining,
          quantity: '$remaining ${existing.unit} available',
          status: remaining == 0 ? 'Empty' : existing.status,
        );
      }
      idx++;
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

  /// Signs out and clears everything tied to the account: push token,
  /// chat key cache, offline chat outbox, live subscriptions and data.
  Future<void> signOut({String? reason}) async {
    final uid = _currentUserId;
    final token = _fcmToken;
    _stopSessionTimer();
    _lifecycleHook?.detach();
    _lifecycleHook = null;
    if (token != null && token.isNotEmpty && uid.isNotEmpty) {
      try {
        await _firestoreService.unregisterDeviceToken(token);
      } catch (e) {
        debugPrint('Device token unregister skipped: $e');
      }
    }
    _fcmToken = null;
    if (uid.isNotEmpty) {
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (e) {
        debugPrint('FCM token delete skipped: $e');
      }
      try {
        await ChatOutboxService.clear(uid);
      } catch (e) {
        debugPrint('Chat outbox clear skipped: $e');
      }
    }
    ChatCrypto.instance.reset();
    signedIn = false;
    _currentUserId = '';
    _profileLoaded = false;
    isVerified = false;
    authBlockedReason = reason;
    disposeFirestoreSubscriptions();
    _deviceTokenSub?.cancel();
    _deviceTokenSub = null;
    _clearAccountData();
    // Stop any live location broadcast — privacy requires it.
    DeliveryLocationService.instance.stopAll();
    UserLocationService.instance.stopSharing();
    await _authService.signOut();
    notifyListeners();
  }

  /// Drops account-specific data and resets to authentic catalog and market items.
  void _clearAccountData() {
    _initDemoData();
    _users.clear();
    _verificationDocs.clear();
    _notifications.clear();
    _reviews.clear();
    _auditLogs.clear();
    _settlements.clear();
    _disputes.clear();
    _conversations.clear();
    _cartItems.clear();
    _adminStats = AdminStats.empty;
    notificationPrefs = const {};
    _recalculateStats();
  }

  // ── Session inactivity timeout ─────────────────────────────
  Timer? _sessionTimer;
  DateTime _lastActivity = DateTime.now();

  /// Call on user interaction (app-level pointer Listener). Cheap: only
  /// records the time; a once-a-minute timer checks for inactivity.
  void recordActivity() {
    _lastActivity = DateTime.now();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _lastActivity = DateTime.now();
    if (_sessionTimeoutMinutes <= 0) return;
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_currentUserId.isEmpty || _sessionTimeoutMinutes <= 0) return;
      final idle = DateTime.now().difference(_lastActivity);
      if (idle >= Duration(minutes: _sessionTimeoutMinutes)) {
        signOut(
          reason: 'You were signed out after $_sessionTimeoutMinutes minutes '
              'of inactivity.',
        );
      }
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  // ── Offline chat outbox ─────────────────────────────────────
  bool _flushingOutbox = false;

  /// Re-sends encrypted chat messages queued while offline. Called after
  /// sign-in and when the app resumes. Stops at the first connectivity
  /// failure; messages the server rejects are dropped (they would never
  /// succeed). Returns how many messages were sent.
  Future<int> flushChatOutbox() async {
    final uid = _currentUserId;
    if (uid.isEmpty || _flushingOutbox) return 0;
    _flushingOutbox = true;
    var sent = 0;
    try {
      final pending = await ChatOutboxService.getPending(uid: uid);
      for (final msg in pending) {
        try {
          await _firestoreService.sendEncryptedMessage(
            orderId: msg.orderId,
            recipientId: msg.recipientId,
            ciphertext: msg.ciphertext,
            conversationId: msg.conversationId,
          );
          await ChatOutboxService.remove(msg, uid: uid);
          sent++;
        } catch (e) {
          if (ChatOutboxService.shouldQueue(e)) break;
          debugPrint('Queued chat message rejected, dropping: $e');
          await ChatOutboxService.remove(msg, uid: uid);
        }
      }
    } catch (e) {
      debugPrint('Chat outbox flush skipped: $e');
    } finally {
      _flushingOutbox = false;
    }
    return sent;
  }

  /// Live account-state gate: an admin suspending / deleting the account
  /// signs the user out with a message (on Spark there is no server-side
  /// Auth disable). Also keeps [isVerified] current after admin review.
  void _watchOwnProfile(String uid) {
    _profileSub?.cancel();
    _profileSub = _firestoreService.userProfileStream(uid).listen(
      (profile) {
        if (profile == null || _currentUserId != uid) return;
        if (profile['isDeleted'] == true || profile['isSuspended'] == true) {
          signOut(
            reason: profile['isDeleted'] == true
                ? 'This account has been deleted.'
                : 'This account has been suspended. Contact Farmora support.',
          );
          return;
        }
        final verified = profile['isVerified'] == true;
        if (verified != isVerified) {
          isVerified = verified;
          notifyListeners();
        }
      },
      onError: (Object e) => debugPrint('Profile watch skipped: $e'),
    );
  }

  /// Transporters publish their public discovery card (Spark mode).
  Future<void> _syncTransporterCard() async {
    try {
      await _firestoreService.syncMyTransporterProfile();
    } catch (e) {
      debugPrint('Transporter card sync skipped: $e');
    }
  }

  /// Publishes this device's chat public key so peers can encrypt to it
  /// before the user first opens a chat. Best-effort.
  Future<void> _publishChatKey() async {
    try {
      final key = await ChatCrypto.instance.publicKeyBase64();
      await _firestoreService.publishChatPublicKey(key);
    } catch (e) {
      debugPrint('Chat key publish skipped: $e');
    }
  }

  /// Marks [conversationId] read for the signed-in user. Throws.
  Future<void> markConversationRead(String conversationId) async {
    _requireSignedIn();
    await _firestoreService.markConversationRead(conversationId);
  }

  void _onAppResumed() {
    if (_currentUserId.isEmpty) return;
    flushChatOutbox();
    _loadPlatformSettings();
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

  /// Adds [p] to the catalogue immediately and syncs to Firestore if signed in.
  Future<String> addProduct(Product p) async {
    final effectiveId = p.id.isNotEmpty
        ? p.id
        : 'prod_local_${DateTime.now().millisecondsSinceEpoch}';
    final productWithId = p.copyWith(
      id: effectiveId,
      farmerId: p.farmerId.isNotEmpty
          ? p.farmerId
          : (_currentUserId.isNotEmpty ? _currentUserId : 'farmer_demo_1'),
    );
    _products.removeWhere((item) => item.id == effectiveId);
    _products.insert(0, productWithId);
    notifyListeners();

    if (_currentUserId.isNotEmpty) {
      try {
        final serverId =
            await _firestoreService.createSecureProduct(productWithId);
        if (serverId.isNotEmpty && serverId != effectiveId) {
          final idx = _products.indexWhere((item) => item.id == effectiveId);
          if (idx != -1) {
            _products[idx] = productWithId.copyWith(id: serverId);
            notifyListeners();
          }
          return serverId;
        }
      } catch (e) {
        debugPrint('Firestore createSecureProduct sync skipped: $e');
      }
    }
    return effectiveId;
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

  /// Product writes go through callables; the products stream refreshes the
  /// catalogue. All of these throw so the screen can show the error.
  Future<void> updateProduct(Product p) async {
    if (_currentUserId.isEmpty) throw StateError('Authentication required.');
    await _firestoreService.updateProduct(p.id, p.toMap());
  }

  Future<void> toggleProductStock(String id) async {
    final current = _products.where((p) => p.id == id).firstOrNull;
    if (current == null) return;
    final newStatus = current.status == 'Active' ? 'Empty' : 'Active';
    await _firestoreService.updateProduct(id, {'status': newStatus});
  }

  Future<void> deleteProduct(String id) async {
    await _firestoreService.deleteProduct(id);
  }

  // ── Order lifecycle (callables; the orders stream shows the result) ──

  void _requireSignedIn() {
    if (_currentUserId.isEmpty) {
      throw UserStateError(L10n.current.errorSignInAgain);
    }
  }

  /// Farmer accepts a pending order (server creates the transport job).
  Future<void> acceptOrder(String orderId) async {
    _requireSignedIn();
    await _firestoreService.transitionOrder(orderId, 'confirmed');
  }

  /// Farmer declines a pending order.
  Future<void> declineOrder(String orderId) async {
    _requireSignedIn();
    await _firestoreService.transitionOrder(orderId, 'rejected');
  }

  /// Buyer (or farmer) cancels an order.
  Future<void> cancelOrder(String orderId) async {
    _requireSignedIn();
    await _firestoreService.transitionOrder(orderId, 'cancelled');
  }

  /// Farmer confirms the goods were handed to the transporter
  /// (`confirmHandover`; sets `farmerHandedOverAt`, no status change).
  Future<void> confirmHandover(String orderId) async {
    _requireSignedIn();
    await _firestoreService.confirmHandover(orderId);
  }

  /// Legacy name for the farmer "handed over" action — see [confirmHandover].
  Future<void> completeOrder(String orderId) => confirmHandover(orderId);

  // ── Payments (COD / Bank Deposit) ───────────────────────

  Future<void> saveBankDetails(BankDetails details) async {
    if (_currentUserId.isNotEmpty) {
      await _paymentService.saveBankDetails(details);
    }
    _myBankDetails = details;
    notifyListeners();
  }

  /// Checkout: whether [farmerId] accepts bank deposits (callable; buyers
  /// cannot read other users' bank details).
  Future<bool> farmerAcceptsBankDeposit(String farmerId) async {
    if (_currentUserId.isEmpty || farmerId.isEmpty) return false;
    return _paymentService.farmerAcceptsBankDeposit(farmerId);
  }

  /// Account the buyer pays into for [order]: the order's
  /// `bankDetailsSnapshot`, else fetched for the buyer by the server.
  Future<BankDetails> bankDetailsForOrder(FarmoraOrder order) async {
    if (_currentUserId.isEmpty) return BankDetails.empty;
    return _paymentService.bankDetailsForOrder(order);
  }

  /// Bank Deposit is offered only when every farmer in the cart has an account.
  Future<bool> cartSupportsBankDeposit() async {
    if (_cartItems.isEmpty || _currentUserId.isEmpty) return false;
    final farmerIds = _cartItems.map((c) => c.product.farmerId).toSet();
    for (final farmerId in farmerIds) {
      if (!await farmerAcceptsBankDeposit(farmerId)) return false;
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

  /// Writes to Firestore; the orders stream refreshes the UI. Throws when
  /// signed out or when the transition is refused.
  Future<void> _applyPayment(
    String orderId, {
    required Future<void> Function() remote,
    required bool Function(FarmoraOrder order) allowed,
    required FarmoraOrder Function(FarmoraOrder order) local,
  }) async {
    if (_currentUserId.isEmpty) {
      throw UserStateError(L10n.current.statePaymentActionUnavailable);
    }
    await remote();
  }

  // ── Offers & Negotiation CRUD ───────────────────────────
  // All offer changes go through callables; the offers stream shows them.

  Future<void> makeOffer({
    required String productId,
    required String productName,
    required String farmerId,
    required int quantity,
    required double price,
  }) async {
    if (_currentUserId.isEmpty) throw StateError('Authentication required.');
    await _firestoreService.createOffer(
      productId: productId,
      proposedQuantity: quantity,
      proposedPrice: price,
    );
  }

  /// Farmer accepts a `pending` offer, or the buyer accepts a `countered`
  /// one. For the buyer, [deliveryAddress] (defaults to the checkout draft),
  /// [paymentMethod] and [transporterId] are used for the created order.
  Future<void> acceptOffer(
    String offerId, {
    String? deliveryAddress,
    String? paymentMethod,
    String? transporterId,
  }) async {
    if (_currentUserId.isEmpty) throw StateError('Authentication required.');
    final address = deliveryAddress ??
        (role == Role.buyer ? deliveryAddressDraft.trim() : null);
    await _firestoreService.acceptOffer(
      offerId: offerId,
      deliveryFeeMinor: (defaultDeliveryFeeLkr * 100).round(),
      deliveryAddress: address,
      paymentMethod: paymentMethod,
      transporterId: transporterId,
    );
  }

  Future<void> rejectOffer(String offerId) async {
    if (_currentUserId.isEmpty) throw StateError('Authentication required.');
    await _firestoreService.rejectOffer(offerId);
  }

  /// Farmer counters with a new PER-UNIT price (LKR).
  Future<void> counterOffer(String offerId, double counterPrice) async {
    if (_currentUserId.isEmpty) throw StateError('Authentication required.');
    await _firestoreService.counterOffer(
      offerId: offerId,
      counterPrice: counterPrice,
    );
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

  Future<void> updateJobStatus(String jobId, String status,
      {String? reason}) async {
    _requireSignedIn();
    await _firestoreService.transitionTransport(jobId, status, reason: reason);
  }

  /// Transporter declines a request addressed to them.
  Future<void> declineTransportJob(String jobId) async {
    _requireSignedIn();
    await _firestoreService.declineTransportJob(jobId);
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

  /// Farmer cancels a still-`requested` transport request.
  Future<void> cancelTransportRequest(String jobId) async {
    _requireSignedIn();
    await _firestoreService.cancelTransportRequest(jobId);
  }

  /// Legacy name for [cancelTransportRequest].
  Future<void> deleteTransportJob(String jobId) =>
      cancelTransportRequest(jobId);

  Future<void> updateOrderAddress(String orderId, String newAddress) async {
    await _firestoreService.updateOrderAddressCallable(
      orderId: orderId,
      deliveryAddress: newAddress,
    );
  }

  /// Transporter vehicle/service fields via the `updateTransporterProfile`
  /// callable. [capacityKg] is the legacy alias of [vehicleCapacity] in kg.
  Future<void> updateTransporterProfile({
    String? vehicleType,
    int? capacityKg,
    num? vehicleCapacity,
    String? vehicleCapacityUnit,
    List<String>? serviceDistricts,
    String? availabilityStatus,
  }) async {
    final capacity = vehicleCapacity ?? capacityKg;
    await _firestoreService.updateTransporterProfile(
      vehicleType: vehicleType,
      vehicleCapacity: capacity,
      vehicleCapacityUnit: vehicleCapacityUnit,
      serviceDistricts: serviceDistricts,
      availabilityStatus: availabilityStatus,
    );
    if (vehicleType != null) this.vehicleType = vehicleType;
    if (capacity != null) {
      final unit = vehicleCapacityUnit ?? 'kg';
      this.capacityKg = (capacity * (unit == 'tons' ? 1000 : 1)).round();
    }
    if (serviceDistricts != null) this.serviceDistricts = serviceDistricts;
    notifyListeners();
  }

  /// Admin: suspend/unsuspend (also disables the Auth account server-side).
  Future<void> setUserSuspended(String userId, bool suspended) async {
    await _firestoreService.setUserSuspended(
        userId: userId, suspended: suspended);
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
  /// Uploads the harvest video and links it to the product (the products
  /// stream shows it). Throws on failure.
  Future<Map<String, String>?> uploadHarvestVideo({
    required String productId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final result = await _firestoreService.uploadProductVideo(
      productId: productId,
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
    );
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _products[idx] = _products[idx].copyWith(
        videoUrl: result['url'],
        videoPath: result['path'],
        harvestStatus: HarvestStatus.harvested,
        harvestDate: DateTime.now(),
      );
      notifyListeners();
    }
    return result;
  }

  /// Removes the product's harvest video.
  Future<void> deleteHarvestVideo(Product product) async {
    await _firestoreService.deleteProductVideo(
      productId: product.id,
      storagePath: product.videoPath,
      downloadUrl: product.videoUrl,
    );
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = _products[idx].copyWith(
        videoUrl: null,
        videoPath: null,
      );
      notifyListeners();
    }
  }

  /// Generates the product QR via `generateProductQr`. Returns the payload.
  Future<String?> generateQrForProduct(String productId) async {
    final payload =
        await _firestoreService.generateProductQr(productId: productId);
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _products[idx] = _products[idx].copyWith(
        qrCode: payload,
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
    if (_currentUserId.isNotEmpty) {
      await _firestoreService.updateUserLocation(
        country: newCountry,
        district: newDistrict,
      );
    }
    country = newCountry;
    district = newDistrict;
    notifyListeners();
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
      final profile = await _loadUserProfile(uid).timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
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
      // Suspended / deleted accounts may not use the app.
      if (profile['isDeleted'] == true || profile['isSuspended'] == true) {
        final deleted = profile['isDeleted'] == true;
        await FirebaseAuth.instance.signOut();
        _currentUserId = '';
        signedIn = false;
        isVerified = false;
        authBlockedReason = deleted
            ? 'This account has been deleted.'
            : 'This account has been suspended. Contact Farmora support.';
        notifyListeners();
        return;
      }
      role = accountRole;
      authBlockedReason = null;
      await _syncLanguageWithProfile(profile);
      _applyProfileFields(profile);
      _profileLoaded = true;
      notifyListeners();
      _registerDeviceToken();
      _loadPlatformSettings();
      _lifecycleHook ??= _AppLifecycleHook.attach(_onAppResumed);
      _publishChatKey();
      _watchOwnProfile(uid);
      if (accountRole == Role.transporter) _syncTransporterCard();
      flushChatOutbox();
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
    final productsStream = role == Role.farmer
        ? _firestoreService.productsByFarmerStream(uid)
        // Buyers/transporters see the Active catalogue; admins see all.
        : _firestoreService.productsStream(activeOnly: !isAdmin);
    _productsSub = productsStream.listen(
      (firestoreProducts) {
        if (firestoreProducts.isNotEmpty) {
          _products.clear();
          _products.addAll(firestoreProducts);
        } else if (_products.isEmpty) {
          _products.addAll(DemoCatalogData.sampleProducts);
        }
        notifyListeners();
      },
      onError: (e) {
        if (_products.isEmpty) {
          _products.addAll(DemoCatalogData.sampleProducts);
        }
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
        if (firestoreOrders.isNotEmpty) {
          _orders.clear();
          _orders.addAll(firestoreOrders);
        } else if (_orders.isEmpty) {
          _orders.addAll(DemoCatalogData.sampleOrders);
        }
        _recalculateStats();
        _ordersLoading = false;
        notifyListeners();
      },
      onError: (e) {
        if (_orders.isEmpty) {
          _orders.addAll(DemoCatalogData.sampleOrders);
          _recalculateStats();
        }
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
        if (firestoreJobs.isNotEmpty) {
          _jobs.clear();
          _jobs.addAll(firestoreJobs);
        } else if (_jobs.isEmpty) {
          _jobs.addAll(DemoCatalogData.sampleJobs);
        }
        notifyListeners();
      },
      onError: (e) {
        if (_jobs.isEmpty) {
          _jobs.addAll(DemoCatalogData.sampleJobs);
        }
        debugPrint('Firestore jobs stream error: $e');
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

    _conversationsSub?.cancel();
    _conversationsSub =
        _firestoreService.conversationsForUserStream(uid).listen(
      (items) {
        _conversations
          ..clear()
          ..addAll(items);
        notifyListeners();
      },
      onError: (e) => debugPrint('Firestore conversations stream error: $e'),
    );

    // Subscribe to offers stream
    _offersSub?.cancel();
    final offersStream = role == Role.farmer
        ? _firestoreService.offersByFarmerStream(uid)
        : _firestoreService.offersByBuyerStream(uid);
    _offersSub = offersStream.listen(
      (firestoreOffers) {
        if (firestoreOffers.isNotEmpty) {
          _offers.clear();
          _offers.addAll(firestoreOffers);
        } else if (_offers.isEmpty) {
          _offers.addAll(DemoCatalogData.sampleOffers);
        }
        notifyListeners();
      },
      onError: (e) {
        if (_offers.isEmpty) {
          _offers.addAll(DemoCatalogData.sampleOffers);
        }
        debugPrint('Firestore offers stream error: $e');
      },
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
          _auditLogs
            ..clear()
            ..addAll(firestoreLogs);
          notifyListeners();
        },
        onError: (e) => debugPrint('Firestore audit stream error: $e'),
      );

      _disputesSub?.cancel();
      _disputesSub = _firestoreService.disputesStream().listen(
        (firestoreDisputes) {
          _disputes
            ..clear()
            ..addAll(firestoreDisputes);
          notifyListeners();
        },
        onError: (e) => debugPrint('Firestore disputes stream error: $e'),
      );

      _marketPricesSub?.cancel();
      _marketPricesSub = _firestoreService.marketPricesStream().listen(
        (firestorePrices) {
          if (firestorePrices.isNotEmpty) {
            _marketPrices
              ..clear()
              ..addAll(firestorePrices);
          } else if (_marketPrices.isEmpty) {
            _marketPrices.addAll(DemoCatalogData.sampleMarketPrices);
          }
          notifyListeners();
        },
        onError: (e) {
          if (_marketPrices.isEmpty) {
            _marketPrices.addAll(DemoCatalogData.sampleMarketPrices);
          }
          debugPrint('Firestore market prices stream error: $e');
        },
      );
    }

    // Settlements: admins see every payout; farmers and transporters see
    // their own withdrawal requests.
    _settlementsSub?.cancel();
    if (role != Role.buyer) {
      _settlementsSub = _firestoreService
          .settlementsStream(recipientId: isAdmin ? null : uid)
          .listen(
        (firestoreSettlements) {
          _settlements
            ..clear()
            ..addAll(firestoreSettlements);
          notifyListeners();
        },
        onError: (e) => debugPrint('Firestore settlements stream error: $e'),
      );
    }

    if (isAdmin) {
      refreshAdminStats().catchError(
          (Object e) => debugPrint('Admin stats load failed: $e'));
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
    _disputesSub?.cancel();
    _conversationsSub?.cancel();
    _profileSub?.cancel();
    _profileSub = null;
    _myBankDetails = BankDetails.empty;
  }

  @override
  void dispose() {
    _stopSessionTimer();
    _lifecycleHook?.detach();
    _lifecycleHook = null;
    disposeFirestoreSubscriptions();
    _deviceTokenSub?.cancel();
    super.dispose();
  }

  /// Admin: reload aggregate platform totals (pull-to-refresh). Throws.
  Future<void> refreshAdminStats() async {
    if (_currentUserId.isEmpty || role != Role.admin) return;
    _adminStatsLoading = true;
    notifyListeners();
    try {
      _adminStats = await _firestoreService.adminStats();
    } finally {
      _adminStatsLoading = false;
      notifyListeners();
    }
  }

  /// Admin only (rules). Throws on failure.
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

  /// The notifications stream reflects the change. Throws on failure.
  Future<void> markNotificationRead(String id) async {
    await _firestoreService.markNotificationRead(id);
  }

  Future<void> markAllNotificationsRead() async {
    if (_currentUserId.isEmpty) return;
    await _firestoreService.markAllNotificationsRead(_currentUserId);
  }

  Future<void> deleteNotification(String id) async {
    await _firestoreService.deleteNotification(id);
  }

  /// Saves `notificationPrefs` ({orderUpdates, messages, promos,
  /// quietHoursStart, quietHoursEnd}) on the profile. Throws on failure.
  Future<void> updateNotificationPrefs(Map<String, dynamic> prefs) async {
    _requireSignedIn();
    await _firestoreService.updateNotificationPreferences(prefs);
    notificationPrefs = Map.unmodifiable(prefs);
    notifyListeners();
  }

  Future<void> _registerDeviceToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      _fcmToken = token;
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
        _fcmToken = nextToken;
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

  /// Removed: verification documents change only through upload +
  /// `submitVerification` and the admin `reviewVerification` callable; the
  /// verification stream shows the result. Kept so old call sites compile.
  @Deprecated('Re-upload via uploadVerificationDocument + submitVerification')
  void updateVerificationDoc(String docId,
      {String? fileName,
      String? fileSizeInfo,
      String? imagePreview,
      VerificationStatus? status,
      String? errorMessage}) {
    debugPrint('updateVerificationDoc ignored: local-only edits are removed.');
  }

  /// Reloads public platform settings (every signed-in user). Throws.
  Future<void> refreshPlatformSettings() async {
    final settings = await _firestoreService.getPlatformSettings();
    _applyPlatformSettings(settings);
  }

  void _applyPlatformSettings(Map<String, dynamic> settings) {
    final feeMinor = (settings['defaultDeliveryFeeMinor'] as num?)?.toInt();
    if (feeMinor != null && feeMinor >= 0) {
      defaultDeliveryFeeLkr = feeMinor / 100.0;
    }
    final maintenance = settings['maintenanceMode'];
    if (maintenance is bool) _maintenanceMode = maintenance;
    final notice = settings['maintenanceNotice'];
    if (notice is String && notice.isNotEmpty) _maintenanceNotice = notice;
    final feeBps = (settings['platformFeeBps'] as num?)?.toInt();
    if (feeBps != null && feeBps >= 0) _commissionRate = feeBps / 100.0;
    final escrowHours = (settings['escrowReleaseHours'] as num?)?.toInt();
    if (escrowHours != null && escrowHours > 0) {
      _escrowReleaseHours = escrowHours;
    }
    final minVersion = settings['minAppVersion'];
    if (minVersion is String && minVersion.isNotEmpty) {
      _minAppVersion = minVersion;
    }
    final timeout = (settings['sessionTimeoutMinutes'] as num?)?.toInt();
    final timeoutChanged = timeout != null &&
        timeout >= 0 &&
        timeout != _sessionTimeoutMinutes;
    if (timeout != null && timeout >= 0) _sessionTimeoutMinutes = timeout;
    _settingsLoaded = true;
    if (_currentUserId.isNotEmpty &&
        (timeoutChanged || _sessionTimer == null)) {
      _startSessionTimer();
    }
    notifyListeners();
  }

  Future<void> _loadPlatformSettings() async {
    try {
      await refreshPlatformSettings();
    } catch (e) {
      // Keep last known / defaults; the gate re-checks on resume.
      debugPrint('Platform settings load failed: $e');
      if (_currentUserId.isNotEmpty && _sessionTimer == null) {
        _startSessionTimer();
      }
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
    final prefs = profile['notificationPrefs'];
    notificationPrefs = prefs is Map
        ? Map<String, dynamic>.unmodifiable(Map<String, dynamic>.from(prefs))
        : const {};
    // `vehicleCapacity` (+ unit) is canonical; `capacityKg` is legacy.
    final capacity = profile['vehicleCapacity'];
    if (capacity is num) {
      final unit = (profile['vehicleCapacityUnit'] ?? 'kg').toString();
      capacityKg = (capacity * (unit == 'tons' ? 1000 : 1)).round();
    }
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
    authBlockedReason = null;
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

  Future<bool> signInWithBackend(
      {required String phone, required String password}) async {
    authError = null;
    authBlockedReason = null;
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

  /// [phoneOtpCode]: SMS code from a prior [sendPhoneOtp]; when given, the
  /// phone number is linked to the new account (enables OTP reset).
  Future<bool> registerWithBackend(
      {required String name,
      required String phone,
      required String password,
      required Role role,
      String? district,
      String? phoneOtpCode}) async {
    authError = null;
    authBlockedReason = null;
    try {
      final result = await _authService.register(
          name: name,
          phone: phone,
          password: password,
          role: role,
          district: district,
          phoneOtpCode: phoneOtpCode);
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
    authBlockedReason = null;
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
    authBlockedReason = null;
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

  /// Forgot password, step 1: sends an SMS code. Returns the verification
  /// id for [resetPasswordWithOtp]. Throws [FarmoraAuthException].
  Future<String> sendPasswordResetOtp(String phone) =>
      _authService.sendPasswordResetOtp(phone);

  /// Forgot password, step 2. Leaves the user signed out; they then log in
  /// with the new password. Throws [FarmoraAuthException].
  Future<void> resetPasswordWithOtp({
    required String verificationId,
    required String code,
    required String newPassword,
  }) =>
      _authService.resetPasswordWithOtp(
        verificationId: verificationId,
        code: code,
        newPassword: newPassword,
      );

  /// Signed-in password change (re-authenticates first). Throws.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  /// Links the phone verified with [sendPhoneOtp] to the signed-in account.
  Future<void> linkPhoneWithOtp(String code) =>
      _authService.linkPhoneWithOtp(code);

  // ── Admin Platform & Market Management ──────────────────────────────
  /// Admin market-price writes: awaited, rethrown; the market prices stream
  /// shows the change. Audited after success.
  Future<void> updateMarketPrice(
    String id, {
    required double minPrice,
    required double maxPrice,
    required String trend,
  }) async {
    final existing = _marketPrices.where((p) => p.id == id).firstOrNull;
    if (existing == null) return;
    final updated = existing.copyWith(
      minPricePerKg: minPrice,
      maxPricePerKg: maxPrice,
      averagePricePerKg: (minPrice + maxPrice) / 2,
      trend: trend,
      updatedAt: DateTime.now(),
    );
    await _firestoreService.upsertMarketPrice(updated);
    logAuditEvent(
      actionType: 'MARKET_PRICE_UPDATE',
      targetEntity: 'MarketPrice',
      targetId: id,
      details:
          'Updated ${existing.cropName}: LKR $minPrice–$maxPrice/kg, trend $trend.',
      severity: 'info',
    );
  }

  Future<void> addMarketPrice(MarketPriceIndex item) async {
    await _firestoreService.upsertMarketPrice(item);
    logAuditEvent(
      actionType: 'MARKET_PRICE_CREATE',
      targetEntity: 'MarketPrice',
      targetId: item.id,
      details:
          'Added benchmark ${item.cropName} (${item.district}): LKR ${item.minPricePerKg}–${item.maxPricePerKg}/kg.',
      severity: 'info',
    );
  }

  /// Remove a market price benchmark in Firestore.
  Future<void> removeMarketPrice(String priceId) async {
    await _firestoreService.deleteMarketPrice(priceId);
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

  /// Admin: resolve a dispute via `resolveDispute` (the function updates
  /// order + dispute, notifies both parties and audits). [refundPercent] is
  /// ignored — the server derives it from [resolution].
  Future<void> resolveDisputeArbitration({
    required String orderId,
    required String resolution,
    required String adminNotes,
    double refundPercent = 100.0,
  }) async {
    await _firestoreService.resolveDispute(
      orderId: orderId,
      resolution: resolution,
      adminNotes: adminNotes,
    );
  }

  /// Admin: broadcast via `broadcastAdvisory`. Returns the recipient count.
  /// [priority] is kept for existing callers and not sent.
  Future<int> broadcastPlatformAdvisory({
    required String title,
    required String message,
    required String targetRole,
    String priority = 'normal',
  }) {
    return _firestoreService.broadcastAdvisory(
      title: title,
      body: message,
      audience: targetRole,
    );
  }

  // ── Admin: Review & Feedback Moderation ───────────────────────
  Future<void> moderateReview({
    required String reviewId,
    required ReviewStatus status,
    String? note,
  }) async {
    await _firestoreService.moderateReview(
      reviewId: reviewId,
      status: status.name,
      note: note,
    );
    logAuditEvent(
      actionType: 'REVIEW_MODERATION',
      targetEntity: 'Review',
      targetId: reviewId,
      details: 'Review status set to ${status.name}. Note: ${note ?? "None"}',
      severity: status == ReviewStatus.rejected ? 'warning' : 'info',
    );
  }

  Future<void> deleteReview({required String reviewId}) async {
    await _firestoreService.deleteReview(reviewId: reviewId);
    logAuditEvent(
      actionType: 'REVIEW_DELETE',
      targetEntity: 'Review',
      targetId: reviewId,
      details: 'Permanently deleted user review.',
      severity: 'warning',
    );
  }

  /// Tests only: puts [review] in the local list.
  @visibleForTesting
  void addReview(Review review) {
    _reviews.insert(0, review);
    notifyListeners();
  }

  // ── Admin: User Management Actions ────────────────────────────
  Future<void> setUserVerified({
    required String userId,
    required bool verified,
  }) async {
    await _firestoreService.setUserVerified(
        userId: userId, verified: verified);
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

  /// Admin: change a user's role via `adminSetUserRole` (audited
  /// server-side). Legacy name kept for existing screens.
  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) =>
      adminSetUserRole(userId: userId, role: role);

  Future<void> adminSetUserRole({
    required String userId,
    required String role,
  }) async {
    await _firestoreService.adminSetUserRole(uid: userId, role: role);
  }

  /// Admin: soft-delete a user (disabled + `isDeleted`), audited server-side.
  Future<void> adminDeleteUser(String userId) async {
    await _firestoreService.adminDeleteUser(userId);
  }

  // ── Admin: Server Maintenance & Platform Config ───────────────
  // Each setter writes `updatePlatformSettings` (audited server-side) and
  // only then updates local state. They throw on failure.

  Future<void> updatePlatformSettings(Map<String, dynamic> settings) async {
    await _firestoreService.updatePlatformSettings(settings);
    _applyPlatformSettings(settings);
  }

  Future<void> setMaintenanceMode({required bool enabled, String? notice}) {
    final text = (notice != null && notice.trim().isNotEmpty)
        ? notice.trim()
        : _maintenanceNotice;
    return updatePlatformSettings({
      'maintenanceMode': enabled,
      'maintenanceNotice': text,
    });
  }

  Future<void> setCommissionRate(double rate) {
    final clamped = rate.clamp(0.0, 50.0);
    return updatePlatformSettings({'platformFeeBps': (clamped * 100).round()});
  }

  Future<void> setEscrowReleaseHours(int hours) {
    return updatePlatformSettings(
        {'escrowReleaseHours': hours.clamp(1, 720)});
  }

  Future<void> setMinAppVersion(String version) async {
    final v = version.trim();
    if (v.isEmpty) return;
    await updatePlatformSettings({'minAppVersion': v});
  }

  Future<void> setSessionTimeoutMinutes(int minutes) {
    return updatePlatformSettings(
        {'sessionTimeoutMinutes': minutes.clamp(0, 1440)});
  }

  Future<void> setDefaultDeliveryFee(double lkr) {
    return updatePlatformSettings(
        {'defaultDeliveryFeeMinor': (lkr * 100).round().clamp(0, 10000000)});
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
    // Append-only record of a client-side write that already succeeded; the
    // audit stream shows it. Callable-backed actions are audited server-side.
    _firestoreService.writeAuditLog(log);
  }

  // ── Admin: Treasury & Bank Escrow Settlements ─────────────────
  // `updateSettlementStatus` validates, notifies the recipient and audits.

  Future<void> approveSettlement(
    String settlementId, {
    required String transactionReference,
  }) async {
    final reference = transactionReference.trim();
    if (reference.length < 4 || reference.length > 100) {
      throw UserArgumentError(L10n.current.stateSettlementReferenceRequired);
    }
    await _firestoreService.updateSettlementStatus(
      settlementId,
      status: 'settled',
      transactionReference: reference,
    );
  }

  Future<void> holdSettlement(String settlementId, String reason) async {
    await _firestoreService.updateSettlementStatus(
      settlementId,
      status: 'on_hold',
      holdReason: reason.trim(),
    );
  }

  Future<void> retrySettlement(String settlementId) async {
    await _firestoreService.updateSettlementStatus(
      settlementId,
      status: 'processing',
      clearHoldReason: true,
    );
  }

  Future<void> rejectSettlement(String settlementId, {String? reason}) async {
    await _firestoreService.updateSettlementStatus(
      settlementId,
      status: 'rejected',
      holdReason: reason?.trim(),
    );
  }

  // ── Farmer / transporter: payout withdrawal ────────────────────
  /// Requests a payout via `requestWithdrawal`; the server checks the
  /// available balance. The own-settlements stream shows the request.
  /// Returns the settlement id. Throws on failure.
  Future<String> requestWithdrawal({
    required double amount,
    required String bankName,
    required String accountNumber,
    String payoutMethod = 'CEFT',
  }) async {
    _requireSignedIn();
    if (amount <= 0) {
      throw UserArgumentError(L10n.current.stateInvalidWithdrawalAmount(
          AppFormat.lkr(_totalEarnings, decimals: 2)));
    }
    return _firestoreService.requestWithdrawal(
      amount: amount,
      bankName: bankName.trim(),
      accountNumber: accountNumber.trim(),
      payoutMethod: payoutMethod,
    );
  }

  /// Legacy name for [requestWithdrawal].
  Future<String> requestFarmerWithdrawal({
    required double amount,
    required String bankName,
    required String accountNumber,
    String payoutMethod = 'CEFT',
  }) =>
      requestWithdrawal(
        amount: amount,
        bankName: bankName,
        accountNumber: accountNumber,
        payoutMethod: payoutMethod,
      );
}

/// Calls [onResume] when the app returns to the foreground.
class _AppLifecycleHook with WidgetsBindingObserver {
  _AppLifecycleHook._(this._onResume);
  final VoidCallback _onResume;

  /// Null when no widgets binding exists (pure unit tests).
  static _AppLifecycleHook? attach(VoidCallback onResume) {
    try {
      final hook = _AppLifecycleHook._(onResume);
      WidgetsBinding.instance.addObserver(hook);
      return hook;
    } catch (_) {
      return null;
    }
  }

  void detach() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onResume();
  }
}
