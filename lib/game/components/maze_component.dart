import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MazeComponent extends PositionComponent {
  final int mapWidth;
  final int mapHeight;
  final double tileSize;
  final List<List<bool>> walkableGrid;
  final Sprite wallSprite;
  final Sprite floorSprite;

  MazeComponent({
    required this.mapWidth,
    required this.mapHeight,
    required this.tileSize,
    required this.walkableGrid,
    required this.wallSprite,
    required this.floorSprite,
  }) : super(
          size: Vector2(mapWidth * tileSize, mapHeight * tileSize),
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw ambient background shadow under the entire maze
    final bgPaint = Paint()..color = const Color(0xFF161A29);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-6, -6, size.x + 12, size.y + 16),
        const Radius.circular(16),
      ),
      bgPaint,
    );

    // Draw tiles
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        final pos = Vector2(x * tileSize, y * tileSize);
        final isWalkable = walkableGrid[y][x];

        if (isWalkable) {
          floorSprite.render(
            canvas,
            position: pos,
            size: Vector2.all(tileSize),
          );
        } else {
          wallSprite.render(
            canvas,
            position: pos,
            size: Vector2.all(tileSize),
          );
        }
      }
    }
  }
}
