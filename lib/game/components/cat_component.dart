import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../models/cat_state.dart';
import '../rendering/procedural_painter.dart';
import '../services/cosmetics_service.dart';
import '../systems/detection_system.dart';
import '../systems/navigation_system.dart';

/// A patrolling cat.
///
/// Movement rule: the cat only ever walks from one tile centre to an
/// orthogonally adjacent walkable tile centre, so it can never cut through or
/// walk on walls. Every decision (next patrol step, next chase step, path back
/// to the route) is made when the cat arrives on a tile centre.
class CatComponent extends PositionComponent {
  final CatConfig config;
  final NavigationSystem nav;
  final DetectionSystem detection;

  static const double catchRadius = 20.0;
  static const double reactionTime = 0.3;
  static const double loseSightGrace = 0.3;
  static const double giveUpCooldown = 1.8;

  CatState state = CatState.patrol;

  /// Full looping patrol route of adjacent tile centres (built with A*).
  final List<Vector2> _route = [];
  int _routeIndex = 0;

  /// Tile centre the cat is currently walking towards.
  Vector2? _target;

  /// Queued tile centres when walking back to the patrol route.
  final List<Vector2> _plan = [];

  double facingAngle = 0.0;
  double _animTimer = 0.0;

  double _reactionTimer = 0.0;
  double _chaseTimer = 0.0;
  double _lostSightTimer = 0.0;
  double _ignoreTimer = 0.0;
  Vector2? _lastKnownMouse;

  CatComponent({
    required this.config,
    required this.nav,
    required this.detection,
  }) : super(size: Vector2(40, 40), anchor: Anchor.center) {
    _buildRoute();
    reset();
  }

  /// Tile centres of the cat's whole patrol loop (read-only view, for level logic).
  List<Vector2> get patrolRoute => _route;

  /// Remaining chase time in 0..1 (for the radar ring).
  double get chaseProgress =>
      state == CatState.chase ? (_chaseTimer / config.maxChaseSeconds).clamp(0.0, 1.0) : 0.0;

  bool get isAlert => state == CatState.detect || state == CatState.chase;

  void _buildRoute() {
    // Snap every waypoint onto a walkable tile (level data may place one on a wall).
    final points = <Vector2>[];
    for (final p in config.patrolWaypoints) {
      final cell = nav.nearestWalkable(GridPoint(p[0], p[1]));
      if (cell == null) continue;
      final w = nav.gridToWorld(cell);
      if (points.isEmpty || points.last != w) points.add(w);
    }
    if (points.isEmpty) return;
    if (points.length == 1) {
      _route.add(points.first);
      return;
    }
    for (int i = 0; i < points.length; i++) {
      final from = points[i];
      final to = points[(i + 1) % points.length];
      final leg = nav.findPath(from, to);
      if (leg.isEmpty) continue;
      for (final p in leg) {
        final snapped = nav.gridToWorld(nav.worldToGrid(p));
        if (_route.isEmpty || _route.last != snapped) _route.add(snapped);
      }
    }
    if (_route.length > 1 && _route.first == _route.last) _route.removeLast();
    if (_route.isEmpty) _route.add(points.first);
  }

  void reset() {
    state = CatState.patrol;
    _routeIndex = 0;
    if (_route.isNotEmpty) position = _route.first.clone();
    _target = null;
    _plan.clear();
    facingAngle = 0.0;
    _reactionTimer = 0.0;
    _chaseTimer = 0.0;
    _lostSightTimer = 0.0;
    _ignoreTimer = 0.0;
    _lastKnownMouse = null;
    frozenTimer = 0.0;
  }

  /// Seconds left of the "freeze" power-up; a frozen cat neither moves nor catches.
  double frozenTimer = 0.0;
  bool get isFrozen => frozenTimer > 0;

  void freeze(double seconds) {
    frozenTimer = math.max(frozenTimer, seconds);
    if (state != CatState.patrol) _startReturn(cooldown: 0.5);
  }

  void updateAI({
    required double dt,
    required Vector2 mousePos,
    required VoidCallback onCaughtMouse,
    bool mouseInvisible = false,
  }) {
    _animTimer += dt;
    if (frozenTimer > 0) {
      frozenTimer -= dt;
      return;
    }
    if (_ignoreTimer > 0) _ignoreTimer -= dt;

    if (!mouseInvisible && position.distanceTo(mousePos) <= catchRadius) {
      onCaughtMouse();
      return;
    }

    // Radar: mouse inside the radius AND not hidden behind a wall.
    final seesMouse = !mouseInvisible &&
        _ignoreTimer <= 0 &&
        detection.canSeeTarget(
          observerPos: position,
          observerFacingAngle: facingAngle,
          targetPos: mousePos,
          visionRange: config.visionRange,
          fovDegrees: config.visionFovDegrees,
        );

    switch (state) {
      case CatState.patrol:
        if (seesMouse) {
          _enterDetect(mousePos);
        } else {
          _walk(dt, config.patrolSpeed, _nextPatrolStep);
        }
        break;

      case CatState.detect:
        if (!seesMouse) {
          // Mouse slipped away before the cat reacted.
          _startReturn(cooldown: 0.0);
          break;
        }
        _face(mousePos);
        _reactionTimer -= dt;
        if (_reactionTimer <= 0) {
          state = CatState.chase;
          _chaseTimer = config.maxChaseSeconds;
          _lostSightTimer = 0.0;
        }
        break;

      case CatState.chase:
        _chaseTimer -= dt;
        if (seesMouse) {
          _lastKnownMouse = mousePos.clone();
          _lostSightTimer = 0.0;
        } else {
          _lostSightTimer += dt;
        }
        if (_lostSightTimer >= loseSightGrace || _chaseTimer <= 0) {
          // Mouse hid behind a wall or chase time ran out: go back to route.
          _startReturn(cooldown: giveUpCooldown);
          break;
        }
        _walk(dt, config.chaseSpeed, () => _nextChaseStep(mousePos));
        break;

      case CatState.returnToPatrol:
        if (seesMouse) {
          _enterDetect(mousePos);
          break;
        }
        _walk(dt, config.patrolSpeed, _nextReturnStep);
        break;
    }
  }

  void _enterDetect(Vector2 mousePos) {
    state = CatState.detect;
    _reactionTimer = reactionTime;
    _lastKnownMouse = mousePos.clone();
    _face(mousePos);
  }

  void _startReturn({required double cooldown}) {
    state = CatState.returnToPatrol;
    _ignoreTimer = cooldown;
    _lastKnownMouse = null;
    _plan.clear();
    // The route is planned once the cat reaches its current tile centre.
  }

  /// Moves towards [_target]; when there is none (or it was reached), asks
  /// [pickNext] for the next adjacent tile centre.
  void _walk(double dt, double speed, Vector2? Function() pickNext) {
    var remaining = speed * dt;
    var guard = 0;
    while (remaining > 0 && guard++ < 4) {
      _target ??= pickNext();
      final target = _target;
      if (target == null) return;

      final dir = target - position;
      final dist = dir.length;
      if (dist <= remaining) {
        position.setFrom(target);
        remaining -= dist;
        _target = null;
      } else {
        dir.scale(1 / dist);
        position.add(dir * remaining);
        facingAngle = math.atan2(dir.y, dir.x);
        remaining = 0;
      }
    }
  }

  Vector2? _nextPatrolStep() {
    if (_route.length < 2) return null;
    // Arrived at the current route point: advance.
    if (position.distanceTo(_route[_routeIndex]) < 0.5) {
      _routeIndex = (_routeIndex + 1) % _route.length;
    }
    final next = _route[_routeIndex];
    if (_isAdjacentOrSame(next)) return next.clone();
    // Off route (should not happen): walk back first.
    _startReturn(cooldown: _ignoreTimer);
    return null;
  }

  Vector2? _nextChaseStep(Vector2 mousePos) {
    final goal = _lastKnownMouse ?? mousePos;
    final myTile = nav.worldToGrid(position);
    final goalTile = nav.worldToGrid(goal);
    if (myTile == goalTile) {
      // Same tile: a straight line inside one walkable tile is safe.
      return goal.clone();
    }
    final path = nav.findPath(nav.gridToWorld(myTile), goal);
    if (path.length < 2) return null;
    return nav.gridToWorld(nav.worldToGrid(path[1]));
  }

  Vector2? _nextReturnStep() {
    if (_plan.isEmpty) {
      if (_route.isEmpty) {
        state = CatState.patrol;
        return null;
      }
      // Snap the decision to the tile the cat is standing on.
      final here = nav.gridToWorld(nav.worldToGrid(position));
      if (position.distanceTo(here) > 0.5) return here;

      var nearest = 0;
      var best = double.infinity;
      for (int i = 0; i < _route.length; i++) {
        final d = here.distanceTo(_route[i]);
        if (d < best) {
          best = d;
          nearest = i;
        }
      }
      if (best < 0.5) {
        _routeIndex = nearest;
        state = CatState.patrol;
        return _nextPatrolStep();
      }
      final path = nav.findPath(here, _route[nearest]);
      for (int i = 1; i < path.length; i++) {
        _plan.add(nav.gridToWorld(nav.worldToGrid(path[i])));
      }
      _routeIndex = nearest;
      if (_plan.isEmpty) {
        state = CatState.patrol;
        return null;
      }
    }
    final next = _plan.removeAt(0);
    if (_plan.isEmpty) state = CatState.patrol;
    return next;
  }

  bool _isAdjacentOrSame(Vector2 p) {
    final a = nav.worldToGrid(position);
    final b = nav.worldToGrid(p);
    return (a.x - b.x).abs() + (a.y - b.y).abs() <= 1;
  }

  void _face(Vector2 p) {
    final to = p - position;
    facingAngle = math.atan2(to.y, to.x);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final radarColor = isFrozen
        ? const Color(0xFF7DD3FC)
        : switch (state) {
            CatState.chase => const Color(0xFFFF3B5C),
            CatState.detect => const Color(0xFFFF9F1A),
            CatState.returnToPatrol => const Color(0xFFB794F6),
            CatState.patrol => const Color(0xFF5EEAD4),
          };

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    if (config.visionFovDegrees >= 350.0) {
      ProceduralPainter.draw360AwarenessZone(
        canvas,
        range: config.visionRange,
        color: radarColor,
        animTimer: _animTimer,
      );
      if (state == CatState.chase) {
        // Countdown ring: how much longer the cat keeps chasing.
        final ring = Paint()
          ..color = radarColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3;
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: 24),
          -math.pi / 2,
          2 * math.pi * chaseProgress,
          false,
          ring,
        );
      }
    } else {
      canvas.rotate(facingAngle);
      ProceduralPainter.drawVisionCone(
        canvas,
        range: config.visionRange,
        fovDegrees: config.visionFovDegrees,
        color: radarColor,
      );
    }
    canvas.restore();

    ProceduralPainter.drawCat(
      canvas,
      Size(size.x, size.y),
      animTimer: _animTimer,
      isAlert: state == CatState.detect || state == CatState.returnToPatrol,
      isChasing: state == CatState.chase,
      skinId: CosmeticsService().equippedCatId,
    );

    if (isFrozen) {
      // Ice block around the frozen cat with a thaw countdown ring.
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(-2, -2, size.x + 4, size.y + 4), const Radius.circular(10));
      canvas.drawRRect(r, Paint()..color = const Color(0x667DD3FC));
      canvas.drawRRect(
        r,
        Paint()
          ..color = const Color(0xFFE0F2FE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      ProceduralPainter.drawAlertIcon(canvas, Offset(size.x / 2, -14), symbol: '❄', color: const Color(0xFF7DD3FC));
      return;
    }

    if (isAlert) {
      ProceduralPainter.drawAlertIcon(canvas, Offset(size.x / 2, -14),
          symbol: '!', color: const Color(0xFFFF3B5C));
    } else if (state == CatState.returnToPatrol) {
      ProceduralPainter.drawAlertIcon(canvas, Offset(size.x / 2, -14),
          symbol: '?', color: const Color(0xFFB794F6));
    }
  }
}
