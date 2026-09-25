import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:farmora/features/payments/presentation/order_payment_card.dart';
import 'package:farmora/models/bank_details.dart';
import 'package:farmora/models/order.dart';
import 'package:farmora/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/l10n_test_app.dart';

FarmoraOrder _order({
  String status = 'delivered',
  String paymentStatus = 'pending',
  String paymentMethod = PaymentMethod.cod,
}) =>
    FarmoraOrder(
      id: 'o1',
      title: 'Carrots',
      detail: '',
      status: status,
      progress: 1,
      color: Colors.green,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
    );

void main() {
  group('BankDetails', () {
    test('validates Sri Lankan account numbers and masks them', () {
      expect(BankDetails.isValidAccountNumber('0012-3456 789'), isTrue);
      expect(BankDetails.isValidAccountNumber('12345'), isFalse);
      expect(BankDetails.isValidAccountNumber('12ab5678'), isFalse);
      const d = BankDetails(
        bankName: 'Bank of Ceylon',
        branch: 'Nuwara Eliya',
        accountHolderName: 'S. Perera',
        accountNumber: '0012345678',
      );
      expect(d.isComplete, isTrue);
      expect(d.maskedAccountNumber, '•••• 5678');
      expect(BankDetails.empty.isComplete, isFalse);
    });
  });

  group('FarmoraOrder payment state', () {
    test('maps legacy escrow statuses onto the new lifecycle', () {
      expect(_order(paymentStatus: 'payment_required').paymentState,
          PaymentState.pending);
      expect(_order(paymentStatus: 'released').paymentState, PaymentState.paid);
      expect(_order(paymentStatus: 'Paid (Escrow)').paymentState,
          PaymentState.paid);
      expect(_order(paymentStatus: 'proof_submitted').paymentState,
          PaymentState.proofSubmitted);
    });

    test('cash can be marked received only for delivered unpaid COD', () {
      expect(_order().canMarkCashReceived, isTrue);
      expect(_order(status: 'In transit').canMarkCashReceived, isFalse);
      expect(_order(paymentStatus: 'paid').canMarkCashReceived, isFalse);
      expect(_order(paymentMethod: PaymentMethod.bankDeposit)
          .canMarkCashReceived, isFalse);
    });

    test('proof review and resubmission follow bank deposit status', () {
      final submitted = _order(
          paymentMethod: PaymentMethod.bankDeposit,
          paymentStatus: 'proof_submitted');
      expect(submitted.canReviewProof, isTrue);
      expect(submitted.canSubmitProof, isTrue);
      final rejected = _order(
          paymentMethod: PaymentMethod.bankDeposit, paymentStatus: 'rejected');
      expect(rejected.canReviewProof, isFalse);
      expect(rejected.canSubmitProof, isTrue);
      expect(rejected.isAwaitingPayment, isTrue);
    });

    test('cancelled orders are never awaiting payment', () {
      expect(_order(status: 'Cancelled').isAwaitingPayment, isFalse);
      expect(_order(status: 'Declined').isAwaitingPayment, isFalse);
    });

    test('fromMap reads Firestore Timestamps for createdAt and paidAt', () {
      final created = DateTime(2026, 8, 3, 10);
      final paid = DateTime(2026, 8, 5, 14);
      final o = FarmoraOrder.fromMap('o1', {
        'status': 'delivered',
        'createdAt': Timestamp.fromDate(created),
        'paidAt': Timestamp.fromDate(paid),
        'paymentMethod': 'bank_deposit',
        'bankDetailsSnapshot': {'bankName': 'HNB', 'accountNumber': '123456'},
      });
      expect(o.createdAt, created);
      expect(o.paidAt, paid);
      expect(o.isBankDeposit, isTrue);
      expect(o.bankDetailsSnapshot?.bankName, 'HNB');
    });
  });

  group('PaymentService', () {
    late FakeFirebaseFirestore db;
    var uid = 'farmer1';
    PaymentService service() => PaymentService(db: db, currentUid: () => uid);

    Future<void> seedOrder(Map<String, dynamic> data) =>
        db.collection('orders').doc('o1').set({
          'buyerId': 'buyer1',
          'farmerId': 'farmer1',
          'status': 'delivered',
          'totalMinor': 1250000,
          'paymentMethod': 'cod',
          'paymentStatus': 'pending',
          ...data,
        });

    Future<Map<String, dynamic>> order() async =>
        (await db.collection('orders').doc('o1').get()).data()!;

    setUp(() {
      db = FakeFirebaseFirestore();
      uid = 'farmer1';
    });

    test('farmer marks COD cash received after delivery', () async {
      await seedOrder({});
      await service().markCashReceived('o1');
      final data = await order();
      expect(data['paymentStatus'], 'paid');
      expect(data['paidAt'], isNotNull);
      expect(data['paymentConfirmedBy'], 'farmer1');
      final notes = await db.collection('notifications').get();
      expect(notes.docs.single.data()['userId'], 'buyer1');
    });

    test('cash cannot be marked before delivery or by the buyer', () async {
      await seedOrder({'status': 'In transit'});
      await expectLater(() => service().markCashReceived('o1'), throwsStateError);
      await seedOrder({});
      uid = 'buyer1';
      await expectLater(() => service().markCashReceived('o1'), throwsStateError);
      expect((await order())['paymentStatus'], 'pending');
    });

    test('farmer confirms a submitted bank deposit', () async {
      await seedOrder({
        'paymentMethod': 'bank_deposit',
        'paymentStatus': 'proof_submitted',
        'rejectionReason': 'old reason',
      });
      await service().confirmBankPayment('o1');
      final data = await order();
      expect(data['paymentStatus'], 'paid');
      expect(data.containsKey('rejectionReason'), isFalse);
    });

    test('rejecting a receipt requires a reason and a pending receipt',
        () async {
      await seedOrder({'paymentMethod': 'bank_deposit'});
      await expectLater(() => service().rejectBankPayment('o1', 'Blurry slip'),
          throwsStateError);
      await expectLater(() => service().rejectBankPayment('o1', ' '), throwsArgumentError);
      await seedOrder(
          {'paymentMethod': 'bank_deposit', 'paymentStatus': 'proof_submitted'});
      await service().rejectBankPayment('o1', 'Amount does not match');
      final data = await order();
      expect(data['paymentStatus'], 'rejected');
      expect(data['rejectionReason'], 'Amount does not match');
    });

    test('saves and reads bank details for the signed-in farmer', () async {
      await service().saveBankDetails(const BankDetails(
        bankName: 'Sampath Bank',
        branch: 'Kandy',
        accountHolderName: 'K. Silva',
        accountNumber: '1234 5678 90',
      ));
      final saved = await service().getBankDetails('farmer1');
      expect(saved.accountNumber, '1234567890');
      expect(saved.isComplete, isTrue);
      await expectLater(() => service().saveBankDetails(BankDetails.empty),
        throwsArgumentError,
      );
    });
  });

  group('OrderPaymentCard localization', () {
    for (final locale in const [Locale('en'), Locale('ta'), Locale('si')]) {
      testWidgets('buyer bank-deposit card fits 360px in ${locale.languageCode}',
          (tester) async {
        tester.view.physicalSize = const Size(360, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final order = FarmoraOrder(
          id: 'o1',
          title: 'Carrots',
          detail: '',
          status: 'accepted',
          progress: 0.2,
          color: Colors.green,
          paymentStatus: 'rejected',
          paymentMethod: PaymentMethod.bankDeposit,
          rejectionReason: 'Blurry',
          totalMinor: 1250000,
          buyerId: 'b1',
          farmerId: 'f1',
          bankDetailsSnapshot: const BankDetails(
            bankName: 'Bank of Ceylon',
            branch: 'Kandy',
            accountHolderName: 'S. Perera',
            accountNumber: '0012345678',
          ),
        );
        await tester.pumpWidget(localizedTestApp(
          Scaffold(
            body: SingleChildScrollView(
              child: OrderPaymentCard(order: order, viewerIsFarmer: false),
            ),
          ),
          locale: locale,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('LKR 12,500.00'), findsWidgets);
        if (locale.languageCode == 'en') {
          expect(find.text('Upload New Receipt'), findsOneWidget);
          expect(find.text('Receipt rejected: Blurry'), findsOneWidget);
        } else {
          expect(find.text('Upload New Receipt'), findsNothing);
        }
      });
    }
  });
}
