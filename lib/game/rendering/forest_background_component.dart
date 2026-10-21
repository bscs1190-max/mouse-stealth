import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../models/theme_config.dart';

class ForestBackgroundComponent extends Component with HasGameRef {
  final ThemeConfig theme;
  double _animTimer = 0.0;

  ForestBackgroundComponent({required this.theme});

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final size = gameRef.size;
    final w = size.x;
    final h = size.y;

    // 1. Dynamic Tier Background Gradient
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: theme.bgGradient,
        center: const Alignment(0.0, -0.1),
        radius: 1.1,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Distant Railroad tracks in upper-right
    _drawTracks(canvas, w - 80, 20, 90, 80);

    // 3. Ambient pine trees themed by world tier
    _drawPineTree(canvas, 10, h * 0.18, 38, 70);
    _drawPineTree(canvas, 18, h * 0.42, 45, 85);
    _drawPineTree(canvas, 8, h * 0.68, 42, 80);

    _drawPineTree(canvas, w - 15, h * 0.22, 40, 75);
    _drawPineTree(canvas, w - 20, h * 0.48, 48, 90);
    _drawPineTree(canvas, w - 12, h * 0.72, 44, 82);

    // 4. Glowing Lantern Lamp-posts on Stone Pedestals with Theme Glow
    _drawLanternPost(canvas, 24, h * 0.32, _animTimer);
    _drawLanternPost(canvas, 24, h * 0.58, _animTimer + 1.2);
    _drawLanternPost(canvas, w - 24, h * 0.38, _animTimer + 0.6);
    _drawLanternPost(canvas, w - 24, h * 0.65, _animTimer + 1.8);
  }

  void _drawPineTree(Canvas canvas, double cx, double cy, double width, double height) {
    final darkPine = Paint()..color = theme.treeFoliageDark;
    final midPine = Paint()..color = theme.treeFoliageMid;

    for (int i = 0; i < 3; i++) {
      final tierW = width * (1.0 - i * 0.2);
      final tierH = height * 0.45;
      final tierY = cy - height * 0.5 + i * (height * 0.26);

      final path = Path();
      path.moveTo(cx, tierY);
      path.lineTo(cx - tierW / 2, tierY + tierH);
      path.lineTo(cx + tierW / 2, tierY + tierH);
      path.close();

      canvas.drawPath(path, i == 1 ? midPine : darkPine);
    }
  }

  void _drawLanternPost(Canvas canvas, double cx, double cy, double timer) {
    final plinthRect = Rect.fromCenter(center: Offset(cx, cy + 16), width: 18, height: 14);
    final stonePaint = Paint()..color = const Color(0xFF283145);
    canvas.drawRRect(RRect.fromRectAndRadius(plinthRect, const Radius.circular(3)), stonePaint);

    final postRect = Rect.fromCenter(center: Offset(cx, cy + 6), width: 5, height: 14);
    final woodPaint = Paint()..color = const Color(0xFF5A3214);
    canvas.drawRect(postRect, woodPaint);

    // Warm Animated Glow
    final flicker = 0.88 + math.sin(timer * 6) * 0.12;
    final glowPaint = Paint()
      ..color = theme.lanternGlow.withValues(alpha: 0.38 * flicker)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(Offset(cx, cy - 2), 22 * flicker, glowPaint);

    // Glass & Housing
    final lanternRect = Rect.fromCenter(center: Offset(cx, cy - 2), width: 12, height: 16);
    final glassPaint = Paint()..color = theme.lanternGlass;
    canvas.drawRRect(RRect.fromRectAndRadius(lanternRect, const Radius.circular(3)), glassPaint);

    final framePaint = Paint()
      ..color = const Color(0xFF1E2430)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(lanternRect, const Radius.circular(3)), framePaint);

    final capPath = Path();
    capPath.moveTo(cx - 8, cy - 10);
    capPath.lineTo(cx, cy - 15);
    capPath.lineTo(cx + 8, cy - 10);
    capPath.close();
    canvas.drawPath(capPath, Paint()..color = const Color(0xFF1E2430));
  }

  void _drawTracks(Canvas canvas, double x, double y, double w, double h) {
    final trackPaint = Paint()
      ..color = const Color(0xFF232D3F)
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(x, y + 10), Offset(x + w, y + h - 10), trackPaint);
    canvas.drawLine(Offset(x + 12, y), Offset(x + w + 12, y + h - 20), trackPaint);

    final tiePaint = Paint()
      ..color = const Color(0xFF3B2816)
      ..strokeWidth = 3.0;
    for (int i = 0; i < 5; i++) {
      final t = i / 4.0;
      final tx = x + w * t;
      final ty = y + h * t;
      canvas.drawLine(Offset(tx - 6, ty + 8), Offset(tx + 14, ty - 8), tiePaint);
    }
  }
}
