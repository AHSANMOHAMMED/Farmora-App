import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmora/providers/farmora_state.dart';
import 'package:farmora/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('Home screen renders with role selection', skip: true, (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FarmoraState(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
