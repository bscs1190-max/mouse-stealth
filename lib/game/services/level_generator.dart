import 'dart:math' as math;
import 'package:flame/extensions.dart';

import '../models/cat_state.dart';
import '../models/power_up.dart';
import '../models/theme_config.dart';
import '../rendering/procedural_obstacle_component.dart';
import '../systems/navigation_system.dart';
import 'level_repository.dart';
import 'level_validator.dart';

enum LevelDifficulty { easy, medium, hard }

extension LevelDifficultyInfo on LevelDifficulty {
  String get tag => switch (this) {
        LevelDifficulty.easy => 'EASY',
        LevelDifficulty.medium => 'MEDIUM',
        LevelDifficulty.hard => 'HARD',
      };
  int get catCount => switch (this) {
        LevelDifficulty.easy => 1,
        LevelDifficulty.medium => 2,
        LevelDifficulty.hard => 3,
      };
}

/// Builds every level from a seeded maze generator and only returns levels
/// that pass [LevelValidator] (reachable house/cheese, a trap-free route, cats
/// on floor tiles and out of sight of the spawn).
class LevelGenerator {
  static const double tileSize = 32.0;

  static LevelDifficulty difficultyFor(int level) {
    if (level % 10 == 0) return LevelDifficulty.hard;
    if (level % 5 == 0) return LevelDifficulty.medium;
    return LevelDifficulty.easy;
  }

  /// Map size in tiles (always odd so the maze carver lines up).
  static (int, int) sizeFor(int level) {
    switch (difficultyFor(level)) {
      case LevelDifficulty.hard:
        return level >= 50 ? (23, 29) : (21, 27);
      case LevelDifficulty.medium:
        return level >= 50 ? (21, 25) : (19, 23);
      case LevelDifficulty.easy:
        if (level <= 3) return (13, 15);
        if (level <= 20) return (15, 19);
        if (level <= 50) return (17, 21);
        return (17, 23);
    }
  }

  static MazeLevelData generate(int level) {
    MazeLevelData? last;
    for (int attempt = 0; attempt < 200; attempt++) {
      final data = _tryBuild(level, math.Random(level * 7919 + attempt * 104729));
      if (data == null) continue;
      last = data;
      if (LevelValidator.validate(data).isEmpty) return data;
    }
    // Should never happen; the audit test guards it.
    return last ?? _tryBuild(level, math.Random(level))!;
  }

  static MazeLevelData? _tryBuild(int level, math.Random rand) {
    final diff = difficultyFor(level);
    final (w, h) = sizeFor(level);
    const t = tileSize;

    // ------------------------------------------------------------------
    // 1. Perfect maze (recursive backtracker on odd cells)
    // ------------------------------------------------------------------
    final grid = List.generate(h, (_) => List.filled(w, false));
    final stack = <GridPoint>[const GridPoint(1, 1)];
    grid[1][1] = true;
    while (stack.isNotEmpty) {
      final cur = stack.last;
      final options = <GridPoint>[];
      for (final d in const [GridPoint(2, 0), GridPoint(-2, 0), GridPoint(0, 2), GridPoint(0, -2)]) {
        final n = GridPoint(cur.x + d.x, cur.y + d.y);
        if (n.x > 0 && n.y > 0 && n.x < w - 1 && n.y < h - 1 && !grid[n.y][n.x]) options.add(n);
      }
      if (options.isEmpty) {
        stack.removeLast();
        continue;
      }
      final next = options[rand.nextInt(options.length)];
      grid[(cur.y + next.y) ~/ 2][(cur.x + next.x) ~/ 2] = true;
      grid[next.y][next.x] = true;
      stack.add(next);
    }

    // ------------------------------------------------------------------
    // 2. Extra openings so there are alternative routes around cats
    // ------------------------------------------------------------------
    final loopChance = switch (diff) {
      LevelDifficulty.easy => level <= 3 ? 0.30 : 0.18,
      LevelDifficulty.medium => 0.20,
      LevelDifficulty.hard => 0.22,
    };
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        if (grid[y][x]) continue;
        final horiz = grid[y][x - 1] && grid[y][x + 1] && !grid[y - 1][x] && !grid[y + 1][x];
        final vert = grid[y - 1][x] && grid[y + 1][x] && !grid[y][x - 1] && !grid[y][x + 1];
        if ((horiz || vert) && rand.nextDouble() < loopChance) grid[y][x] = true;
      }
    }

    // Open courtyards: open space where cats patrol (more on harder levels)
    final rooms = switch (diff) {
      LevelDifficulty.easy => level <= 3 ? 0 : 1,
      LevelDifficulty.medium => 1,
      LevelDifficulty.hard => 2,
    };
    final roomCentres = <GridPoint>[];
    for (int r = 0, tries = 0; r < rooms && tries < 30; tries++) {
      final cx = 3 + rand.nextInt((w - 6) ~/ 2) * 2;
      final cy = 4 + rand.nextInt((h - 8) ~/ 2) * 2;
      // Keep courtyards apart so their cats patrol different areas.
      if (roomCentres.any((o) => (o.x - cx).abs() + (o.y - cy).abs() < 6)) continue;
      r++;
      for (int y = cy - 1; y <= cy + 1; y++) {
        for (int x = cx - 1; x <= cx + 1; x++) {
          if (x > 0 && y > 0 && x < w - 1 && y < h - 1) grid[y][x] = true;
        }
      }
      roomCentres.add(GridPoint(cx, cy));
    }

    // ------------------------------------------------------------------
    // 3. Spawn and house in opposite corners
    // ------------------------------------------------------------------
    final corner = level % 4;
    final spawnG = switch (corner) {
      0 => GridPoint(1, h - 2),
      1 => GridPoint(w - 2, h - 2),
      2 => const GridPoint(1, 1),
      _ => GridPoint(w - 2, 1),
    };
    final houseG = GridPoint(w - 1 - spawnG.x, h - 1 - spawnG.y);
    grid[spawnG.y][spawnG.x] = true;
    grid[houseG.y][houseG.x] = true;

    final distFromSpawn = _bfs(grid, spawnG);
    if (!distFromSpawn.containsKey(houseG)) return null;

    final nav = NavigationSystem(mapWidth: w, mapHeight: h, tileSize: t, walkableGrid: grid);
    final solution = nav.findPath(_pos(spawnG), _pos(houseG));
    final solutionCells = solution.map(nav.worldToGrid).toList();
    final solutionSet = solutionCells.toSet();

    final floor = <GridPoint>[];
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        if (grid[y][x]) floor.add(GridPoint(x, y));
      }
    }
    final used = <GridPoint>{spawnG, houseG};
    bool nearSpawn(GridPoint p, double tiles) {
      final dx = (p.x - spawnG.x).toDouble(), dy = (p.y - spawnG.y).toDouble();
      return math.sqrt(dx * dx + dy * dy) <= tiles;
    }

    // ------------------------------------------------------------------
    // 4. Cats guarding the main route
    // ------------------------------------------------------------------
    final speedBonus = math.min(level * 0.35, 30.0);
    final vision = math.min(82.0 + level * 0.2, 104.0);
    final visionTiles = vision / t + 1.6;
    final cats = <CatConfig>[];
    final catAnchors = <GridPoint>[];
    final catCells = <GridPoint>{};
    for (int i = 0; i < diff.catCount; i++) {
      List<GridPoint>? waypoints;
      // Prefer room loops for the first cats on levels with courtyards.
      if (i < roomCentres.length) {
        // (each courtyard gets its own cat)
        final c = roomCentres[i];
        final loop = [
          GridPoint(c.x - 1, c.y - 1),
          GridPoint(c.x + 1, c.y - 1),
          GridPoint(c.x + 1, c.y + 1),
          GridPoint(c.x - 1, c.y + 1),
        ];
        if (loop.every((p) => grid[p.y][p.x] && !nearSpawn(p, visionTiles + 1))) waypoints = loop;
      }
      for (int tries = 0; waypoints == null && tries < 40; tries++) {
        // Anchor somewhere along the solution path, spread out per cat.
        final lo = 0.3 + 0.55 * i / diff.catCount;
        final idx = ((lo + rand.nextDouble() * 0.25) * (solutionCells.length - 1)).round();
        final a = solutionCells[idx.clamp(0, solutionCells.length - 1)];
        if (nearSpawn(a, visionTiles + 1) || (a.x - houseG.x).abs() + (a.y - houseG.y).abs() < 4) continue;
        if (catAnchors.any((o) => (o.x - a.x).abs() + (o.y - a.y).abs() < 6)) continue;
        // Second point a few steps away, also far from the spawn.
        final fromA = _bfs(grid, a);
        final candidates = fromA.entries
            .where((e) => e.value >= 3 && e.value <= 6 && !nearSpawn(e.key, visionTiles + 1))
            .map((e) => e.key)
            .toList();
        if (candidates.isEmpty) continue;
        final b = candidates[rand.nextInt(candidates.length)];
        final leg = nav.findPath(_pos(a), _pos(b)).map(nav.worldToGrid);
        if (leg.any((p) => nearSpawn(p, visionTiles))) continue;
        waypoints = [a, b];
      }
      if (waypoints == null) return null;
      catAnchors.add(waypoints.first);
      for (int k = 0; k < waypoints.length; k++) {
        final a = waypoints[k], b = waypoints[(k + 1) % waypoints.length];
        catCells.addAll(nav.findPath(_pos(a), _pos(b)).map(nav.worldToGrid));
      }
      cats.add(CatConfig(
        id: 'cat_${level}_$i',
        patrolWaypoints: waypoints.map((p) => [p.x, p.y]).toList(),
        patrolSpeed: 55.0 + speedBonus,
        chaseSpeed: 100.0 + speedBonus,
        visionRange: vision,
        maxChaseSeconds: switch (diff) {
          LevelDifficulty.easy => 2.5,
          LevelDifficulty.medium => 3.0,
          LevelDifficulty.hard => 3.5,
        },
      ));
    }

    // ------------------------------------------------------------------
    // 5. Cheese, power-ups, crates and traps (each checked for fairness)
    // ------------------------------------------------------------------
    final shuffled = [...floor]..shuffle(rand);
    GridPoint? take(bool Function(GridPoint) ok) {
      for (final p in shuffled) {
        if (!used.contains(p) && ok(p)) {
          used.add(p);
          return p;
        }
      }
      return null;
    }

    int gap(GridPoint a, GridPoint b) => (a.x - b.x).abs() + (a.y - b.y).abs();
    final catWaypoints = [for (final c in cats) for (final wp in c.patrolWaypoints) GridPoint(wp[0], wp[1])];
    // Every collectible keeps clear of the spawn, the house, cat waypoints and other items.
    final items = <GridPoint>[spawnG, houseG];
    bool clear(GridPoint p, {int itemGap = 2}) =>
        items.every((o) => gap(o, p) >= itemGap) && catWaypoints.every((o) => gap(o, p) >= 2);

    /// Picks the candidate that is farthest (in steps) from everything already placed,
    /// so items spread over the whole map instead of clumping.
    GridPoint? pickSpread(bool Function(GridPoint) ok) {
      GridPoint? best;
      var bestScore = -1;
      for (final p in shuffled) {
        if (used.contains(p) || !ok(p)) continue;
        final score = items.map((o) => gap(o, p)).reduce(math.min);
        if (score > bestScore) {
          bestScore = score;
          best = p;
        }
      }
      if (best != null) {
        used.add(best);
        items.add(best);
      }
      return best;
    }

    // Cheese: one on the main route (mid-way), two in dead ends spread across the map.
    final cheese = <GridPoint>[];
    final routeLen = solutionCells.length;
    final routeCheese = take((p) {
      final i = solutionCells.indexOf(p);
      return i > routeLen * 0.3 && i < routeLen * 0.65 && clear(p, itemGap: 5);
    });
    if (routeCheese != null) {
      cheese.add(routeCheese);
      items.add(routeCheese);
    }
    while (cheese.length < 3) {
      final c = pickSpread((p) => _isDeadEnd(grid, p) && clear(p, itemGap: 5)) ??
          pickSpread((p) => clear(p, itemGap: 5));
      if (c == null) return null;
      cheese.add(c);
    }

    // Power-ups: on the first half of the journey so they help before the cats.
    final kinds = PowerUpKind.values.where((k) => level >= k.introducedAt).toList();
    final powerUps = <PowerUpPlacement>[];
    final count = kinds.isEmpty ? 0 : (diff == LevelDifficulty.easy ? 1 : 2);
    final newKind = kinds.where((k) => k.introducedAt == level);
    final total = distFromSpawn[houseG]!;
    for (int i = 0; i < count; i++) {
      final unused = kinds.where((k) => powerUps.every((p) => p.kind != k)).toList();
      final pool = unused.isEmpty ? kinds : unused;
      final kind = i == 0 && newKind.isNotEmpty ? newKind.first : pool[rand.nextInt(pool.length)];
      final p = pickSpread((p) {
        final d = distFromSpawn[p] ?? 0;
        return d >= 4 && d <= total * 0.6 && !_isDeadEnd(grid, p) && !catCells.contains(p) && clear(p, itemGap: 3);
      });
      if (p != null) powerUps.add(PowerUpPlacement(kind, _pos(p)));
    }

    final obstacles = <ObstaclePlacement>[];
    final blocked = grid.map((r) => r.map((c) => !c).toList()).toList();
    final traps = <GridPoint>{};
    final mustReach = [houseG, ...cheese, ...powerUps.map((p) => nav.worldToGrid(p.position))];

    /// Everything reachable, and reachable WITHOUT touching a trap.
    bool fair() {
      final safe = _bfs(grid, spawnG, blocked: blocked, avoid: traps);
      return mustReach.every(safe.containsKey);
    }

    // Crates: cover to hide behind (from level 6), off the main route.
    final crateCount = level < 6 ? 0 : math.min(2 + level ~/ 12, 8) + (diff == LevelDifficulty.hard ? 2 : 0);
    for (int i = 0; i < crateCount; i++) {
      final p = take((p) => !solutionSet.contains(p) && !catCells.contains(p) && clear(p));
      if (p == null) break;
      blocked[p.y][p.x] = true;
      if (fair()) {
        obstacles.add(ObstaclePlacement(ObstacleKind.crate, _pos(p)));
      } else {
        blocked[p.y][p.x] = false;
      }
    }

    // Traps (from level 4): placed ON the main route where a detour exists, so
    // they force a smarter path, but never next to items and never clustered.
    final trapCount = level < 4 ? 0 : math.min(1 + level ~/ 10, 8) + (diff == LevelDifficulty.hard ? 2 : 0);
    bool trapOk(GridPoint p) =>
        !catCells.contains(p) && clear(p) && traps.every((o) => gap(o, p) >= 3) && !nearSpawn(p, 3);
    final routeSpots = [...solutionCells.sublist((routeLen * 0.2).round(), (routeLen * 0.9).round())]..shuffle(rand);
    for (final p in [...routeSpots, ...shuffled]) {
      if (traps.length >= trapCount) break;
      if (used.contains(p) || !trapOk(p)) continue;
      traps.add(p);
      if (fair()) {
        used.add(p);
        obstacles.add(ObstaclePlacement(ObstacleKind.trap, _pos(p)));
      } else {
        traps.remove(p);
      }
    }

    final hintPath = nav.findPath(_pos(spawnG), _pos(houseG), avoid: traps);
    final time = (hintPath.length * 1.1 + 30 + diff.catCount * 8).round();

    return MazeLevelData(
      levelNumber: level,
      title: 'Level $level',
      difficultyTag: diff.tag,
      mapWidth: w,
      mapHeight: h,
      tileSize: t,
      walkableGrid: grid,
      mouseSpawn: _pos(spawnG),
      housePosition: _pos(houseG),
      cheesePositions: cheese.map(_pos).toList(),
      obstacles: obstacles,
      cats: cats,
      solutionPath: hintPath,
      theme: ThemeConfig.forLevel(level),
      timeLimitSeconds: time,
      powerUps: powerUps,
      hammerCharges: switch (diff) {
        LevelDifficulty.easy => 1,
        LevelDifficulty.medium => 2,
        LevelDifficulty.hard => 3,
      },
    );
  }

  static bool _isDeadEnd(List<List<bool>> grid, GridPoint p) {
    var open = 0;
    for (final d in const [GridPoint(1, 0), GridPoint(-1, 0), GridPoint(0, 1), GridPoint(0, -1)]) {
      if (grid[p.y + d.y][p.x + d.x]) open++;
    }
    return open == 1;
  }

  static Map<GridPoint, int> _bfs(
    List<List<bool>> grid,
    GridPoint start, {
    List<List<bool>>? blocked,
    Set<GridPoint> avoid = const {},
  }) {
    final h = grid.length, w = grid.first.length;
    final dist = <GridPoint, int>{start: 0};
    final q = [start];
    for (int i = 0; i < q.length; i++) {
      final p = q[i];
      for (final d in const [GridPoint(1, 0), GridPoint(-1, 0), GridPoint(0, 1), GridPoint(0, -1)]) {
        final n = GridPoint(p.x + d.x, p.y + d.y);
        if (n.x < 0 || n.y < 0 || n.x >= w || n.y >= h || !grid[n.y][n.x]) continue;
        if (blocked != null && blocked[n.y][n.x]) continue;
        if (avoid.contains(n) || dist.containsKey(n)) continue;
        dist[n] = dist[p]! + 1;
        q.add(n);
      }
    }
    return dist;
  }

  static Vector2 _pos(GridPoint p) => Vector2((p.x + 0.5) * tileSize, (p.y + 0.5) * tileSize);
}
