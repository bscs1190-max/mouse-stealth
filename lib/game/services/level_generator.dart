import 'dart:math' as math;
import 'package:flame/extensions.dart';

import '../models/cat_state.dart';
import '../models/level_mechanics.dart';
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
    final distFromHouse = _bfs(grid, houseG);
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
    final catCellSets = <Set<GridPoint>>[]; // patrol cells per cat
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
      final mine = <GridPoint>{};
      for (int k = 0; k < waypoints.length; k++) {
        final a = waypoints[k], b = waypoints[(k + 1) % waypoints.length];
        mine.addAll(nav.findPath(_pos(a), _pos(b)).map(nav.worldToGrid));
      }
      catCells.addAll(mine);
      catCellSets.add(mine);
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
    // 5. Extra mechanics: locked house (key) and/or a gate with a wall button
    // ------------------------------------------------------------------
    int gap(GridPoint a, GridPoint b) => (a.x - b.x).abs() + (a.y - b.y).abs();
    final mech = LevelMechanics.forLevel(
      level,
      hard: diff == LevelDifficulty.hard,
      medium: diff == LevelDifficulty.medium,
    );
    final catWaypoints = [for (final c in cats) for (final wp in c.patrolWaypoints) GridPoint(wp[0], wp[1])];

    GridPoint? gateCell;
    var region = distFromSpawn.keys.toSet();
    if (mech.gate) {
      final routeLen0 = solutionCells.length;
      final candidates = <GridPoint>[
        for (int i = (routeLen0 * 0.62).round(); i < (routeLen0 * 0.92).round(); i++)
          if (!catCells.contains(solutionCells[i]) &&
              gap(solutionCells[i], houseG) >= 2 &&
              catWaypoints.every((c) => gap(c, solutionCells[i]) >= 3))
            solutionCells[i],
      ]..shuffle(rand);
      for (final c in candidates) {
        grid[c.y][c.x] = false;
        final closed = _bfs(grid, spawnG);
        grid[c.y][c.x] = true;
        // The gate must really block the way to the house, with room left to explore.
        if (!closed.containsKey(houseG) && closed.length > 20 && catWaypoints.every(closed.containsKey)) {
          gateCell = c;
          region = closed.keys.toSet();
          break;
        }
      }
      if (gateCell == null) return null;
    }

    // ------------------------------------------------------------------
    // 6. Cheese, key, button, power-ups, crates, traps (all verified)
    // ------------------------------------------------------------------
    final shuffled = [...floor.where(region.contains)]..shuffle(rand);
    GridPoint? take(bool Function(GridPoint) ok) {
      for (final p in shuffled) {
        if (!used.contains(p) && ok(p)) {
          used.add(p);
          return p;
        }
      }
      return null;
    }

    final items = <GridPoint>[spawnG, houseG, ?gateCell];
    if (gateCell != null) used.add(gateCell);
    bool clear(GridPoint p, {int itemGap = 2}) =>
        items.every((o) => gap(o, p) >= itemGap) && catWaypoints.every((o) => gap(o, p) >= 2);

    final total = distFromSpawn[houseG]!;
    // How many steps off the shortest spawn-to-house route a cell is.
    int detour(GridPoint p) => (distFromSpawn[p] ?? 999) + (distFromHouse[p] ?? 999) - total;

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

    // Distance (in tiles) from a cell to the nearest cat patrol cell.
    double toCats(GridPoint p) {
      var best = 999.0;
      for (final c in catCells) {
        final dx = (c.x - p.x).toDouble(), dy = (c.y - p.y).toDouble();
        best = math.min(best, math.sqrt(dx * dx + dy * dy));
      }
      return best;
    }

    // Collectibles stay outside the cats radar when possible, so the cheese and
    // key are a planning puzzle, not an unavoidable catch.
    final radarSafe = visionTiles - 0.4;

    final routeLen = solutionCells.length;

    // ------------------------------------------------------------------
    // Power-ups are placed by WALKING TIME, not by straight-line distance.
    // The mouse covers ~4.5 tiles/s (about 3.6 with turns), so an orb must
    // sit a few steps before a cat's real line of sight, and the cat's whole
    // zone must be crossable while the effect lasts.
    // ------------------------------------------------------------------
    const stepsPerSecond = 3.6;

    /// Straight line of sight between two cells (walls block it).
    bool seesCell(GridPoint a, GridPoint b) {
      final dx = (b.x - a.x).toDouble(), dy = (b.y - a.y).toDouble();
      final n = math.max(1, (math.sqrt(dx * dx + dy * dy) * 4).ceil());
      for (int s = 0; s <= n; s++) {
        final x = (a.x + 0.5 + dx * s / n).floor(), y = (a.y + 0.5 + dy * s / n).floor();
        if (!grid[y][x]) return false;
      }
      return true;
    }

    /// True when a cat of [cat] could actually see this cell from its patrol.
    bool exposedTo(int cat, GridPoint p) {
      for (final c in catCellSets[cat]) {
        final dx = (c.x - p.x).toDouble(), dy = (c.y - p.y).toDouble();
        if (dx * dx + dy * dy <= visionTiles * visionTiles && seesCell(c, p)) return true;
      }
      return false;
    }

    bool exposedAny(GridPoint p) {
      for (int c = 0; c < catCellSets.length; c++) {
        if (exposedTo(c, p)) return true;
      }
      return false;
    }

    int firstExposed(int cat) {
      for (int k = 0; k < routeLen; k++) {
        if (exposedTo(cat, solutionCells[k])) return k;
      }
      return -1;
    }

    int lastExposed(int cat) {
      for (int k = routeLen - 1; k >= 0; k--) {
        if (exposedTo(cat, solutionCells[k])) return k;
      }
      return -1;
    }

    final kinds = PowerUpKind.values.where((k) => level >= k.introducedAt).toList();
    final powerUps = <PowerUpPlacement>[];
    final powerCats = <int>[]; // which cat each power-up is meant for
    final count = kinds.isEmpty ? 0 : (diff == LevelDifficulty.easy ? 1 : 2);
    final newKind = kinds.where((k) => k.introducedAt == level);

    final catOrder = List.generate(cats.length, (i) => i)..sort((a, b) => firstExposed(a).compareTo(firstExposed(b)));
    for (int i = 0; i < count && cats.isNotEmpty; i++) {
      final unused = kinds.where((k) => powerUps.every((p) => p.kind != k)).toList();
      final pool = unused.isEmpty ? kinds : unused;
      final kind = i == 0 && newKind.isNotEmpty ? newKind.first : pool[rand.nextInt(pool.length)];
      final cat = catOrder[i % catOrder.length];
      final entry = firstExposed(cat), exit = lastExposed(cat);
      if (entry < 1) continue;
      final budget = kind.duration * stepsPerSecond; // steps walkable while it lasts
      GridPoint? spot;
      for (final lead in [3, 4, 2, 5, 6, 8]) {
        final k = entry - lead;
        if (k < 1) continue;
        final p = solutionCells[k];
        if (!region.contains(p) || used.contains(p) || catCells.contains(p) || !clear(p, itemGap: 2)) continue;
        if (nearSpawn(p, 3) || exposedAny(p)) continue;
        // Freeze and ghost must outlast the walk across the cat's whole zone.
        if (kind != PowerUpKind.speed && exit - k > budget * 0.8) continue;
        spot = p;
        break;
      }
      if (spot == null) continue;
      used.add(spot);
      items.add(spot);
      powerUps.add(PowerUpPlacement(kind, _pos(spot)));
      powerCats.add(cat);
    }
    if (kinds.isNotEmpty && powerUps.isEmpty) return null;

    // Guarded cheese: with a freeze orb, one cheese sits INSIDE that cat's zone,
    // close enough to grab and leave before the ice melts.
    final cheese = <GridPoint>[];
    final freezeIdx = powerUps.indexWhere((p) => p.kind == PowerUpKind.freeze);
    if (freezeIdx >= 0) {
      final cat = powerCats[freezeIdx];
      final orbCell = nav.worldToGrid(powerUps[freezeIdx].position);
      final fromOrb = _bfs(grid, orbCell);
      final reachBudget = PowerUpKind.freeze.duration * stepsPerSecond * 0.7;
      GridPoint? best;
      var bestD = 999;
      for (final p in shuffled) {
        if (used.contains(p) || catCells.contains(p) || !clear(p, itemGap: 2)) continue;
        final d = fromOrb[p];
        if (d == null || d < 4 || d > reachBudget * 0.75 || detour(p) > 6) continue;
        if (!exposedTo(cat, p)) continue; // really inside the guarded zone
        var nearestPatrol = 999.0;
        for (final c in catCellSets[cat]) {
          final dx = (c.x - p.x).toDouble(), dy = (c.y - p.y).toDouble();
          nearestPatrol = math.min(nearestPatrol, math.sqrt(dx * dx + dy * dy));
        }
        if (nearestPatrol < 1.5) continue; // not right on the cat's path
        if (d < bestD) {
          bestD = d;
          best = p;
        }
      }
      if (best != null) {
        used.add(best);
        items.add(best);
        cheese.add(best);
      }
    }

    // Cheese: one right on the route, two a short detour away (never far side pockets).
    final routeCheese = take((p) {
      final i = solutionCells.indexOf(p);
      return i > routeLen * 0.25 && i < routeLen * 0.6 && clear(p, itemGap: 5) && toCats(p) > radarSafe;
    });
    if (routeCheese != null) {
      cheese.add(routeCheese);
      items.add(routeCheese);
    }
    for (final (maxDetour, strict) in [(10, true), (14, true), (18, true), (14, false), (18, false)]) {
      bool outside(GridPoint p) => !strict || toCats(p) > radarSafe;
      while (cheese.length < 3) {
        final c = pickSpread((p) => detour(p) >= 2 && detour(p) <= maxDetour && _isDeadEnd(grid, p) && clear(p, itemGap: 5)) ??
            pickSpread((p) => detour(p) >= 2 && detour(p) <= maxDetour && clear(p, itemGap: 5) && outside(p));
        if (c == null) break;
        cheese.add(c);
      }
    }
    if (cheese.length < 3) return null;

    // Key: a short detour off the route, away from the cats.
    GridPoint? keyCell;
    if (mech.lockedHouse) {
      for (final strict in [true, false]) {
        keyCell ??= pickSpread((p) =>
            detour(p) >= 4 && detour(p) <= 10 && clear(p, itemGap: 4) && !catCells.contains(p) && (!strict || toCats(p) > radarSafe));
      }
      if (keyCell == null) return null;
    }

    // Wall button: right ON the main route, shortly before the gate, near (but
    // outside) a cat zone, so pressing it is a timing decision, never a long detour.
    GatePlacement? gatePlacement;
    GridPoint? pressCell;
    if (gateCell != null) {
      for (final band in [(0.28, 0.58), (0.15, 0.62)]) {
        GridPoint? best;
        var bestScore = 1e9;
        for (int k = (routeLen * band.$1).round(); k < (routeLen * band.$2).round() && k < routeLen; k++) {
          final p = solutionCells[k];
          if (!region.contains(p) || used.contains(p) || catCells.contains(p) || !clear(p, itemGap: 3)) continue;
          if (_interiorWallNeighbour(grid, p) == null || toCats(p) <= radarSafe) continue;
          final score = (toCats(p) - (radarSafe + 2.5)).abs();
          if (score < bestScore) {
            bestScore = score;
            best = p;
          }
        }
        if (best != null) {
          pressCell = best;
          break;
        }
      }
      if (pressCell == null) return null;
      used.add(pressCell);
      items.add(pressCell);
      final wall = _interiorWallNeighbour(grid, pressCell)!;
      gatePlacement = GatePlacement(
        gate: _pos(gateCell),
        switchWall: _pos(wall),
        pressSpot: _pos(pressCell),
      );
    }


    final obstacles = <ObstaclePlacement>[];
    final blocked = grid.map((r) => r.map((c) => !c).toList()).toList();
    final traps = <GridPoint>{};
    final mustReach = [
      ...cheese,
      ...powerUps.map((p) => nav.worldToGrid(p.position)),
      ?keyCell,
      ?pressCell,
    ];

    /// Everything reachable without touching a trap; the house too once the gate is open.
    bool fair() {
      if (gateCell != null) blocked[gateCell.y][gateCell.x] = true;
      final closed = _bfs(grid, spawnG, blocked: blocked, avoid: traps);
      if (gateCell != null) blocked[gateCell.y][gateCell.x] = false;
      if (!mustReach.every(closed.containsKey)) return false;
      final open = _bfs(grid, spawnG, blocked: blocked, avoid: traps);
      return open.containsKey(houseG);
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

    // Traps (from level 4): on the main route where a detour exists, never
    // beside items or each other.
    final trapCount = level < 4 ? 0 : math.min(1 + level ~/ 10, 8) + (diff == LevelDifficulty.hard ? 2 : 0);
    bool trapOk(GridPoint p) =>
        !catCells.contains(p) && clear(p) && traps.every((o) => gap(o, p) >= 3) && !nearSpawn(p, 3);
    final routeSpots = [...solutionCells.sublist((routeLen * 0.2).round(), (routeLen * 0.9).round())]..shuffle(rand);
    for (final p in [...routeSpots.where(region.contains), ...shuffled]) {
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
    final time = (hintPath.length * 1.1 +
            30 +
            diff.catCount * 8 +
            (keyCell != null ? 14 : 0) +
            (gateCell != null ? 14 : 0))
        .round();

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
      gate: gatePlacement,
      keyPosition: keyCell == null ? null : _pos(keyCell),
    );
  }

  /// An inner (breakable, non-border) wall tile touching [p], for the wall button.
  static GridPoint? _interiorWallNeighbour(List<List<bool>> grid, GridPoint p) {
    final h = grid.length, w = grid.first.length;
    for (final d in const [GridPoint(1, 0), GridPoint(-1, 0), GridPoint(0, 1), GridPoint(0, -1)]) {
      final n = GridPoint(p.x + d.x, p.y + d.y);
      if (n.x > 0 && n.y > 0 && n.x < w - 1 && n.y < h - 1 && !grid[n.y][n.x]) return n;
    }
    return null;
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
