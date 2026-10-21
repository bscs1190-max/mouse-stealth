import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_find/game/services/level_repository.dart';
import 'package:path_find/game/systems/collision_system.dart';
import 'package:path_find/game/systems/detection_system.dart';
import 'package:path_find/game/systems/navigation_system.dart';
import 'package:path_find/game/systems/scoring_system.dart';

void main() {
  group('CollisionSystem Tests', () {
    test('Correctly identifies walkable and non-walkable positions', () {
      final walkableGrid = [
        [false, false, false],
        [false, true, false],
        [false, false, false],
      ];

      final system = CollisionSystem(
        mapWidth: 3,
        mapHeight: 3,
        tileSize: 32.0,
        walkableGrid: walkableGrid,
      );

      // Center of floor cell (1, 1) -> (48, 48)
      expect(system.isWalkable(Vector2(48, 48), radius: 2.0), isTrue);

      // Inside wall cell (0, 0) -> (16, 16)
      expect(system.isWalkable(Vector2(16, 16), radius: 2.0), isFalse);

      // Line segment crossing through wall from (48, 48) to (16, 16)
      expect(
        system.isSegmentWalkable(Vector2(48, 48), Vector2(16, 16), step: 2.0),
        isFalse,
      );
    });
  });

  group('NavigationSystem (A* Pathfinding) Tests', () {
    test('Finds valid shortest path around obstacles to destination', () {
      // 3x3 grid with center wall:
      // F, F, F
      // F, W, F
      // F, F, F
      final walkableGrid = [
        [true, true, true],
        [true, false, true],
        [true, true, true],
      ];

      final nav = NavigationSystem(
        mapWidth: 3,
        mapHeight: 3,
        tileSize: 32.0,
        walkableGrid: walkableGrid,
      );

      // Path from top-left (16, 16) to bottom-right (80, 80)
      final path = nav.findPath(Vector2(16, 16), Vector2(80, 80));
      expect(path.isNotEmpty, isTrue);
      expect(path.first, equals(Vector2(16, 16)));
      expect(path.last, equals(Vector2(80, 80)));

      // Ensure no path point steps directly into wall (48, 48)
      for (final pt in path) {
        final gridPt = nav.worldToGrid(pt);
        expect(nav.isGridWalkable(gridPt.x, gridPt.y), isTrue);
      }
    });

    test('Returns empty path when destination is completely walled off', () {
      final walkableGrid = [
        [true, false, false],
        [false, false, false],
        [false, false, true],
      ];

      final nav = NavigationSystem(
        mapWidth: 3,
        mapHeight: 3,
        tileSize: 32.0,
        walkableGrid: walkableGrid,
      );

      final path = nav.findPath(Vector2(16, 16), Vector2(80, 80));
      expect(path.isEmpty, isTrue);
    });
  });

  group('DetectionSystem (Line of Sight & Vision Cone) Tests', () {
    test('Detects mouse when directly in front with unobstructed view', () {
      final walkableGrid = [
        [true, true, true, true],
        [true, true, true, true],
      ];

      final collision = CollisionSystem(
        mapWidth: 4,
        mapHeight: 2,
        tileSize: 32.0,
        walkableGrid: walkableGrid,
      );

      final detection = DetectionSystem(collisionSystem: collision);

      // Cat at (16, 16) facing right (0 radians)
      final seesMouse = detection.canSeeTarget(
        observerPos: Vector2(16, 16),
        observerFacingAngle: 0.0,
        targetPos: Vector2(80, 16), // In front within range
        visionRange: 100.0,
        fovDegrees: 70.0,
      );

      expect(seesMouse, isTrue);
    });

    test('Blocks detection when mouse is behind a solid wall', () {
      // Cat (16, 16) -> Wall at col 1 (48, 16) -> Mouse at col 2 (80, 16)
      final walkableGrid = [
        [true, false, true, true],
        [true, false, true, true],
      ];

      final collision = CollisionSystem(
        mapWidth: 4,
        mapHeight: 2,
        tileSize: 32.0,
        walkableGrid: walkableGrid,
      );

      final detection = DetectionSystem(collisionSystem: collision);

      final seesMouse = detection.canSeeTarget(
        observerPos: Vector2(16, 16),
        observerFacingAngle: 0.0,
        targetPos: Vector2(80, 16),
        visionRange: 100.0,
        fovDegrees: 70.0,
      );

      // MUST BE FALSE: Wall blocks Line of Sight!
      expect(seesMouse, isFalse);
    });

    test('Ignores mouse when mouse is behind the cat if FOV is restricted', () {
      final walkableGrid = [
        [true, true, true, true],
        [true, true, true, true],
      ];

      final collision = CollisionSystem(
        mapWidth: 4,
        mapHeight: 2,
        tileSize: 32.0,
        walkableGrid: walkableGrid,
      );

      final detection = DetectionSystem(collisionSystem: collision);

      // Cat at (80, 16) facing right (0 radians), mouse is behind at (16, 16) with 70 degree FOV
      final seesMouse = detection.canSeeTarget(
        observerPos: Vector2(80, 16),
        observerFacingAngle: 0.0,
        targetPos: Vector2(16, 16),
        visionRange: 100.0,
        fovDegrees: 70.0,
      );

      expect(seesMouse, isFalse);
    });

    test('Detects mouse behind the cat when FOV is 360 degrees and unobstructed', () {
      final walkableGrid = [
        [true, true, true, true],
        [true, true, true, true],
      ];

      final collision = CollisionSystem(
        mapWidth: 4,
        mapHeight: 2,
        tileSize: 32.0,
        walkableGrid: walkableGrid,
      );

      final detection = DetectionSystem(collisionSystem: collision);

      // Cat at (80, 16) facing right (0 radians), mouse is behind at (16, 16) with 360 degree awareness
      final seesMouse = detection.canSeeTarget(
        observerPos: Vector2(80, 16),
        observerFacingAngle: 0.0,
        targetPos: Vector2(16, 16),
        visionRange: 100.0,
        fovDegrees: 360.0,
      );

      expect(seesMouse, isTrue);
    });
  });

  group('ScoringSystem Tests', () {
    test('Calculates 3 stars for all cheese and full hearts', () {
      final stars = ScoringSystem.calculateStars(
        reachedHouse: true,
        collectedCheese: 3,
        totalCheese: 3,
        currentHearts: 3,
        initialHearts: 3,
      );
      expect(stars, equals(3));
    });

    test('Calculates 2 stars if some cheese collected or heart lost', () {
      final stars = ScoringSystem.calculateStars(
        reachedHouse: true,
        collectedCheese: 2,
        totalCheese: 3,
        currentHearts: 2,
        initialHearts: 3,
      );
      expect(stars, equals(2));
    });

    test('Calculates 1 star if reached house with 0 cheese', () {
      final stars = ScoringSystem.calculateStars(
        reachedHouse: true,
        collectedCheese: 0,
        totalCheese: 3,
        currentHearts: 1,
        initialHearts: 3,
      );
      expect(stars, equals(1));
    });

    test('Calculates 0 stars if goal not reached', () {
      final stars = ScoringSystem.calculateStars(
        reachedHouse: false,
        collectedCheese: 3,
        totalCheese: 3,
        currentHearts: 3,
        initialHearts: 3,
      );
      expect(stars, equals(0));
    });
  });

  group('Cosmetics & LevelGenerator Tests', () {
    test('LevelGenerator generates valid level maps up to 100 with A* connectivity', () {
      final lvl10 = LevelRepository.getLevel(10);
      expect(lvl10.levelNumber, equals(10));
      expect(lvl10.cats.every((c) => c.visionFovDegrees == 360.0), isTrue);
      expect(lvl10.solutionPath.isNotEmpty, isTrue);

      final lvl50 = LevelRepository.getLevel(50);
      expect(lvl50.levelNumber, equals(50));
      expect(lvl50.theme.name, equals('Frozen Glacier'));
      expect(lvl50.cats.every((c) => c.visionFovDegrees == 360.0), isTrue);

      final lvl100 = LevelRepository.getLevel(100);
      expect(lvl100.levelNumber, equals(100));
      expect(lvl100.theme.name, equals('Celestial Citadel'));
    });
  });
}
