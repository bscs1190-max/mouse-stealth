import 'package:flame/extensions.dart';

class GridPoint {
  final int x;
  final int y;

  const GridPoint(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPoint && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x * 4099 + y;

  @override
  String toString() => '($x, $y)';
}

class _AStarNode {
  final GridPoint point;
  final _AStarNode? parent;
  final double gCost; // Cost from start
  final double hCost; // Heuristic to target

  _AStarNode({
    required this.point,
    this.parent,
    required this.gCost,
    required this.hCost,
  });

  double get fCost => gCost + hCost;
}

class NavigationSystem {
  final int mapWidth;
  final int mapHeight;
  final double tileSize;
  final List<List<bool>> walkableGrid;

  NavigationSystem({
    required this.mapWidth,
    required this.mapHeight,
    required this.tileSize,
    required this.walkableGrid,
  });

  /// Check if a grid point is within bounds and walkable
  bool isGridWalkable(int x, int y) {
    if (x < 0 || x >= mapWidth || y < 0 || y >= mapHeight) return false;
    return walkableGrid[y][x];
  }

  /// Convert world position to grid cell
  GridPoint worldToGrid(Vector2 worldPos) {
    final gx = (worldPos.x / tileSize).floor().clamp(0, mapWidth - 1);
    final gy = (worldPos.y / tileSize).floor().clamp(0, mapHeight - 1);
    return GridPoint(gx, gy);
  }

  /// Convert grid cell to center world position
  Vector2 gridToWorld(GridPoint point) {
    return Vector2(
      (point.x + 0.5) * tileSize,
      (point.y + 0.5) * tileSize,
    );
  }

  /// Find shortest walkable path between start and target world positions.
  /// Returns `List<Vector2>` waypoints, or empty list if unreachable.
  /// Cells in [avoid] (e.g. traps) are only used when there is no other way.
  List<Vector2> findPath(Vector2 startPos, Vector2 targetPos, {Set<GridPoint> avoid = const {}}) {
    final start = worldToGrid(startPos);
    final target = worldToGrid(targetPos);

    if (!isGridWalkable(target.x, target.y)) {
      // Find nearest walkable neighbor to target
      final altTarget = _findNearestWalkableNeighbor(target);
      if (altTarget == null) return [];
      return findPath(startPos, gridToWorld(altTarget), avoid: avoid);
    }

    if (start == target) {
      return [startPos.clone(), targetPos.clone()];
    }

    final openList = <_AStarNode>[];
    final closedSet = <GridPoint>{};
    final openMap = <GridPoint, _AStarNode>{};

    double heuristic(GridPoint a, GridPoint b) {
      return ((a.x - b.x).abs() + (a.y - b.y).abs()).toDouble();
    }

    final startNode = _AStarNode(
      point: start,
      parent: null,
      gCost: 0,
      hCost: heuristic(start, target),
    );

    openList.add(startNode);
    openMap[start] = startNode;

    const directions = [
      GridPoint(0, -1), // Up
      GridPoint(1, 0),  // Right
      GridPoint(0, 1),  // Down
      GridPoint(-1, 0), // Left
    ];

    while (openList.isNotEmpty) {
      // Get node with lowest fCost
      openList.sort((a, b) => a.fCost.compareTo(b.fCost));
      final current = openList.removeAt(0);
      openMap.remove(current.point);
      closedSet.add(current.point);

      if (current.point == target) {
        // Reconstruct path
        return _reconstructPath(current, startPos, targetPos);
      }

      for (final dir in directions) {
        final neighborPt = GridPoint(current.point.x + dir.x, current.point.y + dir.y);

        if (!isGridWalkable(neighborPt.x, neighborPt.y) || closedSet.contains(neighborPt)) {
          continue;
        }

        final tentativeG = current.gCost + (avoid.contains(neighborPt) ? 25.0 : 1.0);
        final existingNeighbor = openMap[neighborPt];

        if (existingNeighbor == null) {
          final neighborNode = _AStarNode(
            point: neighborPt,
            parent: current,
            gCost: tentativeG,
            hCost: heuristic(neighborPt, target),
          );
          openList.add(neighborNode);
          openMap[neighborPt] = neighborNode;
        } else if (tentativeG < existingNeighbor.gCost) {
          final updatedNode = _AStarNode(
            point: neighborPt,
            parent: current,
            gCost: tentativeG,
            hCost: existingNeighbor.hCost,
          );
          openList.remove(existingNeighbor);
          openList.add(updatedNode);
          openMap[neighborPt] = updatedNode;
        }
      }
    }

    return []; // No valid path found
  }

  List<Vector2> _reconstructPath(_AStarNode endNode, Vector2 startPos, Vector2 targetPos) {
    final points = <Vector2>[];
    _AStarNode? curr = endNode;

    while (curr != null) {
      points.add(gridToWorld(curr.point));
      curr = curr.parent;
    }

    final reversed = points.reversed.toList();
    if (reversed.isNotEmpty) {
      reversed[0] = startPos.clone(); // Smooth start from exact entity location
      reversed[reversed.length - 1] = targetPos.clone(); // Exact end
    }
    return reversed;
  }

  /// Closest walkable cell to [pt] (breadth-first), or null if the map has none.
  GridPoint? nearestWalkable(GridPoint pt) {
    if (isGridWalkable(pt.x, pt.y)) return pt;
    final seen = <GridPoint>{pt};
    final queue = <GridPoint>[pt];
    for (int i = 0; i < queue.length; i++) {
      final p = queue[i];
      for (final d in const [GridPoint(0, -1), GridPoint(1, 0), GridPoint(0, 1), GridPoint(-1, 0)]) {
        final n = GridPoint(p.x + d.x, p.y + d.y);
        if (n.x < 0 || n.y < 0 || n.x >= mapWidth || n.y >= mapHeight || !seen.add(n)) continue;
        if (walkableGrid[n.y][n.x]) return n;
        queue.add(n);
      }
    }
    return null;
  }

  GridPoint? _findNearestWalkableNeighbor(GridPoint pt) {
    const offsets = [
      GridPoint(0, -1),
      GridPoint(1, 0),
      GridPoint(0, 1),
      GridPoint(-1, 0),
      GridPoint(-1, -1),
      GridPoint(1, -1),
      GridPoint(-1, 1),
      GridPoint(1, 1),
    ];
    for (final off in offsets) {
      final nx = pt.x + off.x;
      final ny = pt.y + off.y;
      if (isGridWalkable(nx, ny)) return GridPoint(nx, ny);
    }
    return null;
  }
}
