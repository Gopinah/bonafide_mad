import 'package:flutter_test/flutter_test.dart';
import 'package:bonafide_mad/main.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Fixed: Changed MyApp to BonaproApp to match lib/main.dart
    await tester.pumpWidget(const BonaproApp());

    // Basic verification that splash screen or login exists
    expect(find.text('Bonapro'), findsWidgets);
  });
}
