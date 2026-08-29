import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_role.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/transport_job.dart';
import '../core/services/firebase_auth_service.dart';

class FarmoraState extends ChangeNotifier {
  bool signedIn = false;
  String language = 'English';
  Role role = Role.buyer;
  String? authError;
  late final FirebaseAuthService? _authService =
      Firebase.apps.isEmpty ? null : FirebaseAuthService();

  final List<Product> _products = [
    const Product(
      id: 'prod-1',
      name: 'Organic Tomatoes',
      category: 'Vegetables',
      location: 'Nuwara Eliya',
      quantity: '20 kg available',
      price: 'LKR 420 / kg',
      emoji: '🍅',
      color: Color(0xffffe1da),
    ),
    const Product(
      id: 'prod-2',
      name: 'Cavendish Bananas',
      category: 'Fruits',
      location: 'Ambalantota',
      quantity: '45 kg available',
      price: 'LKR 280 / kg',
      emoji: '🍌',
      color: Color(0xfffff0c2),
    ),
    const Product(
      id: 'prod-3',
      name: 'Gotukola Bunches',
      category: 'Herbs',
      location: 'Kandy',
      quantity: '80 bunches',
      price: 'LKR 90 / bunch',
      emoji: '🌿',
      color: Color(0xffddf1dd),
    ),
  ];

  final List<FarmoraOrder> _orders = [
    const FarmoraOrder(
      id: 'ord-1',
      title: 'Organic Tomatoes',
      detail: '20 kg · LKR 8,400 · Today',
      status: 'In transit',
      progress: 0.68,
      color: Color(0xff3478c5),
    ),
    const FarmoraOrder(
      id: 'ord-2',
      title: 'Cavendish Bananas',
      detail: '15 kg · LKR 4,200 · Yesterday',
      status: 'Delivered',
      progress: 1.0,
      color: Color(0xff1f7a4d),
    ),
  ];

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

  List<Product> get products => List.unmodifiable(_products);
  List<FarmoraOrder> get orders => List.unmodifiable(_orders);
  List<TransportJob> get jobs => List.unmodifiable(_jobs);

  void signIn(Role r) {
    role = r;
    signedIn = true;
    notifyListeners();
  }

  Future<bool> signInWithBackend({
    required String phone,
    required String password,
  }) async {
    authError = null;
    try {
      final result = _authService == null
          ? const FarmoraAuthResult(Role.buyer)
          : await _authService.login(
              phone: phone,
              password: password,
            );
      role = result.role;
      signedIn = true;
      notifyListeners();
      return true;
    } on FarmoraAuthException catch (error) {
      authError = error.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithBackend({
    required String name,
    required String phone,
    required String password,
    required Role role,
    String? district,
  }) async {
    authError = null;
    try {
      final result = _authService == null
          ? FarmoraAuthResult(role)
          : await _authService.register(
              name: name,
              phone: phone,
              password: password,
              role: role,
              district: district,
            );
      this.role = result.role;
      signedIn = true;
      notifyListeners();
      return true;
    } on FarmoraAuthException catch (error) {
      authError = error.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    authError = null;
    try {
      if (_authService == null) return false;
      final result = await _authService.loginWithGoogle();
      role = result.role;
      signedIn = true;
      notifyListeners();
      return true;
    } on FarmoraAuthException catch (error) {
      authError = error.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithGoogle({
    required String name,
    required String phone,
    required Role role,
    String? district,
  }) async {
    authError = null;
    try {
      if (_authService == null) return false;
      final result = await _authService.registerWithGoogle(
        name: name,
        phone: phone,
        role: role,
        district: district,
      );
      this.role = result.role;
      signedIn = true;
      notifyListeners();
      return true;
    } on FarmoraAuthException catch (error) {
      authError = error.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService?.signOut();
    } catch (_) {
      // A deleted/expired Firebase user must not block local sign-out.
    } finally {
      authError = null;
      signedIn = false;
      notifyListeners();
    }
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

  /// Alias for backward compatibility
  void add(Product p) => addProduct(p);

  void acceptJob(String jobId) {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      _jobs[index] = _jobs[index].copyWith(accepted: true);
      notifyListeners();
    }
  }
}
