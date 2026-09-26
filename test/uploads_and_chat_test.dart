import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:farmora/core/localization/l10n.dart';
import 'package:farmora/core/utils/app_errors.dart';
import 'package:farmora/core/utils/image_upload.dart';
import 'package:farmora/models/conversation_model.dart';
import 'package:farmora/models/order.dart';
import 'package:farmora/models/verification_model.dart';
import 'package:farmora/services/payment_service.dart';
import 'package:farmora/services/service_errors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _jpeg([int size = 64]) =>
    Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(size, 0)]);

void main() {
  group('image validation', () {
    test('detects real image types from magic bytes', () {
      expect(sniffImageContentType(_jpeg()), 'image/jpeg');
      expect(
          sniffImageContentType(Uint8List.fromList(
              [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0])),
          'image/png');
      expect(
          sniffImageContentType(Uint8List.fromList(
              'RIFF\x00\x00\x00\x00WEBPVP8 '.codeUnits)),
          'image/webp');
      // A PDF / SVG renamed to .jpg is still rejected.
      expect(sniffImageContentType(Uint8List.fromList('%PDF-1.7'.codeUnits)),
          isNull);
      expect(sniffImageContentType(Uint8List.fromList('<svg>'.codeUnits)),
          isNull);
    });

    test('rejects empty, unsupported and oversized files', () {
      expect(() => validateImageBytes(Uint8List(0)),
          throwsA(isA<AppException>()));
      expect(
          () => validateImageBytes(Uint8List.fromList('hello'.codeUnits)),
          throwsA(isA<AppException>().having(
              (e) => e.message, 'message', contains('Unsupported'))));
      expect(() => validateImageBytes(_jpeg(kMaxImageBytes)),
          throwsA(isA<AppException>().having(
              (e) => e.message, 'message', contains('too large'))));
    });

    test('accepts a valid photo and sanitises its name', () {
      final img = validateImageBytes(_jpeg(), name: 'my slip (1).JPG');
      expect(img.contentType, 'image/jpeg');
      expect(img.extension, 'jpg');
      expect(img.name, 'my_slip__1_.JPG');
    });
  });

  group('user-facing errors', () {
    test('an undeployed callable on web becomes a clear message', () {
      final e = FirebaseFunctionsException(code: 'internal', message: 'internal');
      expect(describeError(e, action: 'publish this product'),
          'The Farmora server could not be reached. Please try again later.');
    });

    test('permission, storage and picker errors are readable', () {
      expect(
          describeError(
              FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
              action: 'publish this product'),
          "You don't have permission to do this.");
      expect(
          describeError(FirebaseException(
              plugin: 'firebase_storage', code: 'unauthorized')),
          "You don't have permission to upload this file.");
      expect(
          describeError(PlatformException(code: 'photo_access_denied')),
          contains('Photo access was denied'));
      expect(describeError(const AppException('Custom')), 'Custom');
    });

    test('service rule errors keep their type and show their message', () {
      final e = UserStateError(L10n.current.svcNotEnoughStock);
      expect(e, isA<StateError>());
      expect(describeError(e), 'Not enough stock.');
      expect(describeError(UserArgumentError('Bad')), 'Bad');
    });

    test('image and service messages follow the app language', () {
      addTearDown(() => L10n.updateLocale(const Locale('en')));
      L10n.updateLocale(const Locale('ta'));
      expect(
          () => validateImageBytes(Uint8List(0)),
          throwsA(isA<AppException>().having((e) => e.message, 'message',
              L10n.current.errorImageEmpty)));
      expect(L10n.current.errorImageEmpty, isNot('The selected file is empty.'));
      expect(PaymentMethod.label(PaymentMethod.bankDeposit), 'வங்கி வைப்பு');
      L10n.updateLocale(const Locale('si'));
      expect(PaymentMethod.label(PaymentMethod.cod), 'බාරදීමේදී මුදල්');
    });

    test('verification document types get display names', () {
      expect(VerificationDoc.documentTypeLabel('NIC'), 'National ID card (NIC)');
      expect(VerificationDoc.documentTypeLabel('Vehicle Registration'),
          'Vehicle registration');
      expect(VerificationDoc.documentTypeLabel('Something else'),
          'Something else');
    });
  });

  group('chat message model', () {
    test('parses image and payment-proof attachments', () {
      final m = FarmoraMessage.fromMap('m1', {
        'conversationId': 'c1',
        'senderId': 'b',
        'receiverId': 'f',
        'attachmentUrl': 'https://x/y.jpg',
        'attachmentPath': 'payment_slips/o1/b_1.jpg',
        'attachmentKind': 'payment_proof',
        'createdAt': DateTime(2026, 9, 1).toIso8601String(),
      });
      expect(m.hasImage, isTrue);
      expect(m.isPaymentProof, isTrue);
      expect(m.recipientId, 'f');
      expect(m.body, isEmpty);
      expect(m.createdAt, DateTime(2026, 9, 1));
    });
  });

  group('PaymentService.submitPaymentProof', () {
    late FakeFirebaseFirestore db;
    late PaymentService buyerService;

    setUp(() async {
      db = FakeFirebaseFirestore();
      buyerService = PaymentService(db: db, currentUid: () => 'buyer1');
      await db.collection('orders').doc('o1').set({
        'buyerId': 'buyer1',
        'farmerId': 'farmer1',
        'title': 'Carrots',
        'status': 'confirmed',
        'totalMinor': 735000,
        'paymentMethod': PaymentMethod.bankDeposit,
        'paymentStatus': 'pending',
      });
    });

    test('links the slip, marks it for review and notifies the farmer (Spark)',
        () async {
      await buyerService.submitPaymentProof(
        orderId: 'o1',
        proofImageUrl: 'https://storage/slip.jpg',
        proofImagePath: 'payment_slips/o1/buyer1_1.jpg',
      );
      final order = FarmoraOrder.fromMap(
          'o1', (await db.collection('orders').doc('o1').get()).data()!);
      expect(order.paymentState, PaymentState.proofSubmitted);
      expect(order.proofImageUrl, 'https://storage/slip.jpg');
      expect(order.canReviewProof, isTrue);
      // Spark: the buyer's client notifies the farmer (with Cloud Functions
      // the onOrderPaymentStatusChanged trigger does it instead).
      final notes = await db.collection('notifications').get();
      expect(notes.docs, hasLength(1));
      expect(notes.docs.single.data()['userId'], 'farmer1');
    });

    test('farmer can then confirm it', () async {
      await buyerService.submitPaymentProof(
        orderId: 'o1',
        proofImageUrl: 'https://storage/slip.jpg',
        proofImagePath: 'payment_slips/o1/buyer1_1.jpg',
      );
      await PaymentService(db: db, currentUid: () => 'farmer1')
          .confirmBankPayment('o1');
      final data = (await db.collection('orders').doc('o1').get()).data()!;
      expect(data['paymentStatus'], 'paid');
    });

    test('rejects other users, COD orders and foreign slip paths', () async {
      expect(
          () => PaymentService(db: db, currentUid: () => 'stranger')
              .submitPaymentProof(
                  orderId: 'o1',
                  proofImageUrl: 'https://x',
                  proofImagePath: 'payment_slips/o1/stranger_1.jpg'),
          throwsStateError);
      expect(
          () => buyerService.submitPaymentProof(
              orderId: 'o1',
              proofImageUrl: 'https://x',
              proofImagePath: 'payment_slips/other/buyer1_1.jpg'),
          throwsArgumentError);
      await db
          .collection('orders')
          .doc('o1')
          .update({'paymentMethod': PaymentMethod.cod});
      expect(
          () => buyerService.submitPaymentProof(
              orderId: 'o1',
              proofImageUrl: 'https://x',
              proofImagePath: 'payment_slips/o1/buyer1_1.jpg'),
          throwsStateError);
    });

    test('a paid order no longer accepts slips', () async {
      await db.collection('orders').doc('o1').update({'paymentStatus': 'paid'});
      expect(
          () => buyerService.submitPaymentProof(
              orderId: 'o1',
              proofImageUrl: 'https://x',
              proofImagePath: 'payment_slips/o1/buyer1_1.jpg'),
          throwsStateError);
    });
  });
}
