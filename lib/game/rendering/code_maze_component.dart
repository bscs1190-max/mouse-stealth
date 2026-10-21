import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../models/theme_config.dart';
import 'procedural_painter.dart';

/// Draws the maze. The static tiles are recorded once into a [ui.Picture]
/// and replayed every frame; call [markDirty] after the grid changes
/// (e.g. a wall was broken).
class CodeMazeComponent extends PositionComponent {
  final int mapWidth;
  final int mapHeight;
  final double tileSize;
  final List<List<bool>> walkableGrid;
  final Vector2 mouseSpawn;
  final Vector2 housePosition;
  final ThemeConfig theme;
  double _animTimer = 0.0;
  ui.Picture? _cache;

  CodeMazeComponent({
    required this.mapWidth,
    required this.mapHeight,
    required this.tileSize,
    required this.walkableGrid,
    required this.mouseSpawn,
    required this.housePosition,
    required this.theme,
  }) : super(size: Vector2(mapWidth * tileSize, mapHeight * tileSize));

  void markDirty() {
    _cache?.dispose();
    _cache = null;
  }

  @override
  void onRemove() {
    markDirty();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt;
  }

  bool _wall(int x, int y) =>
      x < 0 || y < 0 || x >= mapWidth || y >= mapHeight || !walkableGrid[y][x];

  ui.Picture _record() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final t = tileSize;
    final w = size.x, h = size.y;

    // Board shadow + frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-6, 0, w + 12, h + 14), const Radius.circular(18)),
      Paint()
        ..color = const Color(0xAA000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-5, -5, w + 10, h + 10), const Radius.circular(14)),
      Paint()..color = theme.wallBottom,
    );

    // Floor: soft checkerboard
    final floorA = Paint()..color = theme.floorBase;
    final floorB = Paint()..color = Color.lerp(theme.floorBase, Colors.white, 0.035)!;
    final dot = Paint()..color = theme.floorSeam.withValues(alpha: 0.8);
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        if (_wall(x, y)) continue;
        final r = Rect.fromLTWH(x * t, y * t, t, t);
        canvas.drawRect(r, (x + y).isEven ? floorA : floorB);
        canvas.drawCircle(r.center, 1.2, dot);
      }
    }

    // Walls: a dark base (depth) with a lighter raised top face.
    const lift = 5.0;
    final basePaint = Paint()..color = Color.lerp(theme.wallBottom, Colors.black, 0.35)!;
    final edge = Paint()
      ..color = theme.wallHighlight
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        if (!_wall(x, y)) continue;
        final r = Rect.fromLTWH(x * t, y * t, t, t);
        canvas.drawRect(r, basePaint);
      }
    }
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        if (!_wall(x, y)) continue;
        final up = _wall(x, y - 1), down = _wall(x, y + 1);
        final left = _wall(x - 1, y), right = _wall(x + 1, y);
        // Merge the top face with wall neighbours so walls read as one block.
        final face = Rect.fromLTRB(
          x * t + (left ? 0 : 1.5),
          y * t - (up ? 0 : lift) + (up ? 0 : 1.5),
          (x + 1) * t - (right ? 0 : 1.5),
          (y + 1) * t - (down ? 0 : lift),
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            face,
            topLeft: Radius.circular(!up && !left ? 6 : 0),
            topRight: Radius.circular(!up && !right ? 6 : 0),
            bottomLeft: Radius.circular(!down && !left ? 6 : 0),
            bottomRight: Radius.circular(!down && !right ? 6 : 0),
          ),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.wallTop, Color.lerp(theme.wallTop, theme.wallBottom, 0.55)!],
            ).createShader(face),
        );
        if (!up) canvas.drawLine(face.topLeft + const Offset(4, 0.5), face.topRight + const Offset(-4, 0.5), edge);
        if (!down) {
          // Shadow cast onto the floor below
          canvas.drawRect(
            Rect.fromLTWH(x * t, (y + 1) * t, t, 5),
            Paint()..color = const Color(0x55000000),
          );
        }
      }
    }
    return recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawPicture(_cache ??= _record());

    // Animated spawn and house pads
    final spawnRect = Rect.fromCenter(
      center: Offset(mouseSpawn.x, mouseSpawn.y),
      width: tileSize * 1.1,
      height: tileSize * 1.1,
    );
    canvas.save();
    canvas.translate(spawnRect.left, spawnRect.top);
    ProceduralPainter.drawGlowingPad(canvas, Size(spawnRect.width, spawnRect.height), animTimer: _animTimer);
    canvas.restore();

    final houseRect = Rect.fromCenter(
      center: Offset(housePosition.x, housePosition.y),
      width: tileSize * 1.25,
      height: tileSize * 1.25,
    );
    canvas.save();
    canvas.translate(houseRect.left, houseRect.top);
    ProceduralPainter.drawGlowingPad(canvas, Size(houseRect.width, houseRect.height), isGoal: true, animTimer: _animTimer);
    canvas.restore();
  }
}
