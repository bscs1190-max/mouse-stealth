import 'package:flutter_test/flutter_test.dart';
import 'package:path_find/game/models/power_up.dart';
import 'package:path_find/game/services/level_repository.dart';
import 'package:path_find/game/services/level_validator.dart';

void main() {
  test('all 100 levels are finishable and fair', () {
    final report = <String>[];
    for (int i = 1; i <= 100; i++) {
      final issues = LevelValidator.validate(LevelRepository.getLevel(i));
      if (issues.isNotEmpty) report.add('Level $i: ${issues.join('; ')}');
    }
    expect(report, isEmpty, reason: report.join('\n'));
  });

  test('every 5th level is MEDIUM with 2 cats, every 10th is HARD with 3 cats', () {
    for (int i = 1; i <= 100; i++) {
      final d = LevelRepository.getLevel(i);
      if (i % 10 == 0) {
        expect(d.difficultyTag, 'HARD', reason: 'level $i');
        expect(d.cats.length, 3, reason: 'level $i');
      } else if (i % 5 == 0) {
        expect(d.difficultyTag, 'MEDIUM', reason: 'level $i');
        expect(d.cats.length, 2, reason: 'level $i');
      } else {
        expect(d.difficultyTag, 'EASY', reason: 'level $i');
        expect(d.cats.length, 1, reason: 'level $i');
      }
    }
  });

  test('medium and hard maps are bigger than the easy levels around them', () {
    for (int i = 5; i <= 100; i += 5) {
      final d = LevelRepository.getLevel(i);
      final easy = LevelRepository.getLevel(i - 1);
      expect(d.mapWidth * d.mapHeight, greaterThan(easy.mapWidth * easy.mapHeight), reason: 'level $i');
    }
  });

  test('each power-up appears in the level it is introduced', () {
    for (final k in PowerUpKind.values) {
      final d = LevelRepository.getLevel(k.introducedAt);
      expect(d.powerUps.map((p) => p.kind), contains(k));
    }
    expect(LevelRepository.getLevel(1).powerUps, isEmpty);
  });
}
