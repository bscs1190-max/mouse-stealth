import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../services/cosmetics_service.dart';
import '../models/power_up.dart';
import 'procedural_painter.dart';

class CodeMouseComponent extends PositionComponent {
  final Vector2 spawnPosition;
  bool isMoving = false;
  bool isAlert = false;
  double _animTimer = 0.0;

  // Active navigation path
  List<Vector2> waypoints = [];
  int waypointIndex = 0;
  double speed = 145.0; // pixels per second
  double speedMultiplier = 1.0; // Speed power-up
  bool isGhost = false; // Ghost power-up (drawn translucent)

  CodeMouseComponent({
    required this.spawnPosition,
  }) : super(
          position: spawnPosition.clone(),
          size: Vector2(38, 38),
          anchor: Anchor.center,
        );

  void reset() {
    position = spawnPosition.clone();
    angle = 0.0;
    isMoving = false;
    isAlert = false;
    waypoints.clear();
    waypointIndex = 0;
    scale = Vector2.all(1.0);
  }

  void navigateToPath(List<Vector2> path) {
    if (path.isEmpty) return;
    waypoints = path;
    waypointIndex = 0;
    isMoving = true;
  }

  void stopMoving() {
    waypoints.clear();
    waypointIndex = 0;
    isMoving = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt;

    if (isMoving && waypoints.isNotEmpty && waypointIndex < waypoints.length) {
      final target = waypoints[waypointIndex];
      final dir = target - position;
      final dist = dir.length;
      final moveStep = speed * speedMultiplier * dt;

      if (dist <= moveStep) {
        position = target.clone();
        waypointIndex++;
        if (waypointIndex >= waypoints.length) {
          isMoving = false;
          waypoints.clear();
        }
      } else {
        dir.normalize();
        position += dir * moveStep;
        angle = math.atan2(dir.y, dir.x);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final skinId = CosmeticsService().equippedMouseId;
    if (speedMultiplier > 1.0 && isMoving) {
      // Speed streaks behind the mouse
      final streak = Paint()
        ..color = const Color(0xFFFFE066).withValues(alpha: 0.7)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 3; i++) {
        final y = size.y * (0.35 + i * 0.15);
        canvas.drawLine(Offset(-10.0 - i * 3, y), Offset(2, y), streak);
      }
    }
    if (isGhost) {
      canvas.saveLayer(Offset.zero & Size(size.x, size.y), Paint()..color = const Color(0x73FFFFFF));
    }
    ProceduralPainter.drawMouse(
      canvas,
      Size(size.x, size.y),
      animTimer: _animTimer,
      isHappy: !isMoving && !isAlert,
      skinId: skinId,
    );
    if (isGhost) canvas.restore();
    // If spotted, small alert exclamation mark
    if (isAlert) {
      ProceduralPainter.drawAlertIcon(
        canvas,
        Offset(size.x / 2, -12),
        symbol: '!',
        color: const Color(0xFFFF3366),
      );
    }
  }

  void playVictoryAnimation() {
    scale = Vector2.all(1.3);
  }
}

class CodeHouseComponent extends PositionComponent {
  final Vector2 destinationPoint;
  double _animTimer = 0.0;

  CodeHouseComponent({
    required Vector2 position,
  })  : destinationPoint = position.clone(),
        super(
          position: position,
          size: Vector2(48, 48),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final skinId = CosmeticsService().equippedHouseId;
    ProceduralPainter.drawHouse(
      canvas,
      Size(size.x, size.y),
      animTimer: _animTimer,
      skinId: skinId,
    );
  }
}

class CodeCheeseComponent extends PositionComponent {
  final int id;
  final Vector2 originalPosition;
  bool isCollected = false;

  CodeCheeseComponent({
    required this.id,
    required Vector2 position,
  })  : originalPosition = position.clone(),
        super(
          position: position.clone(),
          size: Vector2(26, 26),
          anchor: Anchor.center,
        );

  void reset() {
    isCollected = false;
    position = originalPosition.clone();
    scale = Vector2.all(1.0);
  }

  void collect() {
    isCollected = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isCollected) {
      if (scale.x > 0.05) {
        scale -= Vector2.all(dt * 4.0);
        position.y -= dt * 25.0;
      }
      return;
    }
  }

  @override
  void render(Canvas canvas) {
    if (isCollected && scale.x <= 0.05) return;
    super.render(canvas);

    // Glowing aura
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 12, glowPaint);

    ProceduralPainter.drawCheese(canvas, Size(size.x, size.y));
  }
}

/// Floating power-up orb the mouse can pick up.
class CodePowerUpComponent extends PositionComponent {
  final PowerUpKind kind;
  bool isCollected = false;
  double _animTimer = 0.0;
  late final TextPainter _icon;

  static const _colors = {
    PowerUpKind.freeze: Color(0xFF38BDF8),
    PowerUpKind.speed: Color(0xFFFACC15),
    PowerUpKind.ghost: Color(0xFFC084FC),
  };

  CodePowerUpComponent({required this.kind, required Vector2 position})
      : super(position: position.clone(), size: Vector2.all(28), anchor: Anchor.center) {
    _icon = TextPainter(
      text: TextSpan(text: kind.emoji, style: const TextStyle(fontSize: 15)),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  Color get color => _colors[kind]!;

  void reset() {
    isCollected = false;
    scale = Vector2.all(1);
  }

  void collect() => isCollected = true;

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt;
    if (isCollected && scale.x > 0.05) scale += Vector2.all(dt * 3); // burst outwards
  }

  @override
  void render(Canvas canvas) {
    if (isCollected) {
      if (scale.x > 1.9) return;
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        13,
        Paint()
          ..color = color.withValues(alpha: (2.0 - scale.x).clamp(0.0, 1.0) * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      return;
    }
    final bob = math.sin(_animTimer * 3) * 2;
    final c = Offset(size.x / 2, size.y / 2 + bob);
    final pulse = 0.5 + 0.5 * math.sin(_animTimer * 4);
    canvas.drawCircle(c, 15 + pulse * 3, Paint()..color = color.withValues(alpha: 0.18 + pulse * 0.12));
    canvas.drawCircle(
      c,
      12,
      Paint()
        ..shader = RadialGradient(colors: [Colors.white, color]).createShader(Rect.fromCircle(center: c, radius: 12)),
    );
    canvas.drawCircle(
      c,
      12,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _icon.paint(canvas, c - Offset(_icon.width / 2, _icon.height / 2));
  }
}
