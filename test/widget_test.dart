import 'package:flutter_test/flutter_test.dart';

import 'package:farmora/main.dart';

void main() {
  testWidgets('FarmoraApp boots into the splash screen with brand elements',
      (WidgetTester tester) async {
    // Build the real app shell. The splash screen is shown first and does not
    // require Firebase, so this works as a pure widget smoke test.
    await tester.pumpWidget(const FarmoraApp());

    // Splash is displayed with the brand identity while initialization runs.
    expect(find.text('Farmora'), findsOneWidget);
    expect(find.text('Connecting Farmers, Buyers & Transport'), findsOneWidget);

    // The app has not navigated past the splash yet (2.6s timer + transition).
    expect(find.text('Skip'), findsNothing);
  });
}
