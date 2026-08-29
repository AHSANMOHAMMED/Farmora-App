import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:farmora/providers/farmora_state.dart';
import 'package:farmora/app.dart';

void main() {
  testWidgets('Farmora app renders', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FarmoraState(),
        child: const FarmoraApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FarmoraApp), findsOneWidget);
  });
}
