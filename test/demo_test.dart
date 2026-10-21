import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_find/ui/demo/demo_scene.dart';

void main() {
  test('demos are shown only on the level that introduces something', () {
    expect(demosForLevel(1), isEmpty);
    expect(demosForLevel(2), [DemoKind.freeze]);
    expect(demosForLevel(3), [DemoKind.hammer]);
    expect(demosForLevel(4), [DemoKind.trap]);
    expect(demosForLevel(6), [DemoKind.crate]);
    expect(demosForLevel(10), [DemoKind.key]);
    expect(demosForLevel(11), [DemoKind.speed]);
    expect(demosForLevel(15), [DemoKind.gate]);
    expect(demosForLevel(31), [DemoKind.ghost]);
    expect(demosForLevel(32), isEmpty);
  });

  test('every demo has a title and an explanation', () {
    for (final k in DemoKind.values) {
      expect(k.title, isNotEmpty);
      expect(k.caption.length, greaterThan(20));
    }
  });

  testWidgets('every demo paints through its whole loop without errors', (tester) async {
    for (final k in DemoKind.values) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(width: 320, child: DemoView(kind: k)))));
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 430));
        expect(tester.takeException(), isNull, reason: '${k.name} at step $i');
      }
    }
  });
}
