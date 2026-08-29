import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _authService = FirebaseAuthService();
  final _firestoreService = kajana_service.FirestoreService();
  String _currentUserId = '';
  String get currentUserId => _currentUserId;

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
  List<EarningsTransaction> get transactions => List.unmodifiable(_transactions);
  List<VerificationDoc> get verificationDocs => List.unmodifiable(_verificationDocs);

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

  List<Product> get activeProducts => _products.where((p) => p.isActive).toList();

  List<FarmoraOrder> get pendingOrders => _orders.where((o) => o.isPending).toList();
  List<FarmoraOrder> get acceptedOrders => _orders.where((o) => o.isAccepted || o.status == 'In transit').toList();
  List<FarmoraOrder> get completedOrders => _orders.where((o) => o.isCompleted).toList();

  // ── Cart (Buyer) ─────────────────────────────────────────
  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get cartItemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal => _cartItems.fold(0.0, (sum, item) => sum + (item.product.pricePerUnit * item.quantity));

  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere((c) => c.product.id == product.id);
    if (existingIndex != -1) {
      final existing = _cartItems[existingIndex];
      _cartItems[existingIndex] = existing.copyWith(quantity: existing.quantity + quantity);
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
    for (final item in _cartItems) {
      final order = FarmoraOrder(
        id: 'ord-${DateTime.now().millisecondsSinceEpoch}-${item.product.id}',
        orderNumber: '#${_orders.length + 1001}',
        title: item.product.name,
        productName: item.product.name,
        quantity: '${item.quantity} ${item.product.unit}',
        grade: item.product.isOrganic ? 'Organic' : 'Grade A',
        unitPrice: item.product.price,
        totalAmount: '\$${(item.product.pricePerUnit * item.quantity).toStringAsFixed(2)}',
        totalAmountNumber: item.product.pricePerUnit * item.quantity,
        buyerName: 'You',
        buyerCompany: 'Your Order',
        buyerAvatar: 'assets/images/buyer_sarah.png',
        buyerPhone: '',
        deliveryAddress: 'Delivery address TBD',
        detail: '${item.quantity} ${item.product.unit} · \$${(item.product.pricePerUnit * item.quantity).toStringAsFixed(2)}',
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

  void signOut() {
    signedIn = false;
    _currentUserId = '';
    disposeFirestoreSubscriptions();
    _authService.signOut();
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
      _firestoreService.addProduct(p, _currentUserId);
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
    // Currently no Firebase hook for accepting transport jobs yet, adding it to UI mockup
    // _firestoreService.updateJobStatus(jobId, 'Accepted');
  }

  /// Initialize Firestore streams after user signs in.
  /// Loads data from Firestore in real-time while keeping mock data as fallback.
  void initFromFirestore(String uid) {
    _currentUserId = uid;

    // Load user profile and set role
    _loadUserProfile(uid).then((profile) {
      if (profile != null) {
        final roleStr = profile['role'] as String?;
        if (roleStr != null) {
          try {
            role = Role.values.firstWhere((r) => r.name == roleStr);
          } catch (_) {}
        }
        final lang = profile['language'] as String?;
        if (lang != null) language = lang;
        notifyListeners();
      }
    });

    // Subscribe to products stream
    _productsSub?.cancel();
    _productsSub = _firestoreService.productsStream().listen((firestoreProducts) {
      _products.clear();
      _products.addAll(firestoreProducts);
      notifyListeners();
    });

    // Subscribe to users stream
    _usersSub?.cancel();
    _usersSub = _firestoreService.usersStream().listen((firestoreUsers) {
      _users.clear();
      _users.addAll(firestoreUsers);
      notifyListeners();
    });

    // Subscribe to orders stream
    _ordersSub?.cancel();
    _ordersSub = _firestoreService.ordersStream().listen((firestoreOrders) {
      _orders.clear();
      _orders.addAll(firestoreOrders);
      _recalculateStats();
      notifyListeners();
    });

    // Subscribe to transport jobs stream
    _jobsSub?.cancel();
    _jobsSub = _firestoreService.jobsStream().listen((firestoreJobs) {
      _jobs.clear();
      _jobs.addAll(firestoreJobs);
      notifyListeners();
    });

    // Subscribe to verification docs stream (farmer only)
    _verificationSub?.cancel();
    _verificationSub = _firestoreService.verificationDocsStream(uid).listen((firestoreDocs) {
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
            amount: order.totalAmountNumber
          ));
        }

        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        final monthStr = months[now.month - 1];
        monthlySums[monthStr] = (monthlySums[monthStr] ?? 0.0) + order.totalAmountNumber;
        _thisMonth += order.totalAmountNumber;
      }
    }
    
    _monthlyBars.clear();
    monthlySums.forEach((month, amount) {
      _monthlyBars.add(MonthlyBarData(month: month, amount: amount, heightRatio: amount / 2000.0, isHighlighted: true));
    });
  }

  void updateVerificationDoc(String docId, {String? fileName, String? fileSizeInfo, String? imagePreview, VerificationStatus? status}) {
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

  Future<bool> signInWithBackend({required String phone, required String password}) async {
    authError = null;
    try {
      final result = await _authService.login(phone: phone, password: password);
      role = result.role;
      signedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithBackend({required String name, required String phone, required String password, required Role role, String? district}) async {
    authError = null;
    try {
      final result = await _authService.register(name: name, phone: phone, password: password, role: role, district: district);
      this.role = result.role;
      signedIn = true;
      notifyListeners();
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
      return true;
    } catch (e) {
      authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithGoogle({required String name, required String phone, required Role role, String? district}) async {
    authError = null;
    try {
      final result = await _authService.registerWithGoogle(name: name, phone: phone, role: role);
      this.role = result.role;
      signedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      authError = e.toString();
      notifyListeners();
      return false;
    }
  }
}
