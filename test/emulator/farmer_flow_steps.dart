// Steps of the farmer / customer end-to-end flow, run against the Firebase
// Emulator Suite with the app's real service layer and the real
// firestore.rules / storage.rules. Shared by farmer_flow_emulator_test.dart
// and web_runner.dart. Not a live-project test; does not drive the UI.
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmora/core/utils/image_upload.dart';
import 'package:farmora/firebase_options.dart';
import 'package:farmora/models/bank_details.dart';
import 'package:farmora/models/conversation_model.dart';
import 'package:farmora/models/order.dart';
import 'package:farmora/models/product.dart';
import 'package:farmora/services/earnings_calculator.dart';
import 'package:farmora/services/firebase_service.dart';
import 'package:farmora/services/payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
// matcher ships with the Flutter SDK (via flutter_test); imported directly
// because flutter_test itself can't be compiled into the web runner.
// ignore: depend_on_referenced_packages
import 'package:matcher/matcher.dart';

const _project = 'demo-farmora';
final _run = DateTime.now().millisecondsSinceEpoch;

/// Minimal JPEG header + padding; enough for type sniffing and Storage rules.
final PickedImage _photo = validateImageBytes(
  Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(2048, 7)]),
  name: 'photo.jpg',
);

final _auth = FirebaseAuth.instance;
final _db = FirebaseFirestore.instance;

Future<String> _signUp(String role, {String? label}) async {
  final email = '${label ?? role}$_run@farmora.test';
  final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: 'Passw0rd!');
  final uid = cred.user!.uid;
  // Same shape the registration screen writes (validated by the rules).
  await _db.collection('users').doc(uid).set({
    'id': uid,
    'authUid': uid,
    'name': 'Test $role',
    'displayName': 'Test $role',
    'phone': '+94770000000',
    'role': role,
    'isVerified': false,
    'isSuspended': false,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  await _auth.signOut();
  return email;
}

Future<String> _signIn(String email) async {
  await _auth.signOut();
  final cred =
      await _auth.signInWithEmailAndPassword(email: email, password: 'Passw0rd!');
  return cred.user!.uid;
}

Future<FarmoraOrder> _order(String id) async => FarmoraOrder.fromMap(
    id, (await _db.collection('orders').doc(id).get()).data()!);

/// `package:matcher`'s own `expect` only works inside a test body; this one
/// also works in the web runner.
void expect(dynamic actual, dynamic matcher, {String? reason}) {
  final m = wrapMatcher(matcher);
  final state = <dynamic, dynamic>{};
  if (m.matches(actual, state)) return;
  final expected = StringDescription().addDescriptionOf(m).toString();
  throw StateError(
      'Expected: $expected, actual: $actual${reason == null ? '' : ' ($reason)'}');
}

/// Labels a failing operation so the report says exactly which call failed.
Future<T> _op<T>(String label, Future<T> Function() run) async {
  try {
    return await run();
  } catch (e) {
    throw StateError('$label failed: $e');
  }
}

/// The farmer's orders straight from the server (same query as the app's
/// orders listener), so a cached first snapshot can't hide new orders.
Future<List<FarmoraOrder>> _farmerOrders(String farmerId) async {
  final snap = await _db
      .collection('orders')
      .where('farmerId', isEqualTo: farmerId)
      .orderBy('createdAt', descending: true)
      .get(const GetOptions(source: Source.server));
  return snap.docs.map((d) => FarmoraOrder.fromMap(d.id, d.data())).toList();
}

String _describe(List<FarmoraOrder> orders) => orders
    .map((o) => '${o.id.substring(0, 12)}:${o.status}/${o.paymentStatus}/${o.total}')
    .join(', ');

typedef FlowStep = (String, Future<void> Function());

/// Ordered steps; each depends on the ones before it.
List<FlowStep> farmerFlowSteps() {
  final steps = <FlowStep>[];
  late FirestoreService service;
  late String farmerEmail, buyerEmail, strangerEmail;
  late String farmerId, buyerId;
  late String productId, productImageUrl;
  late String codOrderId, bankOrderId;
  const priceMinor = 35000; // LKR 350.00 / kg
  const qty = 2;
  const feeMinor = 35000;
  const expectedTotal = (priceMinor * qty + feeMinor) / 100; // LKR 1050.00

  steps.add(('setup: emulators + farmer/buyer/outsider accounts', () async {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: DefaultFirebaseOptions.web.apiKey,
        appId: DefaultFirebaseOptions.web.appId,
        messagingSenderId: DefaultFirebaseOptions.web.messagingSenderId,
        projectId: _project,
        storageBucket: '$_project.appspot.com',
      ),
    );
    await _auth.useAuthEmulator('127.0.0.1', 9099);
    _db.useFirestoreEmulator('127.0.0.1', 8080);
    await FirebaseStorage.instance.useStorageEmulator('127.0.0.1', 9199);
    service = FirestoreService();
    farmerEmail = await _signUp('farmer');
    buyerEmail = await _signUp('buyer');
    strangerEmail = await _signUp('buyer', label: 'outsider');
  }));

  steps.add(('1. farmer adds a product with an image stored in Storage', () async {
    farmerId = await _signIn(farmerEmail);
    final stored = await service.uploadProductImage(_photo);
    productImageUrl = stored.url;
    expect(stored.path, startsWith('product_images/$farmerId/'));
    final meta = await FirebaseStorage.instance.ref(stored.path).getMetadata();
    expect(meta.contentType, 'image/jpeg');

    productId = await service.createSecureProduct(Product(
      name: 'E2E Carrots',
      category: 'Vegetables',
      location: 'Nuwara Eliya',
      quantity: '50 kg available',
      price: 'LKR 350.00 / kg',
      pricePerUnit: 350,
      priceMinor: priceMinor,
      quantityAvailable: 50,
      media: [stored.url],
      imageUrls: [stored.url],
      images: [stored.url],
    ));
    final doc = (await _db.collection('products').doc(productId).get()).data()!;
    expect(doc['farmerId'], farmerId);
    expect(doc['media'], [stored.url]);
    expect(doc['imagePath'], stored.url);
    expect(doc['status'], 'Active');
  }));

  steps.add(('2. customer sees the product with its image', () async {
    buyerId = await _signIn(buyerEmail);
    final products = await service.productsStream().first;
    final p = products.firstWhere((p) => p.id == productId);
    expect(p.media.first, productImageUrl);
    expect(p.priceMinor, priceMinor);
  }));

  steps.add(('3. customer places a Cash on Delivery order', () async {
    codOrderId = await service.createSecureOrder(
      productId: productId,
      quantity: qty,
      deliveryFeeMinor: feeMinor,
      deliveryAddress: '12 Galle Road, Colombo 03',
      idempotencyKey: 'e2e_cod_${_run}_$productId',
      paymentMethod: PaymentMethod.cod,
    );
    final o = await _order(codOrderId);
    expect(o.buyerId, buyerId);
    expect(o.farmerId, farmerId);
    expect(o.productId, productId);
    expect(o.total, expectedTotal);
    expect(o.paymentMethod, PaymentMethod.cod);
    expect(o.paymentStatus, 'pending');
    expect(o.status, 'pending');
    final stock =
        (await _db.collection('products').doc(productId).get())['quantityAvailable'];
    expect(stock, 50 - qty);
  }));

  steps.add(('4. farmer receives the order, sees COD, completes it, marks cash', () async {
    await _signIn(farmerEmail);
    final orders = await _op('farmer orders query',
        () => _farmerOrders(farmerId));
    final o = orders.firstWhere((o) => o.id == codOrderId);
    expect(PaymentMethod.label(o.paymentMethod), 'Cash on Delivery');
    expect(o.canMarkCashReceived, isFalse, reason: 'not delivered yet');

    // Earnings before completion: pending, not income.
    var calc = EarningsCalculator(orders, farmerId: farmerId);
    expect(calc.thisMonth, 0);
    expect(calc.pendingPayments, expectedTotal);

    await _op('Accept Order (transitionOrder confirmed)',
        () => service.transitionOrder(codOrderId, 'confirmed'));
    await _op('completeOrder (status delivered)',
        () => service.updateOrderStatus(codOrderId, 'Delivered', 1.0));
    expect((await _order(codOrderId)).canMarkCashReceived, isTrue);

    await _op('Mark Cash Received',
        () => PaymentService().markCashReceived(codOrderId));
    final paid = await _order(codOrderId);
    expect(paid.paymentStatus, 'paid');
    expect(paid.paidAt, isNotNull);

    calc = EarningsCalculator(
        await _farmerOrders(farmerId),
        farmerId: farmerId);
    expect(calc.thisMonth, expectedTotal);
    expect(calc.totalEarnings, expectedTotal);
    expect(calc.pendingPayments, 0);
  }));

  steps.add(('5. pending and cancelled orders do not count as income', () async {
    await _signIn(buyerEmail);
    final pendingId = await service.createSecureOrder(
      productId: productId,
      quantity: 1,
      deliveryAddress: '12 Galle Road, Colombo 03',
      idempotencyKey: 'e2e_pending_${_run}_$productId',
    );
    final cancelledId = await service.createSecureOrder(
      productId: productId,
      quantity: 1,
      deliveryAddress: '12 Galle Road, Colombo 03',
      idempotencyKey: 'e2e_cancel_${_run}_$productId',
    );
    await service.transitionOrder(cancelledId, 'cancelled');

    await _signIn(farmerEmail);
    final calc = EarningsCalculator(
        await _farmerOrders(farmerId),
        farmerId: farmerId);
    expect(calc.thisMonth, expectedTotal, reason: 'only the paid COD order');
    expect(calc.pendingPayments, priceMinor / 100,
        reason: 'pending only; orders: ${_describe(calc.paidOrders.toList() + calc.awaitingOrders.toList())}');
    expect((await _order(pendingId)).isPaid, isFalse);
  }));

  steps.add(('6. bank deposit: slip upload, order link, chat message', () async {
    await _signIn(farmerEmail);
    await _op('farmer saves bank details', () => PaymentService().saveBankDetails(const BankDetails(
      bankName: 'Bank of Ceylon',
      branch: 'Kandy',
      accountHolderName: 'Test Farmer',
      accountNumber: '0012345678',
    )));

    await _signIn(buyerEmail);
    bankOrderId = await _op('bank deposit checkout', () => service.createSecureOrder(
      productId: productId,
      quantity: 1,
      deliveryAddress: '12 Galle Road, Colombo 03',
      idempotencyKey: 'e2e_bank_${_run}_$productId',
      paymentMethod: PaymentMethod.bankDeposit,
    ));
    expect((await _order(bankOrderId)).bankDetailsSnapshot?.accountNumber,
        '0012345678');

    // Same steps as FarmoraState.submitPaymentSlip.
    final slip = await _op('slip upload to Storage',
        () => service.uploadPaymentSlip(orderId: bankOrderId, image: _photo));
    expect(slip.path, startsWith('payment_slips/$bankOrderId/${buyerId}_'));
    await _op('link slip to order', () => PaymentService().submitPaymentProof(
        orderId: bankOrderId, proofImageUrl: slip.url, proofImagePath: slip.path));
    final convo = await _op('open chat with farmer',
        () => service.ensureConversation(orderId: bankOrderId, peerId: farmerId));
    await _op('post slip in chat', () => service.sendChatMessage(
      conversation: convo,
      recipientId: farmerId,
      attachment: ChatAttachment(
          url: slip.url, path: slip.path, kind: ChatAttachmentKind.paymentProof),
    ));
    final o = await _order(bankOrderId);
    expect(o.paymentState, PaymentState.proofSubmitted);
    expect(o.proofImageUrl, slip.url);
  }));

  steps.add(('7. farmer receives the slip in chat, opens it, rejects then confirms',
      () async {
    await _signIn(farmerEmail);
    final convo =
        await service.ensureConversation(orderId: bankOrderId, peerId: buyerId);
    final msgs = await service
        .messagesStream(convo.id, orderId: bankOrderId, uid: farmerId)
        .first;
    final proof = msgs.singleWhere((m) => m.isPaymentProof);
    // Farmer can download the slip (what the full-screen viewer loads).
    final bytes =
        await FirebaseStorage.instance.ref(proof.attachmentPath!).getData();
    expect(bytes, isNotNull);

    await PaymentService().rejectBankPayment(bankOrderId, 'Amount unclear');
    expect((await _order(bankOrderId)).paymentState, PaymentState.rejected);

    await _signIn(buyerEmail);
    final slip2 =
        await service.uploadPaymentSlip(orderId: bankOrderId, image: _photo);
    await PaymentService().submitPaymentProof(
        orderId: bankOrderId, proofImageUrl: slip2.url, proofImagePath: slip2.path);

    await _signIn(farmerEmail);
    await PaymentService().confirmBankPayment(bankOrderId);
    expect((await _order(bankOrderId)).isPaid, isTrue);
    final calc = EarningsCalculator(
        await _farmerOrders(farmerId),
        farmerId: farmerId);
    expect(calc.thisMonth, expectedTotal + priceMinor / 100);
    expect(calc.summaryFor(DateTime.now()).bankTotal, priceMinor / 100);
    expect(calc.summaryFor(DateTime.now()).codTotal, expectedTotal);
  }));

  steps.add(('8. chat images both ways, delivered in realtime', () async {
    // A second app instance = the other person's device (own auth session).
    final peerApp = await Firebase.initializeApp(
        name: 'peer-$_run', options: Firebase.app().options);
    final peerAuth = FirebaseAuth.instanceFor(app: peerApp);
    await peerAuth.useAuthEmulator('127.0.0.1', 9099);
    final peerDb = FirebaseFirestore.instanceFor(app: peerApp)
      ..useFirestoreEmulator('127.0.0.1', 8080);

    /// Waits on the peer device for an image message addressed to [uid].
    Future<void> peerReceivesImage(String uid, String fromId) => peerDb
        .collection('messages')
        .where('orderId', isEqualTo: codOrderId)
        .where('receiverId', isEqualTo: uid)
        .snapshots()
        .firstWhere((snap) => snap.docs.any((d) =>
            d['senderId'] == fromId && (d.data()['attachmentUrl'] ?? '') != ''))
        .timeout(const Duration(seconds: 20));

    // Customer -> Farmer: farmer's device is listening while buyer sends.
    await peerAuth.signInWithEmailAndPassword(
        email: farmerEmail, password: 'Passw0rd!');
    final farmerSees = peerReceivesImage(farmerId, buyerId);
    await _signIn(buyerEmail);
    final buyerConvo = await _op('buyer opens chat',
        () => service.ensureConversation(orderId: codOrderId, peerId: farmerId));
    final img = await _op('buyer uploads chat photo',
        () => service.uploadChatImage(orderId: codOrderId, image: _photo));
    await _op('buyer sends photo', () => service.sendChatMessage(
          conversation: buyerConvo,
          recipientId: farmerId,
          attachment: ChatAttachment(url: img.url, path: img.path),
        ));
    await _op('farmer receives photo in realtime', () => farmerSees);

    // Farmer -> Customer: buyer's device is listening while farmer sends.
    await peerAuth.signOut();
    await peerAuth.signInWithEmailAndPassword(
        email: buyerEmail, password: 'Passw0rd!');
    final buyerSees = peerReceivesImage(buyerId, farmerId);
    await _signIn(farmerEmail);
    final farmerConvo = await _op('farmer opens chat',
        () => service.ensureConversation(orderId: codOrderId, peerId: buyerId));
    expect(farmerConvo.id, buyerConvo.id, reason: 'same deterministic chat');
    final back = await _op('farmer uploads chat photo',
        () => service.uploadChatImage(orderId: codOrderId, image: _photo));
    await _op('farmer sends photo', () => service.sendChatMessage(
          conversation: farmerConvo,
          recipientId: buyerId,
          attachment: ChatAttachment(url: back.url, path: back.path),
        ));
    await _op('buyer receives photo in realtime', () => buyerSees);

    // Farmer's chat screen query shows both photos; each one downloads.
    final farmerView = await _op('farmer chat query', () => service
        .messagesStream(farmerConvo.id, orderId: codOrderId, uid: farmerId)
        .first);
    final photos = farmerView.where((m) => m.hasImage).toList();
    expect(photos.length, 2);
    for (final m in photos) {
      expect(await FirebaseStorage.instance.ref(m.attachmentPath!).getData(),
          isNotNull);
    }
    await peerAuth.signOut();
  }));

  steps.add(('9. outsiders cannot read slips, orders or chats', () async {
    await _signIn(strangerEmail);
    final msgs = await service
        .messagesStream('o_${bankOrderId}_x', orderId: bankOrderId, uid: 'x')
        .first
        .then((_) => 'read', onError: (_) => 'denied');
    expect(msgs, 'denied');
    final orderRead = await _db
        .collection('orders')
        .doc(bankOrderId)
        .get()
        .then((_) => 'read', onError: (_) => 'denied');
    expect(orderRead, 'denied');
    final slipPath = (await FirebaseStorage.instance
            .ref('payment_slips/$bankOrderId')
            .listAll()
            .then((_) => 'listed', onError: (_) => 'denied'));
    expect(slipPath, 'denied');
  }));
  return steps;
}
