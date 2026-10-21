import 'package:flame/extensions.dart';

class CollisionSystem {
  final int mapWidth;
  final int mapHeight;
  final double tileSize;
  final List<List<bool>> _walkableGrid;
  final List<Rect> _wallRects = [];
  CollisionSystem({
    required this.mapWidth,
    required this.mapHeight,
    required this.tileSize,
    required this._walkableGrid,
  }) {
    // Pre-calculate wall rects for fast collision checking
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        if (!_walkableGrid[y][x]) {
          _wallRects.add(
            Rect.fromLTWH(
              x * tileSize,
              y * tileSize,
              tileSize,
              tileSize,
            ),
          );
        }
      }
    }
  }

  /// Check if a world position with a given margin/radius is within walkable bounds
  bool isWalkable(Vector2 position, {double radius = 4.0}) {
    // Out of bounds check
    final worldW = mapWidth * tileSize;
    final worldH = mapHeight * tileSize;
    if (position.x < 0 || position.x > worldW || position.y < 0 || position.y > worldH) {
      return false;
    }

    // Grid lookup over the tiles the probe square touches (much faster than
    // testing every wall rect).
    final minX = ((position.x - radius) / tileSize).floor();
    final maxX = ((position.x + radius) / tileSize).ceil() - 1;
    final minY = ((position.y - radius) / tileSize).floor();
    final maxY = ((position.y + radius) / tileSize).ceil() - 1;
    for (int gy = minY; gy <= maxY; gy++) {
      for (int gx = minX; gx <= maxX; gx++) {
        if (gx < 0 || gy < 0 || gx >= mapWidth || gy >= mapHeight) return false;
        if (!_walkableGrid[gy][gx]) return false;
      }
    }
    return true;
  }

  /// Check if the straight line segment between p1 and p2 crosses any walls
  bool isSegmentWalkable(Vector2 p1, Vector2 p2, {double step = 4.0, double radius = 4.0}) {
    final dist = p1.distanceTo(p2);
    if (dist <= 0) return isWalkable(p1, radius: radius);

    final steps = (dist / step).ceil();
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final sample = Vector2(
        p1.x + (p2.x - p1.x) * t,
        p1.y + (p2.y - p1.y) * t,
      );
      if (!isWalkable(sample, radius: radius)) {
        return false;
      }
    }
    return true;
  }
}
