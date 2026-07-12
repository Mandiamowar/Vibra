import 'package:flutter_test/flutter_test.dart';

import 'package:app_movil/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that our app starts without errors.
    expect(find.text('Vibra Pay'), findsOneWidget);
  });
}