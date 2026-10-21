import 'package:flutter_test/flutter_test.dart';
import 'package:path_find/main.dart';

void main() {
  testWidgets('Mouse Stealth App Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const MouseMazeApp());
    expect(find.text('MOUSE\nSTEALTH'), findsOneWidget);
    expect(find.text('PLAY  LEVEL 1'), findsOneWidget);
  });
}
