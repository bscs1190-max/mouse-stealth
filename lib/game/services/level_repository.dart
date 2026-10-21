import 'package:flame/extensions.dart';

import '../models/cat_state.dart';
import '../models/theme_config.dart';
import '../rendering/procedural_obstacle_component.dart';
import '../models/power_up.dart';
import 'level_generator.dart';

class MazeLevelData {
  final int levelNumber;
  final String title;
  final String difficultyTag;
  final int mapWidth;
  final int mapHeight;
  final double tileSize;
  final List<List<bool>> walkableGrid;
  final Vector2 mouseSpawn;
  final Vector2 housePosition;
  final List<Vector2> cheesePositions;
  final List<ObstaclePlacement> obstacles;
  final List<CatConfig> cats; // Patrolling Cat configurations!
  final List<Vector2> solutionPath; // Precise coordinates for fully working hint system!
  final int timeLimitSeconds;
  final ThemeConfig theme;
  final List<PowerUpPlacement> powerUps;
  final int hammerCharges; // Wall-breaker uses for this level

  const MazeLevelData({
    required this.levelNumber,
    required this.title,
    required this.difficultyTag,
    required this.mapWidth,
    required this.mapHeight,
    required this.tileSize,
    required this.walkableGrid,
    required this.mouseSpawn,
    required this.housePosition,
    required this.cheesePositions,
    required this.obstacles,
    required this.cats,
    required this.solutionPath,
    required this.theme,
    this.timeLimitSeconds = 90,
    this.powerUps = const [],
    this.hammerCharges = 1,
  });
}

class ObstaclePlacement {
  final ObstacleKind kind;
  final Vector2 position;

  const ObstaclePlacement(this.kind, this.position);
}

class LevelRepository {
  static const int levelCount = 100;
  static final Map<int, MazeLevelData> _cache = {};

  /// Every level comes from the validated generator; cached because
  /// generation retries until the level passes all fairness checks.
  static MazeLevelData getLevel(int levelNumber) {
    final n = levelNumber.clamp(1, levelCount);
    return _cache.putIfAbsent(n, () => LevelGenerator.generate(n));
  }
}
