import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmora/app.dart';

void main() {
  testWidgets('Farmora starts with role selection', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FarmoraApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Welcome to'), findsOneWidget);
    expect(find.text('Continue to Farmora'), findsOneWidget);
  });
}
