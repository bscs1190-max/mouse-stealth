import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A framed window onto the key-art poster with small, calm animations laid on
/// top: chimney smoke, window glow, drifting golden sparkles, falling leaves,
/// glints in the cat's eyes and a slow camera drift.
class PosterCard extends StatefulWidget {
  final double height;
  const PosterCard({super.key, this.height = 260});

  static const String asset = 'assets/images/loading_bg.jpg';
  static const double imgW = 926, imgH = 2000;

  @override
  State<PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends State<PosterCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(color: const Color(0xFF4F7CFF).withValues(alpha: 0.35), blurRadius: 24, spreadRadius: 1),
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 14, offset: const Offset(0, 8)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) {
                      final t = _c.value * 40;
                      // Slow breathing camera drift
                      final zoom = 1.045 + 0.02 * math.sin(t * 0.35);
                      return Transform.translate(
                        offset: Offset(math.sin(t * 0.22) * 5, math.cos(t * 0.18) * 3),
                        child: Transform.scale(
                          scale: zoom,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(PosterCard.asset, fit: BoxFit.cover, alignment: const Alignment(0, 0.03)),
                              CustomPaint(painter: _FxPainter(t, w, h)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Soft edge shading + a moving shine along the frame
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 1.05,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.38)],
                          stops: const [0.6, 1],
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => CustomPaint(painter: _FramePainter((_c.value * 8) % 1)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FxPainter extends CustomPainter {
  final double t;
  final double cw, ch;
  _FxPainter(this.t, this.cw, this.ch);

  // Map poster pixels -> card pixels (BoxFit.cover with Alignment(0, 0.03)).
  Offset _p(double x, double y) {
    final s = math.max(cw / PosterCard.imgW, ch / PosterCard.imgH);
    final ox = (cw - PosterCard.imgW * s) * 0.5;
    final oy = (ch - PosterCard.imgH * s) * (1 + 0.03) / 2;
    return Offset(ox + x * s, oy + y * s);
  }

  double get _s => math.max(cw / PosterCard.imgW, ch / PosterCard.imgH);

  @override
  void paint(Canvas c, Size size) {
    final s = _s;

    // Window glow flicker
    final glow = 0.55 + 0.25 * math.sin(t * 2.2) + 0.1 * math.sin(t * 5.1);
    for (final w in [const Offset(212, 712), const Offset(252, 700), const Offset(150, 715)]) {
      final p = _p(w.dx, w.dy);
      c.drawCircle(
        p,
        34 * s * 2.2,
        Paint()
          ..shader = RadialGradient(colors: [const Color(0xFFFFD36B).withValues(alpha: 0.35 * glow), const Color(0x00FFD36B)])
              .createShader(Rect.fromCircle(center: p, radius: 34 * s * 2.2)),
      );
    }

    // Chimney smoke
    for (int i = 0; i < 5; i++) {
      final k = (t * 0.18 + i / 5) % 1;
      final p = _p(150 + math.sin(k * 5 + i) * 18 + k * 50, 600 - k * 230);
      c.drawCircle(p, (6 + k * 18) * s * 1.6, Paint()..color = const Color(0xFFCBD5E1).withValues(alpha: 0.28 * (1 - k)));
    }

    // Golden sparkles drifting up around the cheese and the swipe
    final rnd = math.Random(3);
    for (int i = 0; i < 22; i++) {
      final bx = rnd.nextDouble() * PosterCard.imgW;
      final by = 700 + rnd.nextDouble() * 780;
      final speed = 0.04 + rnd.nextDouble() * 0.07;
      final k = (t * speed + rnd.nextDouble()) % 1;
      final p = _p(bx + math.sin(t + i) * 16, by - k * 160);
      final tw = 0.5 + 0.5 * math.sin(t * 3 + i * 1.9);
      _spark(c, p, (3 + 3 * tw) * s * 1.7, const Color(0xFFFFE9A0).withValues(alpha: (1 - k) * (0.4 + 0.5 * tw)));
    }
    // Extra bright twinkle on the glowing cheese
    final cheese = _p(180, 1310);
    _spark(c, cheese + Offset(math.cos(t * 2) * 26 * s * 1.6, math.sin(t * 2.6) * 20 * s * 1.6), 7 * s * 1.7, const Color(0xFFFFF6C8));

    // Falling leaves
    for (int i = 0; i < 6; i++) {
      final k = (t * 0.05 + i / 6) % 1;
      final x = 120 + i * 140 + math.sin(k * 9 + i) * 70;
      final p = _p(x, 640 + k * 900);
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(k * 12 + i);
      final leaf = Path()
        ..moveTo(0, -7 * s * 1.7)
        ..quadraticBezierTo(6 * s * 1.7, 0, 0, 8 * s * 1.7)
        ..quadraticBezierTo(-6 * s * 1.7, 0, 0, -7 * s * 1.7);
      c.drawPath(leaf, Paint()..color = (i.isEven ? const Color(0xFF8FD16A) : const Color(0xFFE59A3A)).withValues(alpha: 0.85 * math.sin(k * math.pi)));
      c.restore();
    }

    // Glint in the cat's eyes every few seconds
    final glint = math.max(0.0, math.sin(t * 0.9));
    if (glint > 0.85) {
      final a = (glint - 0.85) / 0.15;
      for (final e in [const Offset(570, 800), const Offset(735, 815)]) {
        _spark(c, _p(e.dx, e.dy), 10 * s * 1.7 * a, Colors.white.withValues(alpha: a));
      }
    }
  }

  void _spark(Canvas c, Offset p, double r, Color color) {
    final path = Path()
      ..moveTo(p.dx, p.dy - r)
      ..quadraticBezierTo(p.dx, p.dy, p.dx + r, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
      ..quadraticBezierTo(p.dx, p.dy, p.dx - r, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r);
    c.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _FxPainter old) => old.t != t;
}

/// Gold frame with a shine that slides around it.
class _FramePainter extends CustomPainter {
  final double k;
  _FramePainter(this.k);

  @override
  void paint(Canvas c, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(26));
    c.drawRRect(
      r.deflate(1.5),
      Paint()
        ..color = const Color(0xFF6B86D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final path = Path()..addRRect(r.deflate(1.5));
    for (final m in path.computeMetrics()) {
      final start = m.length * k;
      c.drawPath(
        m.extractPath(start, math.min(start + 90, m.length)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) => old.k != k;
}
