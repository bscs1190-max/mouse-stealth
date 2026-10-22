import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../ui/art/night_art.dart';
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

    // Board shadow + stone frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-6, 0, w + 12, h + 14), const Radius.circular(18)),
      Paint()
        ..color = const Color(0xAA000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-5, -5, w + 10, h + 10), const Radius.circular(14)),
      Paint()..color = Color.lerp(theme.wallBottom, Colors.black, 0.45)!,
    );

    // Floor: packed earth with pebbles, cracks and soft per-tile variation.
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        if (_wall(x, y)) continue;
        final r = Rect.fromLTWH(x * t, y * t, t, t);
        final rnd = math.Random(x * 73856093 ^ y * 19349663);
        final v = (rnd.nextDouble() - 0.5) * 0.10;
        canvas.drawRect(r, Paint()..color = Color.lerp(theme.floorBase, v > 0 ? Colors.white : Colors.black, v.abs())!);
        // pebbles
        for (int i = 0; i < 3; i++) {
          if (rnd.nextDouble() < 0.55) {
            final p = Offset(r.left + 4 + rnd.nextDouble() * (t - 8), r.top + 4 + rnd.nextDouble() * (t - 8));
            canvas.drawOval(
              Rect.fromCenter(center: p, width: 2.5 + rnd.nextDouble() * 4, height: 2 + rnd.nextDouble() * 2.5),
              Paint()..color = Colors.white.withValues(alpha: 0.07 + rnd.nextDouble() * 0.07),
            );
          }
        }
        // tiny crack
        if (rnd.nextDouble() < 0.12) {
          final a = Offset(r.left + rnd.nextDouble() * t, r.top + rnd.nextDouble() * t);
          canvas.drawLine(a, a + Offset(rnd.nextDouble() * 9 - 4, rnd.nextDouble() * 9 - 4), Paint()
            ..color = Colors.black.withValues(alpha: 0.25)
            ..strokeWidth = 1);
        }
        // grass tuft beside a wall
        if ((_wall(x - 1, y) || _wall(x + 1, y)) && rnd.nextDouble() < 0.18) {
          final gx = _wall(x - 1, y) ? r.left + 4 : r.right - 4;
          final gp = Paint()
            ..color = const Color(0xFF3F8A45).withValues(alpha: 0.8)
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round;
          for (int b = -1; b <= 1; b++) {
            canvas.drawLine(Offset(gx, r.bottom - 4), Offset(gx + b * 3, r.bottom - 11 - rnd.nextDouble() * 3), gp);
          }
        }
      }
    }

    // Moonlight pooling over the board, darker toward the edges.
    final board = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      board,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: [const Color(0x2A9CC4FF), Colors.transparent, const Color(0x55000010)],
          stops: const [0, 0.55, 1],
        ).createShader(board),
    );

    // Walls: brick faces, lit tops where they border floor.
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        if (!_wall(x, y)) continue;
        final r = Rect.fromLTWH(x * t, y * t, t, t);
        NightArt.stoneWall(
          canvas,
          r,
          seed: x * 131 + y * 17,
          top: 8,
          cap: !_wall(x, y - 1),
          shade: !_wall(x, y + 1),
          tint: theme.wallTop,
          moss: !_wall(x, y + 1),
        );
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
