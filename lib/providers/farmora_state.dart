import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/transport_job.dart';
import '../models/cart_item.dart';
import '../models/verification_model.dart';
import '../models/monthly_bar.dart';
import '../models/transaction.dart';

class FarmoraState extends ChangeNotifier {
  bool signedIn = false;
  String language = 'English';
  Role role = Role.buyer;

  final List<Product> _products = [
    const Product(id: 'prod-1', name: 'Organic Tomatoes', category: 'Vegetables', location: 'Nuwara Eliya', quantity: '20 kg available', price: 'LKR 420 / kg', emoji: '🍅', color: Color(0xffffe1da)),
    const Product(id: 'prod-2', name: 'Cavendish Bananas', category: 'Fruits', location: 'Ambalantota', quantity: '45 kg available', price: 'LKR 280 / kg', emoji: '🍌', color: Color(0xfffff0c2)),
    const Product(id: 'prod-3', name: 'Gotukola Bunches', category: 'Herbs', location: 'Kandy', quantity: '80 bunches', price: 'LKR 90 / bunch', emoji: '🌿', color: Color(0xffddf1dd)),
    const Product(id: 'prod-4', name: 'Green Chilli', category: 'Vegetables', location: 'Dambulla', quantity: '15 kg available', price: 'LKR 520 / kg', emoji: '🌶️', color: Color(0xffe8f5e9)),
    const Product(id: 'prod-5', name: 'Fresh Carrots', category: 'Vegetables', location: 'Badulla', quantity: '30 kg available', price: 'LKR 340 / kg', emoji: '🥕', color: Color(0xfffff0c2)),
    const Product(id: 'prod-6', name: 'Cabbage Heads', category: 'Vegetables', location: 'Kandy', quantity: '50 heads available', price: 'LKR 150 / kg', emoji: '🥬', color: Color(0xffddf1dd)),
    const Product(id: 'prod-7', name: 'Brinjal (Eggplant)', category: 'Vegetables', location: 'Jaffna', quantity: '25 kg available', price: 'LKR 280 / kg', emoji: '🍆', color: Color(0xffe8eaf6)),
    const Product(id: 'prod-8', name: 'King Coconut', category: 'Fruits', location: 'Gampaha', quantity: '100 units available', price: 'LKR 50 / unit', emoji: '🥥', color: Color(0xfffff8e1)),
    const Product(id: 'prod-9', name: 'Green Beans', category: 'Vegetables', location: 'Nuwara Eliya', quantity: '18 kg available', price: 'LKR 320 / kg', emoji: '🫘', color: Color(0xffe8f5e9)),
    const Product(id: 'prod-10', name: 'Curry Leaves', category: 'Herbs', location: 'Matale', quantity: '200 bunches', price: 'LKR 40 / bunch', emoji: '🍃', color: Color(0xffe8f5e9)),
  ];

  final List<FarmoraOrder> _orders = [
    const FarmoraOrder(id: 'ord-1', title: 'Organic Tomatoes', detail: '20 kg · LKR 8,400 · Today', status: 'In transit', progress: 0.68, color: Color(0xff3478c5), productName: 'Organic Tomatoes', buyerName: 'Alex Perera', orderNumber: '#ORD-001', quantity: '20 kg', requestedDate: '2026-08-29'),
    const FarmoraOrder(id: 'ord-2', title: 'Cavendish Bananas', detail: '15 kg · LKR 4,200 · Yesterday', status: 'Delivered', progress: 1.0, color: Color(0xff1f7a4d), productName: 'Cavendish Bananas', buyerName: 'Sara Kumari', orderNumber: '#ORD-002', quantity: '15 kg', requestedDate: '2026-08-27'),
    const FarmoraOrder(id: 'ord-3', title: 'Green Chilli', detail: '10 kg · LKR 5,200 · 2 days ago', status: 'Pending', progress: 0.0, color: Color(0xffe67e22), productName: 'Green Chilli', buyerName: 'Mike Fernando', orderNumber: '#ORD-003', quantity: '10 kg', requestedDate: '2026-08-26'),
    const FarmoraOrder(id: 'ord-4', title: 'Fresh Carrots', detail: '25 kg · LKR 8,500 · 3 days ago', status: 'Confirmed', progress: 0.3, color: Color(0xff1abc9c), productName: 'Fresh Carrots', buyerName: 'Lisa Jayasinghe', orderNumber: '#ORD-004', quantity: '25 kg', requestedDate: '2026-08-25'),
    const FarmoraOrder(id: 'ord-5', title: 'Gotukola Bunches', detail: '50 bunches · LKR 4,500 · Last week', status: 'Delivered', progress: 1.0, color: Color(0xff1f7a4d), productName: 'Gotukola Bunches', buyerName: 'Nimal Perera', orderNumber: '#ORD-005', quantity: '50 bunches', requestedDate: '2026-08-22'),
  ];

  final List<TransportJob> _jobs = [
    const TransportJob(id: 'job-1', title: 'Coconut harvest', route: 'Kaduwela → Colombo', detail: '250 kg · Pickup today, 10:30 AM', fee: 'LKR 3,500'),
    const TransportJob(id: 'job-2', title: 'Fresh vegetables', route: 'Nuwara Eliya → Kandy', detail: '80 kg · Pickup tomorrow, 7:00 AM', fee: 'LKR 5,200'),
  ];

  // ── Cart ──────────────────────────────────────────────
  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get cartItemCount => _cartItems.fold(0, (sum, c) => sum + c.quantity);
  String get cartTotal {
    int total = 0;
    for (final item in _cartItems) {
      final priceStr = item.product.price.replaceAll(RegExp(r'[^0-9]'), '');
      total += (int.tryParse(priceStr) ?? 0) * item.quantity;
    }
    return 'LKR $total';
  }

  void addToCart(Product p) {
    final idx = _cartItems.indexWhere((c) => c.product.id == p.id);
    if (idx >= 0) {
      _cartItems[idx] = _cartItems[idx].copyWith(quantity: _cartItems[idx].quantity + 1);
    } else {
      _cartItems.add(CartItem(product: p));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((c) => c.product.id == productId);
    notifyListeners();
  }

  void updateCartQuantity(String productId, int qty) {
    final idx = _cartItems.indexWhere((c) => c.product.id == productId);
    if (idx >= 0) {
      if (qty <= 0) {
        _cartItems.removeAt(idx);
      } else {
        _cartItems[idx] = _cartItems[idx].copyWith(quantity: qty);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // ── Search & Filter ───────────────────────────────────
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setSelectedCategory(String c) {
    _selectedCategory = c;
    notifyListeners();
  }

  List<Product> get filteredProducts {
    var list = List<Product>.from(_products);
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_selectedCategory != 'All') {
      list = list.where((p) => p.category == _selectedCategory).toList();
    }
    return list;
  }

  // ── Order Helpers ─────────────────────────────────────
  List<FarmoraOrder> get pendingOrders => _orders.where((o) => o.status.toLowerCase() == 'pending' || o.status.toLowerCase() == 'pending payment').toList();
  List<FarmoraOrder> get acceptedOrders => _orders.where((o) => o.status.toLowerCase() == 'confirmed' || o.status.toLowerCase() == 'in transit').toList();
  List<FarmoraOrder> get completedOrders => _orders.where((o) => o.status.toLowerCase() == 'delivered' || o.status.toLowerCase() == 'completed').toList();

  // ── Earnings / Transactions ───────────────────────────
  double get pendingPayments => 12400.0;
  List<MonthlyBar> get monthlyBars => [
    const MonthlyBar(amount: 8500, heightRatio: 0.56, month: 'Jan'),
    const MonthlyBar(amount: 12300, heightRatio: 0.82, month: 'Feb'),
    const MonthlyBar(amount: 6800, heightRatio: 0.45, month: 'Mar'),
    const MonthlyBar(amount: 15200, heightRatio: 1.0, month: 'Apr', isHighlighted: true),
    const MonthlyBar(amount: 9400, heightRatio: 0.62, month: 'May'),
    const MonthlyBar(amount: 11000, heightRatio: 0.73, month: 'Jun'),
  ];
  List<AppTransaction> get transactions => [
    const AppTransaction(orderNumber: "#ORD-001", date: "Today", amount: 8400),
    const AppTransaction(orderNumber: "#ORD-002", date: "Yesterday", amount: 4200),
    const AppTransaction(orderNumber: "#ORD-003", date: "2 days ago", amount: 5200),
  ];
  List<FarmoraOrder> get orders => List.unmodifiable(_orders);
  List<TransportJob> get jobs => List.unmodifiable(_jobs);

  void signIn(Role r) {
    role = r;
    signedIn = true;
    notifyListeners();
  }

  void signOut() {
    signedIn = false;
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

  void addProduct(Product p) {
    _products.insert(0, p);
    notifyListeners();
  }

  void add(Product p) => addProduct(p);

  void addOrder(FarmoraOrder order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void acceptJob(String jobId) {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      _jobs[index] = _jobs[index].copyWith(accepted: true);
      notifyListeners();
    }
  }

  void acceptOrder(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      notifyListeners();
    }
  }

  // ── Verification ──────────────────────────────────────
  final List<VerificationDoc> _verificationDocs = [];
  List<VerificationDoc> get verificationDocs => List.unmodifiable(_verificationDocs);
  void updateVerificationDoc(String id, {String? fileName, String? status, String? imagePreview, String? fileSizeInfo}) {
    notifyListeners();
  }

  void signInDemo(Role r) => signIn(r);

  // ── Order Management ──────────────────────────
  void placeOrder() {
    clearCart();
    notifyListeners();
  }

  void declineOrder(String orderId) {
    notifyListeners();
  }

  // ── Product Management ──────────────────────────
  void toggleProductStock(String productId) {
    notifyListeners();
  }

  void deleteProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  // ── Earnings ────────────────────────────────────
  double get totalEarnings => 52100;
  double get thisMonth => 15200;
  double get thisWeek => 8400;

}
