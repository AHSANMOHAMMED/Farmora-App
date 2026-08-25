import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/transport_job.dart';
import '../models/verification_model.dart';

// ============================================================
// Firebase Authentication Service
// ============================================================
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the currently signed-in user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes (fires on sign-in/sign-out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Save user profile to Firestore after registration
  Future<void> saveUserProfile({
    required String uid,
    required String role,
    required String displayName,
    String? email,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'role': role,
      'displayName': displayName,
      'email': email ?? '',
      'photoUrl': '',
      'language': 'English',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Load user profile from Firestore
  Future<Map<String, dynamic>?> loadUserProfile(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }
}

// ============================================================
// Firestore Data Service
// ============================================================
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Products ──────────────────────────────────────────────

  /// Add a new product to Firestore
  Future<void> addProduct(Product p, String farmerId) async {
    await _db.collection('products').add({
      ...p.toMap(),
      'farmerId': farmerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update a product
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _db.collection('products').doc(id).update(data);
  }

  /// Delete a product
  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  /// Real-time stream of all products
  Stream<List<Product>> productsStream() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Products stream filtered by farmer
  Stream<List<Product>> productsByFarmerStream(String farmerId) {
    return _db
        .collection('products')
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ── Orders ────────────────────────────────────────────────

  /// Add a new order
  Future<void> addOrder(FarmoraOrder o) async {
    await _db.collection('orders').add({
      ...o.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update order status
  Future<void> updateOrderStatus(String id, String status, double progress) async {
    await _db.collection('orders').doc(id).update({
      'status': status,
      'progress': progress,
    });
  }

  /// Real-time stream of all orders
  Stream<List<FarmoraOrder>> ordersStream() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FarmoraOrder.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Orders stream filtered by farmer
  Stream<List<FarmoraOrder>> ordersByFarmerStream(String farmerId) {
    return _db
        .collection('orders')
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FarmoraOrder.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Orders stream filtered by buyer
  Stream<List<FarmoraOrder>> ordersByBuyerStream(String buyerId) {
    return _db
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FarmoraOrder.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ── Transport Jobs ────────────────────────────────────────

  /// Add a new transport job
  Future<void> addTransportJob(TransportJob j) async {
    await _db.collection('transport_jobs').add({
      ...j.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real-time stream of transport jobs
  Stream<List<TransportJob>> jobsStream() {
    return _db
        .collection('transport_jobs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransportJob.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ── Verification Documents ────────────────────────────────

  /// Add a verification document
  Future<void> addVerificationDoc(VerificationDoc d, String farmerId) async {
    await _db.collection('verification_docs').add({
      ...d.toMap(),
      'farmerId': farmerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update verification document
  Future<void> updateVerificationDoc(String id, Map<String, dynamic> data) async {
    await _db.collection('verification_docs').doc(id).update(data);
  }

  /// Verification docs stream for a farmer
  Stream<List<VerificationDoc>> verificationDocsStream(String farmerId) {
    return _db
        .collection('verification_docs')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => VerificationDoc.fromMap(doc.id, doc.data()))
            .toList());
  }
}
