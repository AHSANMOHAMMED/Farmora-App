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
  bool signedIn = false;
  String language = 'English';
  Role role = Role.farmer;

  // Search & Filter State
  String searchQuery = '';
  String selectedCategory = 'All';

  // Products
  final List<Product> _products = [
    const Product(
      id: 'prod-1',
      name: 'Heirloom Tomatoes',
      category: 'Vegetables',
      location: 'Nuwara Eliya',
      quantity: '50 kg available',
      unit: 'kg',
      price: '\$4.50 / kg',
      pricePerUnit: 4.50,
      emoji: '🍅',
      color: Color(0xFFFFE1DA),
      imagePath: 'assets/images/heirloom_tomatoes.png',
      status: 'Active',
      isOrganic: true,
      description: 'Freshly harvested, vibrant red organic tomatoes with natural sweetness.',
    ),
    const Product(
      id: 'prod-2',
      name: 'Dinosaur Kale',
      category: 'Vegetables',
      location: 'Ambalantota',
      quantity: '120 bunches',
      unit: 'bunches',
      price: '\$2.00 / ea',
      pricePerUnit: 2.00,
      emoji: '🥬',
      color: Color(0xFFE8F5E9),
      imagePath: 'assets/images/dinosaur_kale.png',
      status: 'Active',
      isOrganic: false,
      description: 'Crisp, dark green kale leaves rich in nutrients, harvested fresh daily.',
    ),
    const Product(
      id: 'prod-3',
      name: 'Black Beauty Eggplant',
      category: 'Vegetables',
      location: 'Kandy',
      quantity: 'Restocking soon',
      unit: 'kg',
      price: '\$3.75 / kg',
      pricePerUnit: 3.75,
      emoji: '🍆',
      color: Color(0xFFF3E5F5),
      imagePath: 'assets/images/black_beauty_eggplant.png',
      status: 'Empty',
      isOrganic: true,
      description: 'Glossy, plump organic eggplants with firm flesh, perfect for roasting.',
    ),
    const Product(
      id: 'prod-4',
      name: 'Nantes Carrots',
      category: 'Vegetables',
      location: 'Bandarawela',
      quantity: '200 kg available',
      unit: 'kg',
      price: '\$1.50 / kg',
      pricePerUnit: 1.50,
      emoji: '🥕',
      color: Color(0xFFFFF3E0),
      imagePath: 'assets/images/nantes_carrots.png',
      status: 'Active',
      isOrganic: true,
      description: 'Bright orange sweet carrots pulled freshly from nutrient-rich dark soil.',
    ),
  ];

  // Orders
  final List<FarmoraOrder> _orders = [
    const FarmoraOrder(
      id: 'ord-1042-b',
      orderNumber: '#1042-B',
      title: '120 Crates Organic Fuji Apples',
      productName: 'Organic Fuji Apples',
      quantity: '120 Crates (40 lbs ea)',
      grade: 'Grade A Premium',
      unitPrice: '\$45.00',
      totalAmount: '\$5,400.00',
      totalAmountNumber: 5400.0,
      buyerName: 'Sarah Jenkins',
      buyerCompany: 'Fresh Market Co.',
      buyerAvatar: 'assets/images/buyer_sarah.png',
      buyerPhone: '+1 (555) 234-5678',
      deliveryAddress: '450 West End Ave,\nDistribution Center Bay 4',
      detail: '120 Crates · \$5,400.00 · Requested for Oct 24, 2024',
      status: 'Pending',
      progress: 0.25,
      color: Color(0xFF3478C5),
      timestamp: 'Today, 09:15 AM',
      requestedDate: 'Oct 24, 2024',
      buyerIcon: Icons.storefront_rounded,
    ),
    const FarmoraOrder(
      id: 'ord-8892',
      orderNumber: '#8892',
      title: 'Cherry Tomatoes',
      productName: 'Cherry Tomatoes',
      quantity: '25 kg • Grade A',
      grade: 'Grade A',
      unitPrice: '\$5.00',
      totalAmount: '\$125.00',
      totalAmountNumber: 125.0,
      buyerName: 'Local Fresh Market',
      buyerCompany: 'Local Fresh Market',
      buyerAvatar: 'assets/images/buyer_sarah.png',
      buyerPhone: '+1 (555) 890-1234',
      deliveryAddress: '12 Main Street, Central Plaza',
      detail: '25 kg · \$125.00 · Today',
      status: 'Pending',
      progress: 0.3,
      color: Color(0xFF3478C5),
      timestamp: 'Today, 08:45 AM',
      requestedDate: 'Today',
      buyerIcon: Icons.storefront_rounded,
    ),
    const FarmoraOrder(
      id: 'ord-8890',
      orderNumber: '#8890',
      title: 'Romaine Lettuce',
      productName: 'Romaine Lettuce',
      quantity: '50 heads • Organic',
      grade: 'Organic',
      unitPrice: '\$1.51',
      totalAmount: '\$75.50',
      totalAmountNumber: 75.5,
      buyerName: 'Green Leaf Bistro',
      buyerCompany: 'Green Leaf Bistro',
      buyerAvatar: 'assets/images/buyer_sarah.png',
      buyerPhone: '+1 (555) 345-6789',
      deliveryAddress: '88 Culinary Ave, Downtown',
      detail: '50 heads · \$75.50 · Yesterday',
      status: 'Pending',
      progress: 0.3,
      color: Color(0xFF3478C5),
      timestamp: 'Yesterday, 14:20 PM',
      requestedDate: 'Yesterday',
      buyerIcon: Icons.restaurant_rounded,
    ),
    const FarmoraOrder(
      id: 'ord-8885',
      orderNumber: '#8885',
      title: 'Nantes Carrots',
      productName: 'Nantes Carrots',
      quantity: '140 kg • Grade A',
      grade: 'Grade A',
      unitPrice: '\$1.50',
      totalAmount: '\$210.00',
      totalAmountNumber: 210.0,
      buyerName: 'Organic Valley Co.',
      buyerCompany: 'Organic Valley Co.',
      buyerAvatar: 'assets/images/buyer_sarah.png',
      buyerPhone: '+1 (555) 456-7890',
      deliveryAddress: '23 Valley Road',
      detail: '140 kg · \$210.00 · May 18',
      status: 'Delivered',
      progress: 1.0,
      color: Color(0xFF1F7A4D),
      timestamp: 'May 18, 2024',
      requestedDate: 'May 18, 2024',
      buyerIcon: Icons.storefront_rounded,
    ),
    const FarmoraOrder(
      id: 'ord-8881',
      orderNumber: '#8881',
      title: 'Heirloom Tomatoes',
      productName: 'Heirloom Tomatoes',
      quantity: '15 kg • Organic',
      grade: 'Organic',
      unitPrice: '\$4.33',
      totalAmount: '\$65.00',
      totalAmountNumber: 65.0,
      buyerName: 'Urban Eatery',
      buyerCompany: 'Urban Eatery',
      buyerAvatar: 'assets/images/buyer_sarah.png',
      buyerPhone: '+1 (555) 567-8901',
      detail: '15 kg · \$65.00 · May 15',
      status: 'Delivered',
      progress: 1.0,
      color: Color(0xFF1F7A4D),
      timestamp: 'May 15, 2024',
      requestedDate: 'May 15, 2024',
      buyerIcon: Icons.restaurant_rounded,
    ),
  ];

  // Transport Jobs
  final List<TransportJob> _jobs = [
    const TransportJob(
      id: 'job-1',
      title: 'Coconut harvest',
      route: 'Kaduwela → Colombo',
      detail: '250 kg · Pickup today, 10:30 AM',
      fee: 'LKR 3,500',
    ),
    const TransportJob(
      id: 'job-2',
      title: 'Fresh vegetables',
      route: 'Nuwara Eliya → Kandy',
      detail: '80 kg · Pickup tomorrow, 7:00 AM',
      fee: 'LKR 5,200',
    ),
  ];

  // Earnings Stats
  double _totalEarnings = 4580.00;
  double _thisMonth = 1200.00;
  double _thisWeek = 350.00;
  double _pendingPayments = 150.00;

  final List<MonthlyBarData> _monthlyBars = [
    const MonthlyBarData(month: 'Jan', amount: 400, heightRatio: 0.30),
    const MonthlyBarData(month: 'Feb', amount: 550, heightRatio: 0.45),
    const MonthlyBarData(month: 'Mar', amount: 700, heightRatio: 0.60),
    const MonthlyBarData(month: 'Apr', amount: 600, heightRatio: 0.50),
    const MonthlyBarData(month: 'May', amount: 1200, heightRatio: 0.85, isHighlighted: true),
  ];

  final List<EarningsTransaction> _transactions = [
    const EarningsTransaction(id: 'tx-1', orderNumber: '#8892', date: 'May 24, 2024', amount: 125.00),
    const EarningsTransaction(id: 'tx-2', orderNumber: '#8890', date: 'May 21, 2024', amount: 85.50),
    const EarningsTransaction(id: 'tx-3', orderNumber: '#8885', date: 'May 18, 2024', amount: 210.00),
    const EarningsTransaction(id: 'tx-4', orderNumber: '#8881', date: 'May 15, 2024', amount: 65.00),
  ];

  // Verification Documents
  final List<VerificationDoc> _verificationDocs = [
    const VerificationDoc(
      id: 'doc-id',
      title: 'National ID',
      description: 'Clear photo of your government-issued ID. Front and back required.',
      icon: Icons.badge_outlined,
      status: VerificationStatus.pending,
      hasFrontBack: true,
    ),
    const VerificationDoc(
      id: 'doc-farm',
      title: 'Farm Document',
      description: 'Proof of land ownership or lease agreement.',
      icon: Icons.description_outlined,
      status: VerificationStatus.approved,
      fileName: 'deed_of_lease_2024.pdf',
      fileSizeInfo: '2.4 MB • Uploaded Oct 12',
    ),
    const VerificationDoc(
      id: 'doc-license',
      title: 'Vehicle License',
      description: 'Current registration for transport vehicle.',
      icon: Icons.directions_car_outlined,
      status: VerificationStatus.pending,
    ),
    const VerificationDoc(
      id: 'doc-vehicle-photo',
      title: 'Vehicle Photo',
      description: 'Clear photo showing vehicle license plate.',
      icon: Icons.local_shipping_outlined,
      status: VerificationStatus.rejected,
      errorMessage: 'Image was too blurry. Please upload a clear photo showing the license plate.',
      imagePreview: 'assets/images/vehicle_blurry.png',
    ),
  ];

  // Getters
  List<Product> get products => List.unmodifiable(_products);
  List<FarmoraOrder> get orders => List.unmodifiable(_orders);
  List<TransportJob> get jobs => List.unmodifiable(_jobs);
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
      _orders.insert(0, order);
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
    _products.insert(0, p);
    notifyListeners();
    // Sync to Firestore if user is authenticated
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
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      _orders[index] = order.copyWith(
        status: 'Accepted',
        progress: 0.6,
        color: const Color(0xFF1F7A4D),
      );
      // Sync to Firestore
      if (_currentUserId.isNotEmpty) {
        _firestoreService.updateOrderStatus(orderId, 'Accepted', 0.6);
      }
      _thisMonth += order.totalAmountNumber;
      _thisWeek += order.totalAmountNumber;
      _totalEarnings += order.totalAmountNumber;
      _transactions.insert(
        0,
        EarningsTransaction(
          id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
          orderNumber: order.orderNumber,
          date: 'Just now',
          amount: order.totalAmountNumber,
        ),
      );
      notifyListeners();
    }
  }

  void declineOrder(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      _orders[index] = order.copyWith(
        status: 'Declined',
        progress: 0.0,
        color: const Color(0xFFBA1A1A),
      );
      // Sync to Firestore
      if (_currentUserId.isNotEmpty) {
        _firestoreService.updateOrderStatus(orderId, 'Declined', 0.0);
      }
      notifyListeners();
    }
  }

  void acceptJob(String jobId) {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      _jobs[index] = _jobs[index].copyWith(accepted: true);
      notifyListeners();
    }
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
      if (firestoreProducts.isNotEmpty) {
        _products.clear(); _products.addAll(firestoreProducts);
        notifyListeners();
      }
    });

    // Subscribe to orders stream
    _ordersSub?.cancel();
    _ordersSub = _firestoreService.ordersStream().listen((firestoreOrders) {
      if (firestoreOrders.isNotEmpty) {
        _orders.clear(); _orders.addAll(firestoreOrders);
        notifyListeners();
      }
    });

    // Subscribe to transport jobs stream
    _jobsSub?.cancel();
    _jobsSub = _firestoreService.jobsStream().listen((firestoreJobs) {
      if (firestoreJobs.isNotEmpty) {
        _jobs.clear(); _jobs.addAll(firestoreJobs);
        notifyListeners();
      }
    });

    // Subscribe to verification docs stream (farmer only)
    _verificationSub?.cancel();
    _verificationSub = _firestoreService.verificationDocsStream(uid).listen((firestoreDocs) {
      if (firestoreDocs.isNotEmpty) {
        _verificationDocs.clear(); _verificationDocs.addAll(firestoreDocs);
        notifyListeners();
      }
    });
  }

  /// Cancel all Firestore subscriptions
  void disposeFirestoreSubscriptions() {
    _productsSub?.cancel();
    _ordersSub?.cancel();
    _jobsSub?.cancel();
    _verificationSub?.cancel();
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
    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.exists ? doc.data() : null;
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
