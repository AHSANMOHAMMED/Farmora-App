import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
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
  String displayName = '';
  String? profilePhotoUrl;
  String? userEmail;

  // Stream subscriptions for real-time Firestore sync
  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<FarmoraOrder>>? _ordersSub;
  StreamSubscription<List<TransportJob>>? _jobsSub;
  StreamSubscription<List<VerificationDoc>>? _verificationSub;
  StreamSubscription<List<Map<String, dynamic>>>? _usersSub;
  bool signedIn = false;
  String language = 'English';
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

  List<Product> get filteredProducts {
    return _products.where((p) {
      final matchesSearch = searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == 'All' ||
          p.category.toLowerCase() == selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Product> get activeProducts =>
      _products.where((p) => p.isActive).toList();

  List<FarmoraOrder> get pendingOrders =>
      _orders.where((o) => o.isPending).toList();
  List<FarmoraOrder> get acceptedOrders =>
      _orders.where((o) => o.isAccepted || o.status == 'In transit').toList();
  List<FarmoraOrder> get completedOrders =>
      _orders.where((o) => o.isCompleted).toList();

  // ── Cart (Buyer) ─────────────────────────────────────────
  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get cartItemCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal => _cartItems.fold(
      0.0, (sum, item) => sum + (item.product.pricePerUnit * item.quantity));

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

  void placeOrder() {
    if (_cartItems.isEmpty) return;
    if (_currentUserId.isNotEmpty) {
      // Prices and stock are reloaded and committed by the trusted backend.
      for (final item in _cartItems) {
        _firestoreService.createSecureOrder(
          productId: item.product.id,
          quantity: item.quantity,
        );
      }
      _cartItems.clear();
      notifyListeners();
      return;
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
            '\$${(item.product.pricePerUnit * item.quantity).toStringAsFixed(2)}',
        totalAmountNumber: item.product.pricePerUnit * item.quantity,
        buyerName: 'You',
        buyerCompany: 'Your Order',
        buyerAvatar: 'assets/images/buyer_sarah.png',
        buyerPhone: '',
        deliveryAddress: 'Delivery address TBD',
        detail:
            '${item.quantity} ${item.product.unit} · \$${(item.product.pricePerUnit * item.quantity).toStringAsFixed(2)}',
        status: 'Pending',
        progress: 0.1,
        color: const Color(0xFF3478C5),
        timestamp: 'Just now',
        requestedDate: 'Today',
        buyerIcon: Icons.shopping_cart_rounded,
      );
      if (_currentUserId.isNotEmpty) {
        _firestoreService.addOrder(order);
      }
    }
    _cartItems.clear();
    notifyListeners();
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

  Future<void> signOut() async {
    disposeFirestoreSubscriptions();
    await _authService.signOut();
    signedIn = false;
    _currentUserId = '';
    displayName = '';
    profilePhotoUrl = null;
    userEmail = null;
    notifyListeners();
  }

  void setRole(Role r) {
    role = r;
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
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
    }
  }

  void add(Product p) => addProduct(p);

  void toggleProductStock(String id) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final current = _products[index];
      final newStatus = current.status == 'Active' ? 'Empty' : 'Active';
      _products[index] = current.copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
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

  Future<void> seedDatabase() async {
    await _firestoreService.seedDatabase();
  }

  /// Initialize Firestore streams after user signs in.
  /// Loads data from Firestore in real-time while keeping mock data as fallback.
  Future<void> initFromFirestore(String uid) async {
    _currentUserId = uid;
    disposeFirestoreSubscriptions();

    try {
      final profile = await _loadUserProfile(uid);
      if (profile == null) return;
      final firebaseUser = FirebaseAuth.instance.currentUser;
      displayName = (profile['displayName'] ??
              profile['name'] ??
              firebaseUser?.displayName ??
              'Farmora User')
          .toString();
      profilePhotoUrl =
          (profile['photoUrl'] as String?) ?? firebaseUser?.photoURL;
      userEmail = (profile['email'] as String?) ?? firebaseUser?.email;
      final roleStr = profile['role'] as String?;
      if (roleStr != null) {
        role = Role.values.firstWhere((value) => value.name == roleStr);
      }
      final lang = profile['language'] as String?;
      if (lang != null) language = lang;
      notifyListeners();
    } catch (error) {
      debugPrint('Could not load user profile: $error');
      return;
    }

    _productsSub = _firestoreService.productsStream().listen(
      (items) {
        _products
          ..clear()
          ..addAll(items);
        notifyListeners();
      },
      onError: (Object error) => debugPrint('Products stream: $error'),
    );

    Stream<List<FarmoraOrder>>? orders;
    Stream<List<TransportJob>>? jobs;
    switch (role) {
      case Role.farmer:
        orders = _firestoreService.ordersByFarmerStream(uid);
        jobs = _firestoreService.jobsByCreatorStream(uid);
        _verificationSub = _firestoreService.verificationDocsStream(uid).listen(
          (items) {
            _verificationDocs
              ..clear()
              ..addAll(items);
            notifyListeners();
          },
          onError: (Object error) => debugPrint('Verification stream: $error'),
        );
      case Role.buyer:
        orders = _firestoreService.ordersByBuyerStream(uid);
        jobs = _firestoreService.jobsByCreatorStream(uid);
      case Role.transporter:
        orders = _firestoreService.ordersByTransporterStream(uid);
        jobs = _firestoreService.jobsByTransporterStream(uid);
      case Role.admin:
        orders = _firestoreService.ordersStream();
        jobs = _firestoreService.jobsStream();
        _usersSub = _firestoreService.usersStream().listen(
          (items) {
            _users
              ..clear()
              ..addAll(items);
            notifyListeners();
          },
          onError: (Object error) => debugPrint('Users stream: $error'),
        );
    }

    _ordersSub = orders.listen(
      (items) {
        _orders
          ..clear()
          ..addAll(items);
        _recalculateStats();
        notifyListeners();
      },
      onError: (Object error) => debugPrint('Orders stream: $error'),
    );
    _jobsSub = jobs.listen(
      (items) {
        _jobs
          ..clear()
          ..addAll(items);
        notifyListeners();
      },
      onError: (Object error) => debugPrint('Jobs stream: $error'),
    );
  }

  /// Cancel all Firestore subscriptions
  void disposeFirestoreSubscriptions() {
    _productsSub?.cancel();
    _ordersSub?.cancel();
    _jobsSub?.cancel();
    _verificationSub?.cancel();
    _usersSub?.cancel();
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
        _totalEarnings += order.totalAmountNumber;

        if (order.status == 'Pending') {
          _pendingPayments += order.totalAmountNumber;
        } else {
          _transactions.add(EarningsTransaction(
              id: 'tx-${order.id}',
              orderNumber: order.orderNumber,
              date: order.timestamp,
              amount: order.totalAmountNumber));
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
            (monthlySums[monthStr] ?? 0.0) + order.totalAmountNumber;
        _thisMonth += order.totalAmountNumber;
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
      VerificationStatus? status}) {
    final index = _verificationDocs.indexWhere((d) => d.id == docId);
    if (index != -1) {
      _verificationDocs[index] = _verificationDocs[index].copyWith(
        fileName: fileName,
        fileSizeInfo: fileSizeInfo,
        imagePreview: imagePreview,
        status: status ?? VerificationStatus.approved,
        errorMessage: null,
      );
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
    } catch (e) {
      authError = e.toString();
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
    } catch (e) {
      authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPhoneOtpRegistration({
    required String code,
    required String name,
    required String phone,
    required Role role,
    String? district,
  }) async {
    authError = null;
    try {
      final result = await _authService.registerWithPhoneOtp(
        code: code,
        name: name,
        phone: phone,
        role: role,
        district: district,
      );
      this.role = result.role;
      signedIn = true;
      notifyListeners();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) initFromFirestore(user.uid);
      return true;
    } catch (e) {
      authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    try {
      profilePhotoUrl = await _firestoreService.uploadProfilePhoto(
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
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
