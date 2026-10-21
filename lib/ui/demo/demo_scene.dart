import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/models/level_mechanics.dart';
import '../../game/models/power_up.dart';
import '../../game/rendering/mechanic_components.dart';
import '../../game/rendering/procedural_painter.dart';

/// Things the player can be shown a looping mini-demo of.
enum DemoKind {
  goal,
  tapMove,
  radar,
  zoomPan,
  hammer,
  trap,
  crate,
  freeze,
  speed,
  ghost,
  key,
  gate,
}

extension DemoInfo on DemoKind {
  String get title => switch (this) {
        DemoKind.goal => 'Reach the house',
        DemoKind.tapMove => 'Tap to move',
        DemoKind.radar => 'Dodge the cat radar',
        DemoKind.zoomPan => 'Pinch and drag',
        DemoKind.hammer => 'Smash a wall',
        DemoKind.trap => 'Avoid the traps',
        DemoKind.crate => 'Hide behind cover',
        DemoKind.freeze => 'Freeze power-up',
        DemoKind.speed => 'Speed power-up',
        DemoKind.ghost => 'Ghost power-up',
        DemoKind.key => 'Find the key',
        DemoKind.gate => 'Open the gate',
      };

  String get caption => switch (this) {
        DemoKind.goal => 'Guide the mouse to the house. Grab the cheese on the way to earn stars.',
        DemoKind.tapMove => 'Tap any tile and the mouse walks there by itself.',
        DemoKind.radar =>
          'A cat that sees you inside its radar chases you for a few seconds. Stay outside it, or hide behind walls.',
        DemoKind.zoomPan => 'Pinch with two fingers to zoom. Drag with one finger to look around the map.',
        DemoKind.hammer => 'Tap BREAK, then tap a wall or crate to smash it and open a new shortcut.',
        DemoKind.trap => 'Traps cost a heart. Tap a tile and the mouse already walks around known traps.',
        DemoKind.crate => 'Walls and crates block a cat\'s view. Hide behind them while the cat passes.',
        DemoKind.freeze =>
          'Grab the orb just before a cat. Every cat freezes in ice for 6 seconds: walk past it and grab the guarded cheese.',
        DemoKind.speed => 'Grab the orb and the mouse runs much faster for 5 seconds. Outrun the chase.',
        DemoKind.ghost => 'Grab the orb and cats cannot see or catch you for 6 seconds.',
        DemoKind.key => 'The house is locked. Collect the golden key first, then go home.',
        DemoKind.gate => 'A gate blocks the way. Tap the glowing wall button: the mouse presses it and the gate opens.',
      };
}

/// Demos to show on a level's intro card: only things introduced in that level.
List<DemoKind> demosForLevel(int level) {
  return [
    for (final k in PowerUpKind.values)
      if (k.introducedAt == level)
        switch (k) {
          PowerUpKind.freeze => DemoKind.freeze,
          PowerUpKind.speed => DemoKind.speed,
          PowerUpKind.ghost => DemoKind.ghost,
        },
    if (level == 3) DemoKind.hammer,
    if (level == 4) DemoKind.trap,
    if (level == 6) DemoKind.crate,
    if (level == LevelMechanics.firstKeyLevel) DemoKind.key,
    if (level == LevelMechanics.firstGateLevel) DemoKind.gate,
  ];
}

/// Looping animated demo (about 5 seconds) drawn entirely with code.
class DemoView extends StatefulWidget {
  final DemoKind kind;
  final double height;
  const DemoView({super.key, required this.kind, this.height = 150});

  @override
  State<DemoView> createState() => _DemoViewState();
}

class _DemoViewState extends State<DemoView> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(painter: _DemoPainter(widget.kind, _c.value)),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Painter. Everything is drawn in a 300 x 150 space (10 x 5 tiles of 30px).
// -----------------------------------------------------------------------------
class _DemoPainter extends CustomPainter {
  final DemoKind kind;
  final double t;
  _DemoPainter(this.kind, this.t);

  static const double w = 300, h = 150, ts = 30;
  static const _wall = Color(0xFF5A48A3);
  static const _wallTop = Color(0xFF7B6AC4);
  static const _floor = Color(0xFF1B1838);
  static const _teal = Color(0xFF5EEAD4);
  static const _red = Color(0xFFFF3B5C);
  static const _ice = Color(0xFF7DD3FC);

  double seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
  double ease(double x) => x * x * (3 - 2 * x);
  Offset lerp(Offset a, Offset b, double x) => Offset.lerp(a, b, x)!;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / w, size.height / h);
    canvas.save();
    canvas.translate((size.width - w * s) / 2, (size.height - h * s) / 2);
    canvas.scale(s);
    canvas.clipRect(const Rect.fromLTWH(0, 0, w, h));
    _background(canvas);
    switch (kind) {
      case DemoKind.goal:
        _goal(canvas);
      case DemoKind.tapMove:
        _tapMove(canvas);
      case DemoKind.radar:
        _radar(canvas);
      case DemoKind.zoomPan:
        _zoomPan(canvas);
      case DemoKind.hammer:
        _hammer(canvas);
      case DemoKind.trap:
        _trap(canvas);
      case DemoKind.crate:
        _crate(canvas);
      case DemoKind.freeze:
        _powerRun(canvas, DemoKind.freeze);
      case DemoKind.speed:
        _powerRun(canvas, DemoKind.speed);
      case DemoKind.ghost:
        _powerRun(canvas, DemoKind.ghost);
      case DemoKind.key:
        _key(canvas);
      case DemoKind.gate:
        _gate(canvas);
    }
    canvas.restore();
  }

  // ---- building blocks --------------------------------------------------------
  void _background(Canvas c) {
    c.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = _floor);
    final seam = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 1;
    for (double x = 0; x <= w; x += ts) {
      c.drawLine(Offset(x, 0), Offset(x, h), seam);
    }
    for (double y = 0; y <= h; y += ts) {
      c.drawLine(Offset(0, y), Offset(w, y), seam);
    }
  }

  /// A wall block covering tile (x, y).
  void _wallTile(Canvas c, int x, int y, {double alpha = 1}) {
    final r = Rect.fromLTWH(x * ts + 1, y * ts + 1, ts - 2, ts - 2);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), Paint()..color = _wall.withValues(alpha: alpha));
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.5), const Radius.circular(5)),
      Paint()..color = _wallTop.withValues(alpha: 0.5 * alpha),
    );
  }

  /// Top and bottom wall rows, leaving the three middle rows open (a wide hall).
  void _hall(Canvas c, {bool corridor = false}) {
    for (int x = 0; x < 10; x++) {
      _wallTile(c, x, 0);
      _wallTile(c, x, 4);
      if (corridor) {
        _wallTile(c, x, 1);
        _wallTile(c, x, 3);
      }
    }
  }

  void _at(Canvas c, Offset centre, double sz, void Function(Size) draw) {
    c.save();
    c.translate(centre.dx - sz / 2, centre.dy - sz / 2);
    draw(Size(sz, sz));
    c.restore();
  }

  void _mouse(Canvas c, Offset p, {double alpha = 1, bool happy = false}) {
    if (alpha < 1) c.saveLayer(Rect.fromCircle(center: p, radius: 24), Paint()..color = Colors.white.withValues(alpha: alpha));
    _at(c, p, 28, (s) => ProceduralPainter.drawMouse(c, s, animTimer: t * 20, isHappy: happy));
    if (alpha < 1) c.restore();
  }

  void _cat(Canvas c, Offset p, {bool chasing = false, bool alert = false, bool frozen = false}) {
    _at(c, p, 30, (s) => ProceduralPainter.drawCat(c, s, animTimer: t * 20, isAlert: alert, isChasing: chasing));
    if (frozen) {
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 36, height: 36), const Radius.circular(9));
      c.drawRRect(r, Paint()..color = const Color(0x667DD3FC));
      c.drawRRect(
        r,
        Paint()
          ..color = const Color(0xFFE0F2FE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _radarRing(Canvas c, Offset p, double r, Color color) {
    final pulse = 0.94 + 0.06 * math.sin(t * math.pi * 12);
    c.drawCircle(
      p,
      r * pulse,
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.05)])
            .createShader(Rect.fromCircle(center: p, radius: r)),
    );
    c.drawCircle(
      p,
      r * pulse,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _icon(Canvas c, IconData icon, Offset p, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontSize: size, fontFamily: icon.fontFamily, package: icon.fontPackage, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, p - Offset(tp.width / 2, tp.height / 2));
  }

  void _orb(Canvas c, Offset p, DemoKind k, {double scale = 1}) {
    final color = switch (k) {
      DemoKind.freeze => const Color(0xFF38BDF8),
      DemoKind.speed => const Color(0xFFFACC15),
      _ => const Color(0xFFC084FC),
    };
    final icon = switch (k) {
      DemoKind.freeze => Icons.ac_unit_rounded,
      DemoKind.speed => Icons.bolt_rounded,
      _ => Icons.visibility_off_rounded,
    };
    final bob = math.sin(t * math.pi * 10) * 2;
    final centre = p + Offset(0, bob);
    c.drawCircle(centre, 17 * scale, Paint()..color = color.withValues(alpha: 0.22));
    c.drawCircle(
      centre,
      12 * scale,
      Paint()..shader = RadialGradient(colors: [Colors.white, color]).createShader(Rect.fromCircle(center: centre, radius: 12 * scale)),
    );
    _icon(c, icon, centre, 15 * scale, const Color(0xFF1B1538));
  }

  void _finger(Canvas c, Offset p, {bool down = false, double ripple = 0}) {
    if (ripple > 0 && ripple < 1) {
      c.drawCircle(
        p,
        8 + ripple * 24,
        Paint()
          ..color = Colors.white.withValues(alpha: 1 - ripple)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    c.drawCircle(p + const Offset(0, 3), 11, Paint()..color = Colors.black.withValues(alpha: 0.3));
    c.drawCircle(p, 11, Paint()..color = Colors.white.withValues(alpha: down ? 0.95 : 0.7));
    c.drawCircle(
      p,
      11,
      Paint()
        ..color = const Color(0xFF8B7CFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _bang(Canvas c, Offset p, String symbol, Color color) {
    c.drawCircle(p, 10, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(text: symbol, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, p - Offset(tp.width / 2, tp.height / 2));
  }

  Offset _along(List<Offset> pts, double x) {
    if (x <= 0) return pts.first;
    if (x >= 1) return pts.last;
    var total = 0.0;
    for (int i = 0; i < pts.length - 1; i++) {
      total += (pts[i + 1] - pts[i]).distance;
    }
    var d = x * total;
    for (int i = 0; i < pts.length - 1; i++) {
      final l = (pts[i + 1] - pts[i]).distance;
      if (d <= l) return lerp(pts[i], pts[i + 1], d / l);
      d -= l;
    }
    return pts.last;
  }

  void _dashed(Canvas c, List<Offset> pts, Color color) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 10) {
        c.drawPath(
          m.extractPath(d, math.min(d + 5, m.length)),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  // ---- scenes ----------------------------------------------------------------
  void _goal(Canvas c) {
    _hall(c, corridor: true);
    const house = Offset(255, 75), cheese = Offset(130, 75);
    _at(c, house, 44, (s) => ProceduralPainter.drawHouse(c, s, animTimer: t * 20));
    final p = lerp(const Offset(30, 75), house - const Offset(22, 0), ease(seg(0.1, 0.8)));
    final taken = p.dx >= cheese.dx - 6;
    if (!taken) _at(c, cheese, 26, (s) => ProceduralPainter.drawCheese(c, s));
    _mouse(c, p, happy: t > 0.8);
    if (taken) {
      _bang(c, Offset(cheese.dx, 40), '+1', const Color(0xFFF08A00));
    }
    if (t > 0.82) {
      for (int i = 0; i < 3; i++) {
        _icon(c, Icons.star_rounded, Offset(105 + i * 45, 28), 30, const Color(0xFFFFC23D));
      }
    }
  }

  void _tapMove(Canvas c) {
    _hall(c, corridor: true);
    const target = Offset(240, 75);
    final move = ease(seg(0.3, 0.8));
    final p = lerp(const Offset(40, 75), target, move);
    if (move < 1) {
      c.drawCircle(
        target,
        10 + 3 * math.sin(t * 40),
        Paint()
          ..color = const Color(0xFF34E0C0).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    _mouse(c, p);
    final tap = seg(0.12, 0.3);
    if (t < 0.4) _finger(c, target + Offset(0, 22 - 22 * math.min(1, tap * 2)), down: tap > 0.5, ripple: tap > 0.5 ? (tap - 0.5) * 2 : 0);
  }

  void _radar(Canvas c) {
    _hall(c);
    const cat = Offset(150, 60);
    final phase = t < 0.5 ? 0 : 1;
    final x = (t < 0.5 ? t * 2 : (t - 0.5) * 2);
    if (phase == 0) {
      // Mistake: walk straight through the radar.
      final mouse = Offset(30 + 140 * ease(seg(0, 0.28)), 60);
      final seen = mouse.dx > 150 - 55 + 6;
      final catPos = seen ? lerp(cat, mouse + const Offset(30, 0), 0.0) : cat;
      _radarRing(c, cat, 55, seen ? _red : _teal);
      _cat(c, catPos, chasing: seen, alert: seen);
      _mouse(c, seen ? mouse + Offset(-ease(seg(0.3, 0.48)) * 90, 0) : mouse);
      if (seen) _bang(c, Offset(cat.dx, 22), '!', _red);
      _bang(c, const Offset(270, 128), 'x', _red);
    } else {
      // Right way: skirt the radar along the bottom row.
      final pts = [const Offset(30, 60), const Offset(30, 118), const Offset(270, 118)];
      _radarRing(c, cat, 55, _teal);
      _cat(c, cat);
      _mouse(c, _along(pts, ease(x * 1.1)));
      _icon(c, Icons.check_circle_rounded, const Offset(270, 30), 26, const Color(0xFF22C55E));
    }
  }

  void _zoomPan(Canvas c) {
    // Mini map: pinch out, then drag.
    final zoomIn = ease(seg(0.1, 0.45));
    final pan = ease(seg(0.55, 0.9));
    final s = 1 + 0.7 * zoomIn;
    c.save();
    c.translate(w / 2, h / 2);
    c.scale(s);
    c.translate(-w / 2 - 120 * pan, -h / 2);
    for (int x = 0; x < 12; x++) {
      _wallTile(c, x, 0);
      _wallTile(c, x, 4);
      if (x % 3 == 1) {
        _wallTile(c, x, 1);
        _wallTile(c, x, 2);
      }
      if (x % 3 == 2) _wallTile(c, x, 3);
    }
    _mouse(c, const Offset(120, 75));
    _at(c, const Offset(330, 75), 44, (sz) => ProceduralPainter.drawHouse(c, sz, animTimer: t * 20));
    c.restore();
    if (t < 0.5) {
      final d = 18 + 42 * zoomIn;
      const centre = Offset(w / 2, h / 2);
      _finger(c, centre + Offset(-d, d * 0.5), down: true);
      _finger(c, centre + Offset(d, -d * 0.5), down: true);
      _icon(c, Icons.zoom_out_map_rounded, const Offset(40, 30), 24, Colors.white70);
    } else {
      final f = const Offset(200, 95) + Offset(-90 * pan, 0);
      _finger(c, f, down: true);
      _icon(c, Icons.swipe_left_rounded, const Offset(40, 30), 26, Colors.white70);
    }
  }

  void _hammer(Canvas c) {
    _hall(c, corridor: true);
    // Wall block in the corridor that gets smashed.
    final smash = seg(0.42, 0.5);
    if (smash < 1) _wallTile(c, 5, 2, alpha: 1 - smash);
    if (smash > 0 && smash < 1) {
      for (int i = 0; i < 8; i++) {
        final a = i / 8 * math.pi * 2;
        c.drawCircle(
          Offset(165, 75) + Offset(math.cos(a), math.sin(a)) * (10 + 30 * smash),
          3.5 * (1 - smash),
          Paint()..color = const Color(0xFFE7D7B5),
        );
      }
    }
    // BREAK button drawn on the lower left
    final btnOn = t > 0.14 && t < 0.42;
    final btn = RRect.fromRectAndRadius(const Rect.fromLTWH(14, 108, 72, 28), const Radius.circular(10));
    c.drawRRect(btn, Paint()..color = btnOn ? const Color(0xFFC81D4E) : const Color(0xFFF08A00));
    final tp = TextPainter(
      text: const TextSpan(text: 'BREAK', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(50 - tp.width / 2, 122 - tp.height / 2));
    final x = ease(seg(0.5, 0.95));
    _mouse(c, lerp(const Offset(40, 75), const Offset(262, 75), x));
    if (t < 0.14) {
      _finger(c, Offset(50 + 140 * (1 - seg(0, 0.1)) * 0, 122) + Offset(0, 24 * (1 - seg(0, 0.1))));
    } else if (t < 0.24) {
      _finger(c, const Offset(50, 124), down: true, ripple: seg(0.14, 0.24));
    } else if (t < 0.5) {
      final f = lerp(const Offset(50, 124), const Offset(165, 82), ease(seg(0.24, 0.36)));
      _finger(c, f, down: t > 0.36, ripple: t > 0.36 ? seg(0.36, 0.46) : 0);
    }
  }

  void _trap(Canvas c) {
    // Two lanes: the direct one has a trap, the mouse takes the other.
    for (int x = 0; x < 10; x++) {
      _wallTile(c, x, 0);
      _wallTile(c, x, 4);
      if (x > 1 && x < 8) _wallTile(c, x, 2);
    }
    const trap = Offset(150, 45);
    _at(c, trap, 30, (s) => ProceduralPainter.drawMouseTrap(c, s, animTimer: t * 20));
    final pts = [const Offset(30, 45), const Offset(60, 45), const Offset(60, 105), const Offset(240, 105), const Offset(240, 45), const Offset(275, 45)];
    _dashed(c, pts, const Color(0xFF34E0C0).withValues(alpha: 0.7));
    _bang(c, const Offset(150, 22), 'x', _red);
    _mouse(c, _along(pts, ease(seg(0.1, 0.9))));
  }

  void _crate(Canvas c) {
    _hall(c, corridor: true);
    const cat = Offset(60, 75), crate = Offset(150, 75);
    final mouse = Offset(215 + 8 * math.sin(t * math.pi * 6), 75);
    _radarRing(c, cat, 110, _teal);
    _cat(c, cat);
    // Line of sight, stopped by the crate
    c.drawLine(
      cat + const Offset(18, 0),
      crate - const Offset(20, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 2,
    );
    _bang(c, crate - const Offset(20, 0), 'x', _red);
    _at(c, crate, 34, (s) => ProceduralPainter.drawCrate(c, s));
    _mouse(c, mouse);
    _icon(c, Icons.visibility_off_rounded, Offset(mouse.dx, 36), 24, Colors.white70);
  }

  /// Freeze, speed and ghost all use the same corridor with one cat.
  void _powerRun(Canvas c, DemoKind k) {
    _hall(c, corridor: true);
    const cat = Offset(195, 75);
    const orb = Offset(75, 75);
    final run = k == DemoKind.speed ? seg(0.08, 0.7) : seg(0.08, 0.88);
    // The speed run covers the same distance faster after the pickup.
    final dx = k == DemoKind.speed ? ease(run) : run;
    var p = Offset(30 + 240 * dx, 75);
    final picked = p.dx >= orb.dx;
    final since = picked ? ((p.dx - orb.dx) / 240) : 0.0;
    var catPos = cat;
    var radarColor = _teal;
    var frozen = false;
    var seen = false;
    var ghostA = 1.0;

    switch (k) {
      case DemoKind.freeze:
        frozen = picked && t < 0.9;
        radarColor = frozen ? _ice : _teal;
      case DemoKind.speed:
        // Cat notices the mouse and chases, but falls behind.
        seen = p.dx > 150 && p.dx < 235;
        radarColor = seen ? _red : _teal;
        if (p.dx > 150) catPos = Offset(math.max(150, 195 - (p.dx - 150) * 0.15 + (t > 0.5 ? 40 * seg(0.5, 0.8) : 0)), 75);
      case DemoKind.ghost:
        ghostA = picked ? 0.35 : 1.0;
      default:
        break;
    }
    _radarRing(c, catPos, 52, radarColor);
    _cat(c, catPos, chasing: seen, alert: seen, frozen: frozen);
    if (!picked) _orb(c, orb, k);
    if (picked && since < 0.07) {
      c.drawCircle(
        orb,
        12 + since * 500,
        Paint()
          ..color = Colors.white.withValues(alpha: 1 - since / 0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    if (k == DemoKind.speed && picked) {
      for (int i = 0; i < 3; i++) {
        c.drawLine(
          p - Offset(20 + i * 6, 7 - i * 7),
          p - Offset(34 + i * 10, 7 - i * 7),
          Paint()
            ..color = const Color(0xFFFFE066)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    _mouse(c, p, alpha: ghostA, happy: false);
    if (seen && k == DemoKind.speed) _bang(c, Offset(catPos.dx, 36), '!', _red);
    if (picked && t < 0.9) {
      final label = switch (k) {
        DemoKind.freeze => 'Cats frozen',
        DemoKind.speed => 'Speed x1.7',
        _ => 'Invisible',
      };
      final tp = TextPainter(
        text: TextSpan(text: label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      final pill = RRect.fromRectAndRadius(Rect.fromLTWH(w / 2 - tp.width / 2 - 10, 8, tp.width + 20, 22), const Radius.circular(11));
      c.drawRRect(pill, Paint()..color = const Color(0xCC5A46E0));
      tp.paint(c, Offset(w / 2 - tp.width / 2, 12));
    }
  }

  void _key(Canvas c) {
    _hall(c, corridor: true);
    const house = Offset(255, 75), keyPos = Offset(120, 75);
    _at(c, house, 44, (s) => ProceduralPainter.drawHouse(c, s, animTimer: t * 20));
    final p = lerp(const Offset(30, 75), house - const Offset(24, 0), ease(seg(0.08, 0.85)));
    final hasKey = p.dx >= keyPos.dx - 4;
    final unlock = seg(0.5, 0.58);
    if (!hasKey) {
      c.drawCircle(keyPos, 17, Paint()..color = const Color(0x55FFC23D));
      drawKeyIcon(c, keyPos + Offset(0, math.sin(t * 30) * 2), 1.3);
    }
    if (unlock < 1 && !(hasKey && t > 0.6)) {
      drawPadlock(c, house + Offset(0, 4 - 10 * unlock), 1.1 * (1 - unlock * 0.6));
    }
    _mouse(c, p, happy: t > 0.85);
    if (hasKey) {
      drawKeyIcon(c, Offset(p.dx, p.dy - 24), 1.0);
    }
  }

  void _gate(Canvas c) {
    _hall(c, corridor: true);
    // Wall button above the corridor
    const press = Offset(120, 75), button = Offset(120, 45);
    const gatePos = Offset(195, 75);
    final pressed = t > 0.42;
    final open = ease(seg(0.5, 0.65));
    _wallTile(c, 4, 1);
    final bc = pressed ? const Color(0xFF34E0C0) : gateColor;
    c.drawCircle(button, 13, Paint()..color = bc.withValues(alpha: 0.25));
    c.drawCircle(button, 9, Paint()..color = bc);
    c.drawCircle(
      button,
      11,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Gate bars slide up
    final bar = Paint()
      ..color = gateColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    c.save();
    c.clipRect(const Rect.fromLTWH(180, 58, 30, 34));
    for (int i = 0; i < 4; i++) {
      final x = 183.0 + i * 8;
      c.drawLine(Offset(x, 60 - 30 * open), Offset(x, 90 - 30 * open), bar);
    }
    c.restore();
    final mouse = t < 0.4
        ? lerp(const Offset(30, 75), press, ease(seg(0.05, 0.38)))
        : lerp(press, const Offset(270, 75), ease(seg(0.68, 0.98)));
    _mouse(c, mouse);
    if (t > 0.3 && t < 0.5) {
      _finger(c, button + const Offset(0, -2), down: t > 0.4, ripple: t > 0.4 ? seg(0.4, 0.5) : 0);
    }
    _bang(c, Offset(gatePos.dx, 28), open > 0.5 ? '✓' : '!', open > 0.5 ? const Color(0xFF22C55E) : gateColor);
  }

  @override
  bool shouldRepaint(covariant _DemoPainter old) => old.t != t || old.kind != kind;
}
