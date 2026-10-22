import 'package:flutter_test/flutter_test.dart';
import 'package:path_find/main.dart';

void main() {
  testWidgets('Mouse Stealth shows the loading screen, then the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MouseMazeApp());
    expect(find.textContaining('LOADING'), findsWidgets);

    // Let the poster load, the loader finish and the fade to home complete.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('PLAY  LEVEL 1'), findsOneWidget);
  });
}
