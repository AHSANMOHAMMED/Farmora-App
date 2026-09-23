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
  double _totalEarnings = 458000.0;
  double _thisMonth = 120000.0;
  double _thisWeek = 35000.0;
  double _pendingPayments = 15000.0;

  final List<MonthlyBarData> _monthlyBars = [];
  final List<EarningsTransaction> _transactions = [];

  // Verification Documents
  final List<VerificationDoc> _verificationDocs = [];

  FarmoraState() {
    _loadInitialMockData();
  }

  void _loadInitialMockData() {
    _products.clear();
    _products.addAll([
      const Product(
        id: 'prod-1',
        name: 'Sweet Corn',
        category: 'Vegetables',
        location: 'Kurunegala',
        quantity: '50 kg available',
        unit: 'kg',
        price: 'LKR 3.00 / kg',
        pricePerUnit: 3.00,
        emoji: '🌽',
        imagePath: 'assets/images/heirloom_tomatoes.png',
        status: 'Active',
        isOrganic: false,
        description: '50 kg available',
      ),
      const Product(
        id: 'prod-2',
        name: 'Heirloom Tomatoes',
        category: 'Vegetables',
        location: 'Matale',
        quantity: '12 kg available',
        unit: 'kg',
        price: 'LKR 4.50 / kg',
        pricePerUnit: 4.50,
        emoji: '🍅',
        imagePath: 'assets/images/heirloom_tomatoes.png',
        status: 'Active',
        isOrganic: true,
        description: '12 kg available',
      ),
      const Product(
        id: 'prod-3',
        name: 'Organic Carrots',
        category: 'Vegetables',
        location: 'Anuradhapura',
        quantity: '0 kg available',
        unit: 'kg',
        price: 'LKR 2.10 / kg',
        pricePerUnit: 2.10,
        emoji: '🥕',
        imagePath: 'assets/images/nantes_carrots.png',
        status: 'Empty',
        isOrganic: true,
        description: '0 kg available',
      ),
      const Product(
        id: 'prod-4',
        name: 'Gala Apples',
        category: 'Fruits',
        location: 'Kandy',
        quantity: '120 kg available',
        unit: 'kg',
        price: 'LKR 1.80 / kg',
        pricePerUnit: 1.80,
        emoji: '🍎',
        imagePath: 'assets/images/heirloom_tomatoes.png',
        status: 'Active',
        isOrganic: false,
        description: '120 kg available',
      ),
      const Product(
        id: 'prod-5',
        name: 'Romaine Lettuce',
        category: 'Vegetables',
        location: 'Badulla',
        quantity: '200 heads',
        unit: 'ea',
        price: 'LKR 1.50 / ea',
        pricePerUnit: 1.50,
        emoji: '🥬',
        imagePath: 'assets/images/romaine_lettuce.png',
        status: 'Active',
        isOrganic: true,
        description: '200 heads available',
      ),
      const Product(
        id: 'prod-6',
        name: 'Black Beauty Eggplant',
        category: 'Vegetables',
        location: 'Matara',
        quantity: 'Restocking soon',
        unit: 'kg',
        price: 'LKR 3.75 / kg',
        pricePerUnit: 3.75,
        emoji: '🍆',
        imagePath: 'assets/images/black_beauty_eggplant.png',
        status: 'Empty',
        isOrganic: true,
        description: 'Restocking soon',
      ),
    ]);

    _orders.clear();
    _orders.addAll([
      const FarmoraOrder(
        id: 'ord-1',
        orderNumber: 'ORD-8924',
        title: 'Heirloom Tomatoes',
        productName: 'Heirloom Tomatoes',
        quantity: '50 kg',
        grade: 'Grade A',
        unitPrice: 'LKR 450.00',
        totalAmount: 'LKR 22,500.00',
        totalAmountNumber: 22500.00,
        buyerName: 'Green Grocery',
        buyerCompany: 'Green Grocery Store',
        buyerAvatar: 'assets/images/buyer_sarah.png',
        deliveryAddress: 'No. 42, Galle Road, Colombo 03',
        detail: '50 kg',
        status: 'Pending',
        progress: 0.0,
        color: Color(0xFF006E1C),
        timestamp: 'Oct 24, 09:30 AM',
        requestedDate: 'Oct 24, 2023',
        buyerIcon: Icons.storefront_rounded,
      ),
      const FarmoraOrder(
        id: 'ord-2',
        orderNumber: 'ORD-8925',
        title: 'Crisphead Lettuce',
        productName: 'Crisphead Lettuce',
        quantity: '20 Boxes',
        grade: 'Grade A',
        unitPrice: 'LKR 1,200.00',
        totalAmount: 'LKR 24,000.00',
        totalAmountNumber: 24000.00,
        buyerName: 'Valley Farm',
        buyerCompany: 'Valley Farm-to-Table',
        buyerAvatar: 'assets/images/buyer_sarah.png',
        deliveryAddress: 'No. 18, Negombo Road, Ja-Ela',
        detail: '20 Boxes',
        status: 'Pending',
        progress: 0.0,
        color: Color(0xFF006E1C),
        timestamp: 'Oct 24, 11:15 AM',
        requestedDate: 'Oct 24, 2023',
        buyerIcon: Icons.restaurant_rounded,
      ),
      const FarmoraOrder(
        id: 'ord-3',
        orderNumber: 'ORD-8928',
        title: 'Organic Carrots',
        productName: 'Organic Carrots',
        quantity: '100 kg',
        grade: 'Organic',
        unitPrice: 'LKR 600.00',
        totalAmount: 'LKR 60,000.00',
        totalAmountNumber: 60000.00,
        buyerName: 'Local Co-op',
        buyerCompany: 'Local Co-op \u2606',
        buyerAvatar: 'assets/images/buyer_sarah.png',
        deliveryAddress: 'No. 7, Temple Road, Kandy',
        detail: 'Please ensure stems are kept long if possible.',
        status: 'Pending',
        progress: 0.0,
        color: Color(0xFF006E1C),
        timestamp: 'Oct 24, 02:45 PM',
        requestedDate: 'Oct 24, 2023',
        buyerIcon: Icons.storefront_rounded,
      ),
      const FarmoraOrder(
        id: 'ord-4',
        orderNumber: 'ORD-8892',
        title: 'Heirloom Tomatoes',
        productName: 'Heirloom Tomatoes',
        quantity: '28 kg',
        grade: 'Organic',
        unitPrice: 'LKR 1,150.00',
        totalAmount: 'LKR 32,200.00',
        totalAmountNumber: 32200.00,
        buyerName: 'Fresh Market',
        buyerCompany: 'Fresh Market Co.',
        buyerAvatar: 'assets/images/buyer_sarah.png',
        deliveryAddress: 'No. 156, Duplication Road, Colombo 04',
        detail: '28 kg',
        status: 'Accepted',
        progress: 0.65,
        color: Color(0xFF006E1C),
        timestamp: 'Oct 23, 2024',
        requestedDate: 'Oct 23, 2024',
      ),
      const FarmoraOrder(
        id: 'ord-5',
        orderNumber: 'ORD-8890',
        title: 'Dinosaur Kale',
        productName: 'Dinosaur Kale',
        quantity: '42 bunches',
        grade: 'Conventional',
        unitPrice: 'LKR 800.00',
        totalAmount: 'LKR 33,600.00',
        totalAmountNumber: 33600.00,
        buyerName: 'Green Leaf',
        buyerCompany: 'Green Leaf Bistro',
        buyerAvatar: 'assets/images/buyer_sarah.png',
        deliveryAddress: 'No. 23, Peradeniya Road, Kandy',
        detail: '42 bunches',
        status: 'Delivered',
        progress: 1.0,
        color: Color(0xFF006E1C),
        timestamp: 'Jun 22, 2024',
        requestedDate: 'Jun 22, 2024',
      ),
      const FarmoraOrder(
        id: 'ord-6',
        orderNumber: 'ORD-8885',
        title: 'Nantes Carrots',
        productName: 'Nantes Carrots',
        quantity: '140 kg',
        grade: 'Organic',
        unitPrice: 'LKR 950.00',
        totalAmount: 'LKR 133,000.00',
        totalAmountNumber: 133000.00,
        buyerName: 'Local Fresh',
        buyerCompany: 'Local Fresh Market',
        buyerAvatar: 'assets/images/buyer_sarah.png',
        deliveryAddress: 'No. 88, Jaffna Road, Vavuniya',
        detail: '140 kg',
        status: 'Delivered',
        progress: 1.0,
        color: Color(0xFF006E1C),
        timestamp: 'Jun 15, 2024',
        requestedDate: 'Jun 15, 2024',
      ),
      const FarmoraOrder(
        id: 'ord-7',
        orderNumber: 'ORD-8881',
        title: 'Romaine Lettuce',
        productName: 'Romaine Lettuce',
        quantity: '40 heads',
        grade: 'Organic',
        unitPrice: 'LKR 700.00',
        totalAmount: 'LKR 28,000.00',
        totalAmountNumber: 28000.00,
        buyerName: 'Bistro 44',
        buyerCompany: 'Bistro 44',
        buyerAvatar: 'assets/images/buyer_sarah.png',
        deliveryAddress: 'No. 5, Beach Road, Galle',
        detail: '40 heads',
        status: 'Delivered',
        progress: 1.0,
        color: Color(0xFF006E1C),
        timestamp: 'Jun 10, 2024',
        requestedDate: 'Jun 10, 2024',
      ),
    ]);

    _monthlyBars.clear();
    _monthlyBars.addAll([
      const MonthlyBarData(month: 'Jan', amount: 80000, heightRatio: 0.45, isHighlighted: false),
      const MonthlyBarData(month: 'Feb', amount: 95000, heightRatio: 0.55, isHighlighted: false),
      const MonthlyBarData(month: 'Mar', amount: 60000, heightRatio: 0.35, isHighlighted: false),
      const MonthlyBarData(month: 'Apr', amount: 70000, heightRatio: 0.40, isHighlighted: false),
      const MonthlyBarData(month: 'May', amount: 110000, heightRatio: 0.75, isHighlighted: false),
      const MonthlyBarData(month: 'Jun', amount: 120000, heightRatio: 0.90, isHighlighted: true),
    ]);

    _transactions.clear();
    _transactions.addAll([
      const EarningsTransaction(id: 'tx-1', orderNumber: '#8921', date: 'June 24, 2024', amount: 24000.00, status: 'Completed'),
      const EarningsTransaction(id: 'tx-2', orderNumber: '#8918', date: 'June 22, 2024', amount: 8550.00, status: 'Completed'),
      const EarningsTransaction(id: 'tx-3', orderNumber: '#8915', date: 'June 21, 2024', amount: 15000.00, status: 'Pending'),
      const EarningsTransaction(id: 'tx-4', orderNumber: '#8890', date: 'June 15, 2024', amount: 42000.00, status: 'Completed'),
    ]);
  }

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
    // Always add to local list so it works in demo mode too
    _products.add(p);
    notifyListeners();
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
    // Update local state (works in demo mode too)
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: 'Accepted',
        progress: 0.6,
      );
      _recalculateStats();
      notifyListeners();
    }
    if (_currentUserId.isNotEmpty) {
      _firestoreService.updateOrderStatus(orderId, 'Accepted', 0.6);
    }
  }

  void completeOrder(String orderId) {
    // Update local state (works in demo mode too)
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: 'Delivered',
        progress: 1.0,
      );
      _recalculateStats();
      notifyListeners();
    }
    if (_currentUserId.isNotEmpty) {
      _firestoreService.updateOrderStatus(orderId, 'Delivered', 1.0);
    }
  }

  void declineOrder(String orderId) {
    // Update local state (works in demo mode too)
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: 'Declined',
        progress: 0.0,
      );
      _recalculateStats();
      notifyListeners();
    }
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
    _profileLoaded = false;
    disposeFirestoreSubscriptions();

    // Load user profile and set role.
    // Retry briefly: right after sign-in the Firestore client may still hold a
    // stale (unauthenticated) token, which causes a spurious PERMISSION_DENIED.
    const maxAttempts = 4;
    Map<String, dynamic>? profile;
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        profile = await _loadUserProfile(uid);
        lastError = null;
        break;
      } catch (error) {
        lastError = error;
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 600 * attempt));
        }
      }
    }

    if (lastError != null) {
      // Profile read genuinely failed — keep session but fall back to demo data
      // instead of signing the user out on a transient permissions race.
      debugPrint('FarmoraState.initFromFirestore profile load failed: $lastError');
      _profileLoaded = true;
      notifyListeners();
      return;
    }

    try {
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

    // Subscribe to products stream (merge with mock data, never clear)
    _productsSub?.cancel();
    final productsStream = role == Role.farmer
        ? _firestoreService.productsByFarmerStream(uid)
        : _firestoreService.productsStream();
    _productsSub = productsStream.listen((firestoreProducts) {
      if (firestoreProducts.isNotEmpty) {
        // Merge: add Firestore products that don't already exist by id
        for (final fp in firestoreProducts) {
          if (!_products.any((p) => p.id == fp.id)) {
            _products.add(fp);
          }
        }
        notifyListeners();
      }
      // When empty, keep mock data untouched
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

    // Subscribe to orders stream (merge with mock data, never clear)
    _ordersSub?.cancel();
    final ordersStream = switch (role) {
      Role.admin => _firestoreService.ordersStream(),
      Role.farmer => _firestoreService.ordersByFarmerStream(uid),
      Role.buyer => _firestoreService.ordersByBuyerStream(uid),
      Role.transporter => _firestoreService.ordersByTransporterStream(uid),
    };
    _ordersSub = ordersStream.listen((firestoreOrders) {
      if (firestoreOrders.isNotEmpty) {
        for (final fo in firestoreOrders) {
          if (!_orders.any((o) => o.id == fo.id)) {
            _orders.add(fo);
          }
        }
        _recalculateStats();
        notifyListeners();
      }
      // When empty, keep mock data untouched
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
    // Don't recalculate if no orders — keep mock data
    if (_orders.isEmpty) return;
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
