import 'dart:math' as math;
import 'package:flame/components.dart';

class MouseComponent extends SpriteComponent {
  final Vector2 spawnPosition;
  bool isMoving = false;
  double _bounceTimer = 0.0;

  MouseComponent({
    required Sprite sprite,
    required this.spawnPosition,
  }) : super(
          sprite: sprite,
          size: Vector2(36, 36),
          anchor: Anchor.center,
          position: spawnPosition.clone(),
        );

  void reset() {
    position = spawnPosition.clone();
    angle = 0.0;
    isMoving = false;
    scale = Vector2.all(1.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bounceTimer += dt * 4;

    if (!isMoving) {
      // Gentle idle breathing
      final idleScale = 1.0 + math.sin(_bounceTimer) * 0.04;
      scale = Vector2(idleScale, 2.0 - idleScale);
    }
  }

  /// Triggers a victory jump when reaching the house
  void playVictoryAnimation() {
    scale = Vector2.all(1.25);
  }
}
