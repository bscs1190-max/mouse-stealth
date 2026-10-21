import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PathComponent extends Component {
  final List<Vector2> points = [];
  final List<Vector2> hintPoints = [];
  bool isInvalid = false;
  double _hintPulse = 0.0;

  void clear() {
    points.clear();
    hintPoints.clear();
    isInvalid = false;
  }

  void addPoint(Vector2 point) {
    if (points.isEmpty) {
      points.add(point.clone());
      return;
    }

    // Only add if there is sufficient minimum spacing to keep path clean & responsive
    final last = points.last;
    if (last.distanceTo(point) >= 4.0) {
      points.add(point.clone());
    }
  }

  void setHint(List<Vector2> path) {
    hintPoints.clear();
    hintPoints.addAll(path.map((p) => p.clone()));
  }

  void clearHint() {
    hintPoints.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _hintPulse += dt * 5;
  }

  @override
  void render(Canvas canvas) {
    // 1. Render Hint Path (Glowing cyan/gold dashed line if active)
    if (hintPoints.length >= 2) {
      final hintPulseAlpha = (0.5 + 0.3 * math.sin(_hintPulse)).clamp(0.2, 0.9);
      final hintGlowPaint = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(hintPulseAlpha)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final hintLinePaint = Paint()
        ..color = const Color(0xFFE0F7FA).withOpacity(hintPulseAlpha)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(hintPoints.first.x, hintPoints.first.y);
      for (int i = 1; i < hintPoints.length; i++) {
        path.lineTo(hintPoints[i].x, hintPoints[i].y);
      }
      canvas.drawPath(path, hintGlowPaint);
      canvas.drawPath(path, hintLinePaint);
    }

    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.x, points.first.y);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }

    if (isInvalid) {
      // Red warning trail on collision
      final errorGlow = Paint()
        ..color = const Color(0xFFFF3366).withOpacity(0.8)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final errorLine = Paint()
        ..color = const Color(0xFFFFB2C2)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, errorGlow);
      canvas.drawPath(path, errorLine);
      return;
    }

    // Outer warm soft glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFB300).withOpacity(0.45)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Inner bright golden trail
    final mainPaint = Paint()
      ..color = const Color(0xFFFFE082)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Center core line
    final corePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, mainPaint);
    canvas.drawPath(path, corePaint);

    // Endpoint cursor bead
    final lastPoint = points.last;
    final beadGlow = Paint()
      ..color = const Color(0xFFFFC107).withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final beadCore = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(lastPoint.x, lastPoint.y), 7, beadGlow);
    canvas.drawCircle(Offset(lastPoint.x, lastPoint.y), 4, beadCore);
  }
}
