import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CheeseComponent extends SpriteComponent {
  final int id;
  final Vector2 originalPosition;
  bool isCollected = false;
  double _floatTimer = 0.0;

  CheeseComponent({
    required this.id,
    required Sprite sprite,
    required Vector2 position,
  })  : originalPosition = position.clone(),
        super(
          sprite: sprite,
          size: Vector2(28, 28),
          anchor: Anchor.center,
          position: position,
        );

  void reset() {
    isCollected = false;
    position = originalPosition.clone();
    scale = Vector2.all(1.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isCollected) {
      if (scale.x > 0.05) {
        scale -= Vector2.all(dt * 4.0);
        position.y -= dt * 25.0; // Float up as it pops
      }
      return;
    }

    _floatTimer += dt * 3.5;
    position.y = originalPosition.y + math.sin(_floatTimer + id) * 2.0;
  }

  @override
  void render(Canvas canvas) {
    if (isCollected && scale.x <= 0.05) return;

    // Golden sparkling aura
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 12, glowPaint);

    super.render(canvas);
  }

  void collect() {
    isCollected = true;
  }
}
