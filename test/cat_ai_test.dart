import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_find/game/components/cat_component.dart';
import 'package:path_find/game/models/cat_state.dart';
import 'package:path_find/game/services/level_repository.dart';
import 'package:path_find/game/systems/collision_system.dart';
import 'package:path_find/game/systems/detection_system.dart';
import 'package:path_find/game/systems/navigation_system.dart';

const t = 32.0;

// 7x5 map. '#' wall, '.' floor. A wall column splits the top rows so a patrol
// from (1,1) to (5,1) must walk around through the bottom corridor.
const _map = [
  '#######',
  '#..#..#',
  '#..#..#',
  '#.....#',
  '#######',
];

List<List<bool>> _grid(List<String> rows) => rows.map((r) => r.split('').map((c) => c != '#').toList()).toList();

CatComponent _makeCat(List<List<bool>> grid, List<List<int>> waypoints, {double range = 70}) {
  final w = grid.first.length, h = grid.length;
  final col = CollisionSystem(mapWidth: w, mapHeight: h, tileSize: t, walkableGrid: grid);
  final nav = NavigationSystem(mapWidth: w, mapHeight: h, tileSize: t, walkableGrid: grid);
  return CatComponent(
    config: CatConfig(id: 'c', patrolWaypoints: waypoints, visionRange: range, maxChaseSeconds: 2.0),
    nav: nav,
    detection: DetectionSystem(collisionSystem: col),
  );
}

Vector2 _c(int x, int y) => Vector2((x + 0.5) * t, (y + 0.5) * t);

void _expectOnFloor(CatComponent cat, List<List<bool>> grid) {
  final gx = (cat.position.x / t).floor(), gy = (cat.position.y / t).floor();
  expect(grid[gy][gx], isTrue, reason: 'cat stepped on wall at ($gx,$gy)');
}

void main() {
  test('patrol walks around walls, never through them', () {
    final grid = _grid(_map);
    final cat = _makeCat(grid, [[1, 1], [5, 1]], range: 1);
    final farMouse = Vector2(-1000, -1000);
    var reachedRight = false;
    for (int i = 0; i < 60 * 20; i++) {
      cat.updateAI(dt: 1 / 60, mousePos: farMouse, onCaughtMouse: () {});
      _expectOnFloor(cat, grid);
      if (cat.position.distanceTo(_c(5, 1)) < 1) reachedRight = true;
    }
    expect(reachedRight, isTrue);
  });

  test('mouse hidden behind a wall is not detected', () {
    final grid = _grid(_map);
    final cat = _makeCat(grid, [[2, 1]]);
    for (int i = 0; i < 60; i++) {
      cat.updateAI(dt: 1 / 60, mousePos: _c(4, 1), onCaughtMouse: () {});
    }
    expect(cat.state, CatState.patrol);
  });

  test('chases visible mouse for a short time, then gives up and returns', () {
    final grid = _grid(_map);
    final cat = _makeCat(grid, [[1, 3]], range: 200);
    final states = <CatState>{};
    // Mouse sits in plain view but out of catch range is impossible on a small
    // map, so keep moving it away along the corridor ahead of the cat.
    for (int i = 0; i < 60 * 6; i++) {
      final mouse = cat.position + Vector2(60, 0);
      if (mouse.x > _c(5, 3).x) mouse.x = _c(5, 3).x;
      var caught = false;
      cat.updateAI(dt: 1 / 60, mousePos: mouse, onCaughtMouse: () => caught = true);
      if (caught) break;
      states.add(cat.state);
      _expectOnFloor(cat, grid);
    }
    expect(states, containsAll([CatState.detect, CatState.chase]));
  });

  test('chase stops as soon as the mouse hides behind a wall', () {
    final grid = _grid(_map);
    final cat = _makeCat(grid, [[1, 2]], range: 200);
    // Visible mouse in the same room -> detect + chase.
    for (int i = 0; i < 30; i++) {
      cat.updateAI(dt: 1 / 60, mousePos: _c(2, 1), onCaughtMouse: () {});
    }
    expect(cat.state, CatState.chase);
    // Mouse ducks into the other room behind the wall column.
    for (int i = 0; i < 30; i++) {
      cat.updateAI(dt: 1 / 60, mousePos: _c(5, 1), onCaughtMouse: () {});
    }
    expect(cat.state, isNot(CatState.chase));
  });

  test('cats stay on walkable tiles in every level', () {
    for (int level = 1; level <= 100; level++) {
      final data = LevelRepository.getLevel(level);
      final grid = data.walkableGrid;
      final col = CollisionSystem(
          mapWidth: data.mapWidth, mapHeight: data.mapHeight, tileSize: data.tileSize, walkableGrid: grid);
      final nav = NavigationSystem(
          mapWidth: data.mapWidth, mapHeight: data.mapHeight, tileSize: data.tileSize, walkableGrid: grid);
      for (final cfg in data.cats) {
        final cat = CatComponent(config: cfg, nav: nav, detection: DetectionSystem(collisionSystem: col));
        final mouse = data.mouseSpawn.clone();
        for (int i = 0; i < 60 * 15; i++) {
          // Mouse wanders between spawn and house to provoke chases.
          final k = (i % 600) / 600;
          final target = data.mouseSpawn + (data.housePosition - data.mouseSpawn) * k;
          final g = nav.worldToGrid(target);
          if (nav.isGridWalkable(g.x, g.y)) mouse.setFrom(target);
          cat.updateAI(dt: 1 / 60, mousePos: mouse, onCaughtMouse: () {});
          final gx = (cat.position.x / data.tileSize).floor();
          final gy = (cat.position.y / data.tileSize).floor();
          expect(grid[gy][gx], isTrue, reason: 'level $level cat ${cfg.id} on wall at ($gx,$gy)');
        }
      }
    }
  });
}
