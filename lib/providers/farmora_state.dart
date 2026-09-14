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
  StreamSubscription<String>? _deviceTokenSub;
  bool signedIn = false;
  String language = 'English';
  String country = 'Sri Lanka';
  String district = '';
  Role role = Role.farmer;

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

  // Getters
  List<Product> get products => List.unmodifiable(_products);
  List<FarmoraOrder> get orders => List.unmodifiable(_orders);
  List<TransportJob> get jobs => List.unmodifiable(_jobs);
  List<Map<String, dynamic>> get users => List.unmodifiable(_users);
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
  double get cartDeliveryFee => _cartItems.isEmpty ? 0.0 : 350.0;
  double get cartGrandTotal => cartSubtotal + cartDeliveryFee;

  Future<bool> placeOrder() async {
    if (_cartItems.isEmpty || _placingOrder) return false;
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
        // Prices and stock are reloaded and committed by the trusted backend.
        for (final item in _cartItems) {
          await _firestoreService.createSecureOrder(
            productId: item.product.id,
            quantity: item.quantity,
            deliveryFeeMinor: 35000,
          );
        }
        _lastOrderKey = key;
        _lastOrderAt = DateTime.now();
        _cartItems.clear();
        notifyListeners();
        return true;
      }
    for (final item in _cartItems) {
      final order = FarmoraOrder(
        id: 'ord-${DateTime.now().millisecondsSinceEpoch}-${item.product.id}',
        orderNumber: '#${_orders.length + 1001}',
        title: item.product.name,
        productName: item.product.name,
        quantity: '${item.quantity} ${item.product.unit}',
        grade: item.product.isOrganic ? 'Organic' : 'Grade A',
        unitPrice: item.product.price,
        totalAmount:
            'LKR ${(item.product.effectivePricePerUnit * item.quantity).toStringAsFixed(2)}',
        totalAmountNumber: item.product.effectivePricePerUnit * item.quantity,
        buyerName: 'You',
        buyerCompany: 'Your Order',
        buyerAvatar: 'assets/images/buyer_sarah.png',
        buyerPhone: '',
        deliveryAddress: 'Delivery address TBD',
        detail:
            '${item.quantity} ${item.product.unit} · LKR ${(item.product.effectivePricePerUnit * item.quantity).toStringAsFixed(2)}',
        status: 'Pending',
        progress: 0.1,
        color: const Color(0xFF3478C5),
        timestamp: 'Just now',
        requestedDate: 'Today',
        buyerIcon: Icons.shopping_cart_rounded,
      );
      _orders.insert(0, order);
    }
    _lastOrderKey = key;
    _lastOrderAt = DateTime.now();
    _cartItems.clear();
    notifyListeners();
    return true;
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
        'සිංහල' => 'si',
        'தமிழ்' => 'ta',
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
    if (_currentUserId.isNotEmpty) {
      _firestoreService.updateOrderStatus(orderId, 'Accepted', 0.6);
    }
  }

  void declineOrder(String orderId) {
    if (_currentUserId.isNotEmpty) {
      _firestoreService.updateOrderStatus(orderId, 'Declined', 0.0);
    }
  }

  void acceptJob(String jobId) {
    if (_currentUserId.isNotEmpty) {
      _firestoreService.transitionTransport(jobId, 'accepted');
    }
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
      language =
          (profile['languageCode'] ?? profile['language'] ?? 'en') as String;
      country = (profile['country'] ?? 'Sri Lanka').toString();
      district = (profile['district'] ?? '').toString();
      _profileLoaded = true;
      notifyListeners();
      _registerDeviceToken();
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
      _ => null,
    };
    _jobsSub = jobsStream?.listen((firestoreJobs) {
      _jobs.clear();
      _jobs.addAll(firestoreJobs);
      notifyListeners();
    });

    // Subscribe to verification docs stream (farmer only)
    _verificationSub?.cancel();
    _verificationSub =
        _firestoreService.verificationDocsStream(uid).listen((firestoreDocs) {
      _verificationDocs.clear();
      _verificationDocs.addAll(firestoreDocs);
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
    for (final order in _orders) {
      if (order.status != 'Declined') {
        _totalEarnings += order.total;

        if (order.status == 'Pending') {
          _pendingPayments += order.total;
        } else {
          _transactions.add(EarningsTransaction(
              id: 'tx-${order.id}',
              orderNumber: order.orderNumber,
              date: order.timestamp,
              amount: order.total));
        }

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
        final monthStr = months[now.month - 1];
        monthlySums[monthStr] =
            (monthlySums[monthStr] ?? 0.0) + order.total;
        _thisMonth += order.total;
      }
    }

    _monthlyBars.clear();
    monthlySums.forEach((month, amount) {
      _monthlyBars.add(MonthlyBarData(
          month: month,
          amount: amount,
          heightRatio: amount / 2000.0,
          isHighlighted: true));
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
