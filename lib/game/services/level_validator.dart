import 'package:flame/extensions.dart';

import '../rendering/procedural_obstacle_component.dart';
import '../systems/navigation_system.dart';
import 'level_repository.dart';

/// Static checks that a level is fair, finishable and well laid out.
class LevelValidator {
  static const _dirs = [GridPoint(1, 0), GridPoint(-1, 0), GridPoint(0, 1), GridPoint(0, -1)];

  /// Returns human readable problems; empty when the level is fine.
  static List<String> validate(MazeLevelData d) {
    final issues = <String>[];
    final w = d.mapWidth, h = d.mapHeight, t = d.tileSize;
    GridPoint cell(Vector2 v) => GridPoint((v.x / t).floor(), (v.y / t).floor());
    int manhattan(GridPoint a, GridPoint b) => (a.x - b.x).abs() + (a.y - b.y).abs();

    // Grid as the game sees it: crates and bushes block movement.
    final blocked = List.generate(h, (y) => List.generate(w, (x) => !d.walkableGrid[y][x]));
    final traps = <GridPoint>{};
    final crates = <GridPoint>{};
    for (final o in d.obstacles) {
      final c = cell(o.position);
      if (o.kind == ObstacleKind.crate || o.kind == ObstacleKind.bush) {
        blocked[c.y][c.x] = true;
        crates.add(c);
      }
      if (o.kind == ObstacleKind.trap) traps.add(c);
    }

    final spawn = cell(d.mouseSpawn);
    final house = cell(d.housePosition);
    final cheese = d.cheesePositions.map(cell).toList();
    final powerUps = d.powerUps.map((p) => cell(p.position)).toList();
    if (blocked[spawn.y][spawn.x]) issues.add('mouse spawn is blocked');
    if (blocked[house.y][house.x]) issues.add('house is blocked');

    Map<GridPoint, int> flood(GridPoint from, {bool avoidTraps = false}) {
      final dist = <GridPoint, int>{from: 0};
      final q = [from];
      for (int i = 0; i < q.length; i++) {
        final p = q[i];
        for (final dlt in _dirs) {
          final n = GridPoint(p.x + dlt.x, p.y + dlt.y);
          if (n.x < 0 || n.y < 0 || n.x >= w || n.y >= h) continue;
          if (blocked[n.y][n.x] || (avoidTraps && traps.contains(n))) continue;
          if (dist.containsKey(n)) continue;
          dist[n] = dist[p]! + 1;
          q.add(n);
        }
      }
      return dist;
    }

    final reach = flood(spawn);
    // Everything must be collectable WITHOUT stepping on a trap.
    final safe = flood(spawn, avoidTraps: true);
    if (!reach.containsKey(house)) {
      issues.add('house is unreachable (path closed)');
    } else if (!safe.containsKey(house)) {
      issues.add('every route to the house crosses a trap');
    }
    for (int i = 0; i < cheese.length; i++) {
      final c = cheese[i];
      if (blocked[c.y][c.x]) {
        issues.add('cheese $i sits inside a wall/crate');
      } else if (!reach.containsKey(c)) {
        issues.add('cheese $i is unreachable');
      } else if (!safe.containsKey(c)) {
        issues.add('cheese $i can only be reached through a trap');
      }
    }
    for (int i = 0; i < powerUps.length; i++) {
      if (!safe.containsKey(powerUps[i])) issues.add('power-up $i can only be reached through a trap');
    }

    // Items must not share/crowd tiles.
    final items = <String, GridPoint>{
      'spawn': spawn,
      'house': house,
      for (int i = 0; i < cheese.length; i++) 'cheese $i': cheese[i],
      for (int i = 0; i < powerUps.length; i++) 'power-up $i': powerUps[i],
    };
    final names = items.keys.toList();
    for (int i = 0; i < names.length; i++) {
      for (int j = i + 1; j < names.length; j++) {
        final a = items[names[i]]!, b = items[names[j]]!;
        final minGap = names[i].startsWith('cheese') && names[j].startsWith('cheese') ? 4 : 2;
        if (manhattan(a, b) < minGap) issues.add('${names[i]} is crowded against ${names[j]}');
      }
    }
    for (final trap in traps) {
      for (final e in items.entries) {
        if (manhattan(trap, e.value) < 2) issues.add('trap at (${trap.x},${trap.y}) is right next to ${e.key}');
      }
      for (final other in traps) {
        if (other != trap && manhattan(trap, other) < 3) {
          issues.add('traps at (${trap.x},${trap.y}) are clustered');
          break;
        }
      }
    }

    // Cats
    for (final cat in d.cats) {
      for (final wp in cat.patrolWaypoints) {
        final p = GridPoint(wp[0], wp[1]);
        if (p.x < 0 || p.y < 0 || p.x >= w || p.y >= h || blocked[p.y][p.x]) {
          issues.add('${cat.id} waypoint (${p.x},${p.y}) is on a wall');
        }
        for (final e in items.entries) {
          if (manhattan(p, e.value) < 2) issues.add('${cat.id} waypoint sits on ${e.key}');
        }
      }
      final first = GridPoint(cat.patrolWaypoints.first[0], cat.patrolWaypoints.first[1]);
      final dx = (first.x - spawn.x).toDouble(), dy = (first.y - spawn.y).toDouble();
      if ((dx * dx + dy * dy) * t * t < (cat.visionRange + t) * (cat.visionRange + t)) {
        issues.add('${cat.id} starts close enough to see the mouse spawn');
      }
    }
    for (int i = 0; i < d.cats.length; i++) {
      for (int j = i + 1; j < d.cats.length; j++) {
        final a = d.cats[i].patrolWaypoints.first, b = d.cats[j].patrolWaypoints.first;
        if ((a[0] - b[0]).abs() + (a[1] - b[1]).abs() < 4) {
          issues.add('${d.cats[i].id} and ${d.cats[j].id} start on top of each other');
        }
      }
    }
    return issues;
  }
}
