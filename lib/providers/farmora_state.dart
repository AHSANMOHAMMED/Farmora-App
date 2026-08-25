import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/transport_job.dart';

class FarmoraState extends ChangeNotifier {
  bool signedIn = false;
  String language = 'English';
  Role role = Role.buyer;

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
    const Product(
      id: 'prod-4',
      name: 'Green Chilli',
      category: 'Vegetables',
      location: 'Dambulla',
      quantity: '15 kg available',
      price: 'LKR 520 / kg',
      emoji: '🌶️',
      color: Color(0xffe8f5e9),
    ),
    const Product(
      id: 'prod-5',
      name: 'Fresh Carrots',
      category: 'Vegetables',
      location: 'Badulla',
      quantity: '30 kg available',
      price: 'LKR 340 / kg',
      emoji: '🥕',
      color: Color(0xfffff0c2),
    ),
    const Product(
      id: 'prod-6',
      name: 'Cabbage Heads',
      category: 'Vegetables',
      location: 'Kandy',
      quantity: '50 heads available',
      price: 'LKR 150 / kg',
      emoji: '🥬',
      color: Color(0xffddf1dd),
    ),
    const Product(
      id: 'prod-7',
      name: 'Brinjal (Eggplant)',
      category: 'Vegetables',
      location: 'Jaffna',
      quantity: '25 kg available',
      price: 'LKR 280 / kg',
      emoji: '🍆',
      color: Color(0xffe8eaf6),
    ),
    const Product(
      id: 'prod-8',
      name: 'King Coconut',
      category: 'Fruits',
      location: 'Gampaha',
      quantity: '100 units available',
      price: 'LKR 50 / unit',
      emoji: '🥥',
      color: Color(0xfffff8e1),
    ),
    const Product(
      id: 'prod-9',
      name: 'Green Beans',
      category: 'Vegetables',
      location: 'Nuwara Eliya',
      quantity: '18 kg available',
      price: 'LKR 320 / kg',
      emoji: '🫘',
      color: Color(0xffe8f5e9),
    ),
    const Product(
      id: 'prod-10',
      name: 'Curry Leaves',
      category: 'Herbs',
      location: 'Matale',
      quantity: '200 bunches',
      price: 'LKR 40 / bunch',
      emoji: '🍃',
      color: Color(0xffe8f5e9),
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
    const FarmoraOrder(
      id: 'ord-3',
      title: 'Green Chilli',
      detail: '10 kg · LKR 5,200 · 2 days ago',
      status: 'Pending',
      progress: 0.0,
      color: Color(0xffe67e22),
    ),
    const FarmoraOrder(
      id: 'ord-4',
      title: 'Fresh Carrots',
      detail: '25 kg · LKR 8,500 · 3 days ago',
      status: 'Confirmed',
      progress: 0.3,
      color: Color(0xff1abc9c),
    ),
    const FarmoraOrder(
      id: 'ord-5',
      title: 'Gotukola Bunches',
      detail: '50 bunches · LKR 4,500 · Last week',
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

  /// Alias for backward compatibility
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
}
