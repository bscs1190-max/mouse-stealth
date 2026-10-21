import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HouseComponent extends SpriteComponent {
  final Vector2 destinationPoint;
  double _glowTimer = 0.0;

  HouseComponent({
    required Sprite sprite,
    required Vector2 position,
  })  : destinationPoint = position.clone(),
        super(
          sprite: sprite,
          size: Vector2(46, 46),
          anchor: Anchor.center,
          position: position,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _glowTimer += dt * 3;
  }

  @override
  void render(Canvas canvas) {
    // Subtle cozy warm halo behind the house
    final pulse = 0.85 + math.sin(_glowTimer) * 0.15;
    final glowPaint = Paint()
      ..color = const Color(0xFFFFB347).withOpacity(0.35 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 24 * pulse, glowPaint);

    super.render(canvas);
  }
}
