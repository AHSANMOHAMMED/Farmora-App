import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/providers/farmora_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin production state', () {
    late FarmoraState state;
    setUp(() => state = FarmoraState());
    tearDown(() => state.dispose());

    test('does not expose seeded users, market data, settlements, or audits',
        () {
      expect(state.users, isEmpty);
      expect(state.marketPrices, isEmpty);
      expect(state.settlements, isEmpty);
      expect(state.auditLogs, isEmpty);
      expect(state.signedIn, isFalse);
    });

    test('admin operations cannot log a fake admin while signed out', () {
      state.logAuditEvent(
        actionType: 'USER_VERIFY',
        targetEntity: 'User',
        targetId: 'user-id',
        details: 'Verification request',
        severity: 'info',
      );
      expect(state.auditLogs, isEmpty);
    });
  });
}
