import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'procedural_painter.dart';

enum ObstacleKind {
  trap,
  crate,
  bridgeHorizontal,
  bridgeVertical,
  bush,
}

class ProceduralObstacleComponent extends PositionComponent {
  final ObstacleKind kind;
  bool isTriggered = false;
  double _animTimer = 0.0;

  ProceduralObstacleComponent({
    required this.kind,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt;
  }

  void trigger() {
    isTriggered = true;
  }

  void reset() {
    isTriggered = false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final renderSize = Size(size.x, size.y);

    switch (kind) {
      case ObstacleKind.trap:
        ProceduralPainter.drawMouseTrap(
          canvas,
          renderSize,
          isSprung: isTriggered,
          animTimer: _animTimer,
        );
        break;
      case ObstacleKind.crate:
        ProceduralPainter.drawCrate(canvas, renderSize);
        break;
      case ObstacleKind.bridgeHorizontal:
        ProceduralPainter.drawBridge(canvas, renderSize, isVertical: false);
        break;
      case ObstacleKind.bridgeVertical:
        ProceduralPainter.drawBridge(canvas, renderSize, isVertical: true);
        break;
      case ObstacleKind.bush:
        ProceduralPainter.drawBush(canvas, renderSize);
        break;
    }
  }
}
