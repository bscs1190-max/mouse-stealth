import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

const Color gateColor = Color(0xFFB794F6);

/// Barred gate that blocks a corridor until its wall button is pressed.
class GateComponent extends PositionComponent {
  bool isOpen = false;
  double _open = 0.0; // 0 closed .. 1 open (animated)
  double _t = 0.0;

  GateComponent({required Vector2 position, required double tile})
      : super(position: position, size: Vector2.all(tile), anchor: Anchor.center);

  void reset() {
    isOpen = false;
    _open = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final target = isOpen ? 1.0 : 0.0;
    _open += (target - _open) * math.min(1.0, dt * 7);
  }

  @override
  void render(Canvas canvas) {
    final w = size.x, h = size.y;
    if (_open > 0.97) return;
    final a = (1 - _open).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(1, 1, w - 2, h - 2), const Radius.circular(5)),
      Paint()..color = const Color(0xFF3B2F63).withValues(alpha: a),
    );
    final glow = 0.5 + 0.5 * math.sin(_t * 3);
    final bar = Paint()
      ..color = gateColor.withValues(alpha: a)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    // Bars slide up as the gate opens.
    final lift = _open * h * 0.8;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
    for (int i = 0; i < 4; i++) {
      final x = 6.0 + i * (w - 12) / 3;
      canvas.drawLine(Offset(x, 3 - lift), Offset(x, h - 3 - lift), bar);
    }
    canvas.drawLine(Offset(3, h / 2 - lift), Offset(w - 3, h / 2 - lift), bar);
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(1, 1, w - 2, h - 2), const Radius.circular(5)),
      Paint()
        ..color = gateColor.withValues(alpha: a * (0.4 + 0.4 * glow))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

/// Round button set into a wall. Tap it; the mouse walks over and presses it.
class WallSwitchComponent extends PositionComponent {
  bool pressed = false;
  double _t = 0.0;

  WallSwitchComponent({required Vector2 position, required double tile})
      : super(position: position, size: Vector2.all(tile), anchor: Anchor.center);

  void reset() => pressed = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    final pulse = pressed ? 0.0 : 0.5 + 0.5 * math.sin(_t * 4);
    final color = pressed ? const Color(0xFF34E0C0) : gateColor;
    if (!pressed) {
      canvas.drawCircle(c, 15 + pulse * 3, Paint()..color = color.withValues(alpha: 0.18 + pulse * 0.15));
    }
    canvas.drawCircle(c, 11, Paint()..color = const Color(0xFF1B1538));
    canvas.drawCircle(
      c,
      pressed ? 6.5 : 8.5,
      Paint()
        ..shader = RadialGradient(colors: [Colors.white, color]).createShader(Rect.fromCircle(center: c, radius: 9)),
    );
    canvas.drawCircle(
      c,
      11,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }
}

/// Golden key that unlocks the house.
class KeyComponent extends PositionComponent {
  bool isCollected = false;
  double _t = 0.0;

  KeyComponent({required Vector2 position})
      : super(position: position.clone(), size: Vector2.all(30), anchor: Anchor.center);

  late final Vector2 _home = position.clone();

  void reset() {
    isCollected = false;
    scale = Vector2.all(1);
    position = _home.clone();
  }

  void collect() => isCollected = true;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (isCollected && scale.x > 0.02) {
      scale -= Vector2.all(dt * 4);
      position.y -= dt * 30;
    }
  }

  @override
  void render(Canvas canvas) {
    if (isCollected && scale.x <= 0.05) return;
    final bob = math.sin(_t * 3) * 2;
    final c = Offset(size.x / 2, size.y / 2 + bob);
    canvas.drawCircle(c, 16, Paint()..color = const Color(0xFFFFC23D).withValues(alpha: 0.25));
    drawKeyIcon(canvas, c, 1.0);
  }
}

/// Key glyph drawn with paths so it needs no font or image.
void drawKeyIcon(Canvas canvas, Offset c, double s) {
  final gold = Paint()..color = const Color(0xFFFFC23D);
  final dark = Paint()
    ..color = const Color(0xFF9A5B00)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(-math.pi / 4);
  canvas.scale(s);
  const ring = Offset(-6, 0);
  canvas.drawCircle(ring, 5.2, gold);
  canvas.drawCircle(ring, 2.0, Paint()..color = const Color(0xFF1B1538));
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-1, -1.6, 14, 3.2), const Radius.circular(1.2)), gold);
  canvas.drawRect(const Rect.fromLTWH(8, 1.4, 2.4, 3.6), gold);
  canvas.drawRect(const Rect.fromLTWH(11.6, 1.4, 2.2, 2.8), gold);
  canvas.drawCircle(ring, 5.2, dark);
  canvas.restore();
}

/// Padlock drawn over a locked house.
void drawPadlock(Canvas canvas, Offset c, double s) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.scale(s);
  canvas.drawCircle(Offset.zero, 12, Paint()..color = const Color(0xCC000000));
  canvas.drawArc(
    Rect.fromCenter(center: const Offset(0, -2.5), width: 9, height: 10),
    math.pi,
    math.pi,
    false,
    Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -1.5, 12, 9), const Radius.circular(2)),
    Paint()..color = const Color(0xFFFFC23D),
  );
  canvas.drawCircle(const Offset(0, 2.5), 1.4, Paint()..color = const Color(0xFF9A5B00));
  canvas.restore();
}
