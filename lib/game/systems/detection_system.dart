import 'dart:math' as math;
import 'package:flame/extensions.dart';

import 'collision_system.dart';

class DetectionSystem {
  final CollisionSystem collisionSystem;

  DetectionSystem({required this.collisionSystem});

  /// Check whether the target position is within the observer's vision cone
  /// AND has an unobstructed Line-of-Sight (LOS) through walls.
  bool canSeeTarget({
    required Vector2 observerPos,
    required double observerFacingAngle, // Radians (0 = Right, pi/2 = Down, etc.)
    required Vector2 targetPos,
    required double visionRange,
    required double fovDegrees,
  }) {
    final dist = observerPos.distanceTo(targetPos);
    // 1. Distance check
    if (dist > visionRange) return false;

    // 2. FOV Angle check
    final toTarget = targetPos - observerPos;
    final targetAngle = math.atan2(toTarget.y, toTarget.x);

    // Normalize angle difference between -pi and pi
    var angleDiff = targetAngle - observerFacingAngle;
    while (angleDiff > math.pi) {
      angleDiff -= 2 * math.pi;
    }
    while (angleDiff < -math.pi) {
      angleDiff += 2 * math.pi;
    }

    final halfFovRad = (fovDegrees * math.pi / 180.0) / 2.0;
    if (angleDiff.abs() > halfFovRad) {
      return false;
    }

    // 3. Line-of-Sight (LOS) Raycast Occlusion Check
    // Raycast from observer to target in steps. If any wall overlaps, LOS is BLOCKED!
    return hasLineOfSight(observerPos, targetPos);
  }

  /// Raycast between two world positions checking if any wall blocks vision
  bool hasLineOfSight(Vector2 from, Vector2 to, {double stepSize = 4.0}) {
    final dist = from.distanceTo(to);
    if (dist <= 0) return true;

    final steps = (dist / stepSize).ceil();
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final sample = Vector2(
        from.x + (to.x - from.x) * t,
        from.y + (to.y - from.y) * t,
      );

      // Vision ray check with a small 2.0 radius
      if (!collisionSystem.isWalkable(sample, radius: 2.0)) {
        return false; // Vision is blocked by a wall!
      }
    }
    return true;
  }
}
