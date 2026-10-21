import 'dart:math' as math;

import 'package:flame/extensions.dart';

import '../models/power_up.dart';
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

    // Blocked-cell grids (true = blocked). `open` is the gate-open state: walls and crates
    // block movement; `closed` additionally blocks the gate tile.
    final open = List.generate(h, (y) => List.generate(w, (x) => !d.walkableGrid[y][x]));
    final traps = <GridPoint>{};
    for (final o in d.obstacles) {
      final c = cell(o.position);
      if (o.kind == ObstacleKind.crate || o.kind == ObstacleKind.bush) open[c.y][c.x] = true;
      if (o.kind == ObstacleKind.trap) traps.add(c);
    }
    // Same grid with the gate shut.
    final closed = [
      for (final row in open) [...row],
    ];
    final gateCell = d.gate == null ? null : cell(d.gate!.gate);
    if (gateCell != null) closed[gateCell.y][gateCell.x] = true;

    final spawn = cell(d.mouseSpawn);
    final house = cell(d.housePosition);
    final cheese = d.cheesePositions.map(cell).toList();
    final powerUps = d.powerUps.map((p) => cell(p.position)).toList();
    final keyCell = d.keyPosition == null ? null : cell(d.keyPosition!);
    final pressCell = d.gate == null ? null : cell(d.gate!.pressSpot);
    final switchWall = d.gate == null ? null : cell(d.gate!.switchWall);
    if (open[spawn.y][spawn.x]) issues.add('mouse spawn is blocked');
    if (open[house.y][house.x]) issues.add('house is blocked');

    Map<GridPoint, int> flood(GridPoint from, List<List<bool>> blockedGrid, {bool avoidTraps = true}) {
      final dist = <GridPoint, int>{from: 0};
      final q = [from];
      for (int i = 0; i < q.length; i++) {
        final p = q[i];
        for (final dlt in _dirs) {
          final n = GridPoint(p.x + dlt.x, p.y + dlt.y);
          if (n.x < 0 || n.y < 0 || n.x >= w || n.y >= h) continue;
          if (blockedGrid[n.y][n.x] || (avoidTraps && traps.contains(n))) continue;
          if (dist.containsKey(n)) continue;
          dist[n] = dist[p]! + 1;
          q.add(n);
        }
      }
      return dist;
    }

    final anyOpen = flood(spawn, open, avoidTraps: false);
    final safeOpenS = flood(spawn, open); // gate open, no traps
    final safeOpenH = flood(house, open);
    final safeClosed = flood(spawn, closed); // gate shut, no traps

    if (!anyOpen.containsKey(house)) {
      issues.add('house is unreachable (path closed)');
    } else if (!safeOpenS.containsKey(house)) {
      issues.add('every route to the house crosses a trap');
    }
    final shortest = safeOpenS[house] ?? 0;
    int detour(GridPoint p) => (safeOpenS[p] ?? 999) + (safeOpenH[p] ?? 999) - shortest;

    // Gate: must really block the house, and everything else is reachable before it opens.
    if (gateCell != null) {
      if (flood(spawn, closed, avoidTraps: false).containsKey(house)) issues.add('the gate does not block the way');
      if (open[switchWall!.y][switchWall.x] == false) issues.add('wall button is not on a wall');
      if (manhattan(switchWall, pressCell!) != 1) issues.add('wall button is not next to its press spot');
      if (!safeClosed.containsKey(pressCell)) issues.add('wall button cannot be reached before the gate');
      if (detour(pressCell) > 10) issues.add('wall button is ${detour(pressCell)} steps off the route');
    }
    final before = gateCell == null ? safeOpenS : safeClosed;

    for (int i = 0; i < cheese.length; i++) {
      final c = cheese[i];
      if (open[c.y][c.x]) {
        issues.add('cheese $i sits inside a wall/crate');
      } else if (!anyOpen.containsKey(c)) {
        issues.add('cheese $i is unreachable');
      } else if (!before.containsKey(c)) {
        issues.add('cheese $i can only be reached through a trap or the gate');
      } else if (detour(c) > 18) {
        issues.add('cheese $i is too far off the route (${detour(c)} steps)');
      }
    }
    if (cheese.isNotEmpty && !cheese.any((c) => detour(c) <= 8)) issues.add('no cheese is on the way to the house');
    for (int i = 0; i < powerUps.length; i++) {
      final p = powerUps[i];
      if (!before.containsKey(p)) {
        issues.add('power-up $i can only be reached through a trap or the gate');
      } else if (detour(p) > 6) {
        issues.add('power-up $i is ${detour(p)} steps off the route, so nobody will grab it');
      } else {
        // Needed most near the cats, measured in WALKING steps (about 3.6 per second):
        // close enough to use before the effect ends, not so close it is inside a cat zone.
        final from = flood(p, open, avoidTraps: false);
        var nearest = 999;
        for (final cat in d.cats) {
          final wp = cat.patrolWaypoints.first;
          nearest = math.min(nearest, from[GridPoint(wp[0], wp[1])] ?? 999);
        }
        if (d.cats.isNotEmpty && (nearest > 16 || nearest < 3)) {
          issues.add("power-up $i is $nearest steps from the nearest cat (want 3-16)");
        }
        if (d.powerUps[i].kind == PowerUpKind.freeze && !cheese.any((c) => (from[c] ?? 999) <= 20)) {
          issues.add("freeze orb $i has no cheese within reach of its 6 seconds");
        }
      }
    }
    if (keyCell != null) {
      if (!before.containsKey(keyCell)) issues.add('key is unreachable before the gate');
      if (detour(keyCell) > 12) issues.add('key is too far off the route');
    }

    // Items must not share/crowd tiles.
    final items = <String, GridPoint>{
      'spawn': spawn,
      'house': house,
      for (int i = 0; i < cheese.length; i++) 'cheese $i': cheese[i],
      for (int i = 0; i < powerUps.length; i++) 'power-up $i': powerUps[i],
      'key': ?keyCell,
      'button': ?pressCell,
      'gate': ?gateCell,
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
        if (p.x < 0 || p.y < 0 || p.x >= w || p.y >= h || open[p.y][p.x]) {
          issues.add('${cat.id} waypoint (${p.x},${p.y}) is on a wall');
          continue;
        }
        if (!before.containsKey(p)) issues.add('${cat.id} waypoint (${p.x},${p.y}) is behind the gate');
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
