import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hand-drawn (code) night-time scenery used behind the app and on the game board:
/// a moonlit sky with twinkling stars and clouds, falling leaves, a vignette and
/// brick maze walls. Everything is vector, no images.
class NightArt {
  // --------------------------------------------------------------------------
  // SKY
  // --------------------------------------------------------------------------
  static final List<_Star> _stars = () {
    final r = math.Random(7);
    return List.generate(90, (_) => _Star(r.nextDouble(), r.nextDouble() * 0.7, 0.6 + r.nextDouble() * 1.6, r.nextDouble() * 6.28));
  }();

  /// Gradient sky, twinkling stars, a glowing moon and drifting clouds.
  static void sky(
    Canvas c,
    Size s,
    double t, {
    Color top = const Color(0xFF070B2A),
    Color mid = const Color(0xFF16275E),
    Color bottom = const Color(0xFF1F4A6B),
    bool moon = true,
    Offset moonAt = const Offset(0.8, 0.13),
  }) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, mid, bottom],
          stops: const [0, 0.55, 1],
        ).createShader(Offset.zero & s),
    );
    for (final st in _stars) {
      final tw = 0.5 + 0.5 * math.sin(t * 2.2 + st.phase);
      c.drawCircle(
        Offset(st.x * s.width, st.y * s.height),
        st.r * (0.7 + 0.5 * tw),
        Paint()..color = Colors.white.withValues(alpha: 0.35 + 0.55 * tw),
      );
    }
    if (moon) {
      final m = Offset(s.width * moonAt.dx, s.height * moonAt.dy);
      final mr = s.width * 0.085;
      c.drawCircle(
        m,
        mr * 3.2,
        Paint()
          ..shader = RadialGradient(colors: [const Color(0x55BFE6FF), const Color(0x00BFE6FF)])
              .createShader(Rect.fromCircle(center: m, radius: mr * 3.2)),
      );
      c.drawCircle(m, mr, Paint()..color = const Color(0xFFEFF8FF));
      final crater = Paint()..color = const Color(0xFFCFE3F2);
      c.drawCircle(m + Offset(-mr * 0.3, -mr * 0.2), mr * 0.2, crater);
      c.drawCircle(m + Offset(mr * 0.35, mr * 0.25), mr * 0.16, crater);
      c.drawCircle(m + Offset(-mr * 0.1, mr * 0.45), mr * 0.1, crater);
    }
    _cloud(c, (s.width * 0.1 + t * 7) % (s.width + 160) - 80, s.height * 0.2, s.width * 0.34, 0.16);
    _cloud(c, (s.width * 0.7 + t * 5) % (s.width + 160) - 80, s.height * 0.3, s.width * 0.28, 0.12);
  }

  static void _cloud(Canvas c, double x, double y, double w, double alpha) {
    final p = Paint()
      ..color = const Color(0xFFBFD4FF).withValues(alpha: alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: w, height: w * 0.22), p);
    c.drawOval(Rect.fromCenter(center: Offset(x - w * 0.2, y + w * 0.03), width: w * 0.55, height: w * 0.18), p);
    c.drawOval(Rect.fromCenter(center: Offset(x + w * 0.22, y + w * 0.04), width: w * 0.5, height: w * 0.17), p);
  }

  /// Dark vignette that pulls the eye to the middle.
  static void vignette(Canvas c, Size s, {double strength = 0.55}) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [Colors.transparent, Colors.black.withValues(alpha: strength)],
          stops: const [0.55, 1],
        ).createShader(Offset.zero & s),
    );
  }

  /// Falling leaves and drifting golden sparkles.
  static void particles(Canvas c, Size s, double t) {
    final r = math.Random(21);
    for (int i = 0; i < 14; i++) {
      final seed = r.nextDouble();
      final x = (r.nextDouble() * s.width + math.sin(t * 0.8 + i) * 26 + t * 12 * (0.4 + seed)) % (s.width + 40) - 20;
      final y = (r.nextDouble() * s.height + t * 22 * (0.5 + seed)) % s.height;
      c.save();
      c.translate(x, y);
      c.rotate(t * (1 + seed) + i);
      final leaf = Path()
        ..moveTo(0, -5)
        ..quadraticBezierTo(5, 0, 0, 6)
        ..quadraticBezierTo(-5, 0, 0, -5);
      c.drawPath(leaf, Paint()..color = (i.isEven ? const Color(0xFF8FD16A) : const Color(0xFFE59A3A)).withValues(alpha: 0.85));
      c.restore();
    }
    for (int i = 0; i < 16; i++) {
      final x = r.nextDouble() * s.width;
      final y = r.nextDouble() * s.height;
      final tw = 0.5 + 0.5 * math.sin(t * 3 + i * 1.7);
      final p = Offset(x + math.sin(t + i) * 6, y + math.cos(t * 0.8 + i) * 6);
      c.drawCircle(p, 2.4 * tw + 0.6, Paint()..color = const Color(0xFFFFE27A).withValues(alpha: 0.25 + 0.6 * tw));
    }
  }

  // --------------------------------------------------------------------------
  // STONE WALLS
  // --------------------------------------------------------------------------
  /// A brick wall segment seen from slightly above: lit top, mortar-lined face, moss.
  static void stoneWall(Canvas c, Rect r, {int seed = 1, double top = 9, bool cap = true, Color? tint, bool moss = true, bool shade = true}) {
    Color tone(Color base) => tint == null ? base : Color.lerp(base, tint, 0.38)!;
    final face = Rect.fromLTWH(r.left, r.top + top, r.width, r.height - top);
    c.drawRect(face, Paint()..color = tone(const Color(0xFF4B5568)));
    final rnd = math.Random(seed);
    final rows = math.max(2, (face.height / 14).round());
    final rh = face.height / rows;
    for (int row = 0; row < rows; row++) {
      final bw = 22.0 + rnd.nextDouble() * 6;
      var x = face.left - (row.isOdd ? bw / 2 : 0);
      while (x < face.right) {
        final b = Rect.fromLTWH(x + 1, face.top + row * rh + 1, bw - 2, rh - 2).intersect(face);
        if (!b.isEmpty) {
          final shade = 0.9 + rnd.nextDouble() * 0.2;
          c.drawRect(b, Paint()..color = Color.lerp(tone(const Color(0xFF5E6A80)), tone(const Color(0xFF3F4859)), 1 - (shade - 0.9) * 5)!);
          c.drawRect(Rect.fromLTWH(b.left, b.top, b.width, 2), Paint()..color = Colors.white.withValues(alpha: 0.08));
        }
        x += bw;
      }
    }
    // Moss
    for (int i = 0; moss && i < (r.width / 26).round() + 1; i++) {
      if (rnd.nextDouble() < 0.5) {
        c.drawOval(
          Rect.fromLTWH(r.left + rnd.nextDouble() * r.width, face.bottom - 5 - rnd.nextDouble() * 5, 9 + rnd.nextDouble() * 8, 5),
          Paint()..color = const Color(0xFF3F7A3A).withValues(alpha: 0.7),
        );
      }
    }
    // Lit top
    if (cap) {
      final topR = RRect.fromRectAndRadius(Rect.fromLTWH(r.left - 1, r.top, r.width + 2, top + 2), const Radius.circular(3));
      c.drawRRect(topR, Paint()..color = tone(const Color(0xFF8D9AB2)));
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, r.width, 3), const Radius.circular(2)),
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
    }
    if (shade) c.drawRect(Rect.fromLTWH(r.left, face.bottom, r.width, 4), Paint()..color = const Color(0x55000000));
  }
}

class _Star {
  final double x, y, r, phase;
  const _Star(this.x, this.y, this.r, this.phase);
}
