import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/rendering/procedural_painter.dart';
import '../../game/services/cosmetics_service.dart';
import 'outlined_text.dart';

/// Ribbon with swallow-tail ends and a thick border (like a hanging title banner).
class RibbonBanner extends StatelessWidget {
  final Widget child;
  final Color fillTop;
  final Color fillBottom;
  final Color border;
  final double height;
  final double tail;

  const RibbonBanner({
    super.key,
    required this.child,
    required this.fillTop,
    required this.fillBottom,
    required this.border,
    this.height = 64,
    this.tail = 22,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RibbonPainter(fillTop, fillBottom, border, tail),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tail + 6),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  final Color top, bottom, border;
  final double tail;
  _RibbonPainter(this.top, this.bottom, this.border, this.tail);

  @override
  void paint(Canvas canvas, Size s) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width - tail, s.height / 2)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..lineTo(tail, s.height / 2)
      ..close();
    canvas.drawShadow(path, Colors.black, 6, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(Offset.zero & s),
    );
    // Glossy top highlight
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s.width, s.height * 0.42),
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter old) => old.top != top || old.bottom != bottom || old.border != border;
}

/// Gold-rimmed blue shield with "VS".
class VsShield extends StatelessWidget {
  final double size;
  const VsShield({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.1,
      child: CustomPaint(
        painter: _ShieldPainter(),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: size * 0.04),
            child: OutlinedText('VS', size: size * 0.42, color: Colors.white, outline: const Color(0xFF16307A)),
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    Path hex(double inset) {
      final w = s.width - inset * 2, h = s.height - inset * 2;
      final o = Offset(inset, inset);
      return Path()
        ..moveTo(o.dx + w * 0.5, o.dy)
        ..lineTo(o.dx + w, o.dy + h * 0.22)
        ..lineTo(o.dx + w, o.dy + h * 0.72)
        ..lineTo(o.dx + w * 0.5, o.dy + h)
        ..lineTo(o.dx, o.dy + h * 0.72)
        ..lineTo(o.dx, o.dy + h * 0.22)
        ..close();
    }

    final outer = hex(2);
    canvas.drawPath(
      outer,
      Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawShadow(outer, Colors.black, 8, false);
    canvas.drawPath(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE27A), Color(0xFFE59A00)],
        ).createShader(Offset.zero & s),
    );
    final inner = hex(s.width * 0.08);
    canvas.drawPath(
      inner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F8DFF), Color(0xFF1E48C8)],
        ).createShader(Offset.zero & s),
    );
    canvas.drawPath(
      inner,
      Paint()
        ..color = const Color(0xFF16307A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

enum ArtKind { mouse, cat, house }

/// One of the game's characters drawn large, gently bobbing.
class CharacterArt extends StatefulWidget {
  final ArtKind kind;
  final double size;
  final bool alert;
  final bool flip;

  const CharacterArt({super.key, required this.kind, this.size = 120, this.alert = false, this.flip = false});

  @override
  State<CharacterArt> createState() => _CharacterArtState();
}

class _CharacterArtState extends State<CharacterArt> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final bob = math.sin(_c.value * math.pi * 2) * widget.size * 0.03;
        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.flip(
            flipX: widget.flip,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(painter: _CharPainter(widget.kind, _c.value * 12, widget.alert)),
            ),
          ),
        );
      },
    );
  }
}

class _CharPainter extends CustomPainter {
  final ArtKind kind;
  final double t;
  final bool alert;
  _CharPainter(this.kind, this.t, this.alert);

  @override
  void paint(Canvas canvas, Size size) {
    final skins = CosmeticsService();
    switch (kind) {
      case ArtKind.mouse:
        ProceduralPainter.drawMouse(canvas, size, animTimer: t, isHappy: true, skinId: skins.equippedMouseId);
      case ArtKind.cat:
        ProceduralPainter.drawCat(canvas, size, animTimer: t, isAlert: alert, skinId: skins.equippedCatId);
      case ArtKind.house:
        ProceduralPainter.drawHouse(canvas, size, animTimer: t, skinId: skins.equippedHouseId);
    }
  }

  @override
  bool shouldRepaint(covariant _CharPainter old) => old.t != t || old.kind != kind || old.alert != alert;
}

/// Wooden treasure chest whose lid swings open as [open] goes 0 -> 1.
class ChestPainter extends CustomPainter {
  final double open;
  final double t;
  ChestPainter(this.open, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    final bodyTop = h * 0.5;
    final bodyH = h * 0.38;
    final bodyW = w * 0.74;
    final left = cx - bodyW / 2;

    // Light burst behind the chest
    if (open > 0.05) {
      final glow = Offset(cx, bodyTop);
      canvas.drawCircle(
        glow,
        w * (0.35 + 0.35 * open),
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF3B0).withValues(alpha: 0.9 * open),
              const Color(0x00FFE066),
            ],
          ).createShader(Rect.fromCircle(center: glow, radius: w * 0.7)),
      );
      final rays = Paint()..color = const Color(0xFFFFF3B0).withValues(alpha: 0.28 * open);
      for (int i = 0; i < 9; i++) {
        final a = -math.pi + (i + 0.5) * math.pi / 9 + math.sin(t * 2) * 0.03;
        final p = Path()
          ..moveTo(glow.dx, glow.dy)
          ..lineTo(glow.dx + math.cos(a - 0.07) * w * 0.9, glow.dy + math.sin(a - 0.07) * w * 0.9)
          ..lineTo(glow.dx + math.cos(a + 0.07) * w * 0.9, glow.dy + math.sin(a + 0.07) * w * 0.9)
          ..close();
        canvas.drawPath(p, rays);
      }
    }

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, bodyTop + bodyH + 6), width: bodyW * 1.05, height: 18),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Body
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(left, bodyTop, bodyW, bodyH), const Radius.circular(10));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB8793A), Color(0xFF7A4520)],
        ).createShader(body.outerRect),
    );
    // Plank lines
    final plank = Paint()
      ..color = const Color(0xFF5A3216)
      ..strokeWidth = 2;
    for (int i = 1; i < 3; i++) {
      final y = bodyTop + bodyH * i / 3;
      canvas.drawLine(Offset(left + 4, y), Offset(left + bodyW - 4, y), plank);
    }
    // Interior glow
    if (open > 0.1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left + 6, bodyTop - 3, bodyW - 12, 12), const Radius.circular(6)),
        Paint()..color = const Color(0xFFFFF3B0).withValues(alpha: open),
      );
    }
    // Metal bands + lock
    final metal = Paint()..color = const Color(0xFFB9C2D6);
    canvas.drawRect(Rect.fromLTWH(left + bodyW * 0.14, bodyTop, bodyW * 0.1, bodyH), metal);
    canvas.drawRect(Rect.fromLTWH(left + bodyW * 0.76, bodyTop, bodyW * 0.1, bodyH), metal);
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF3C220F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final lock = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, bodyTop + 6), width: 26, height: 24),
      const Radius.circular(5),
    );
    canvas.drawRRect(lock, Paint()..color = const Color(0xFFFFC23D));
    canvas.drawRRect(
      lock,
      Paint()
        ..color = const Color(0xFF8A5200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(Offset(cx, bodyTop + 6), 3.2, Paint()..color = const Color(0xFF5A3200));

    // Lid: hinged at the back-top edge, swings up and back
    canvas.save();
    canvas.translate(left + 2, bodyTop); // hinge on the left edge
    canvas.rotate(-open * 0.95);
    final lidH = h * 0.2;
    final lid = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, -lidH, bodyW, lidH),
      topLeft: const Radius.circular(40),
      topRight: const Radius.circular(40),
      bottomLeft: const Radius.circular(6),
      bottomRight: const Radius.circular(6),
    );
    canvas.drawRRect(
      lid,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD08A47), Color(0xFF9A5A2A)],
        ).createShader(lid.outerRect),
    );
    canvas.drawRect(Rect.fromLTWH(bodyW * 0.14, -lidH, bodyW * 0.1, lidH), metal);
    canvas.drawRect(Rect.fromLTWH(bodyW * 0.76, -lidH, bodyW * 0.1, lidH), metal);
    canvas.drawRRect(
      lid,
      Paint()
        ..color = const Color(0xFF3C220F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ChestPainter old) => old.open != open || old.t != t;
}
