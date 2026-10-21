import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pure procedural vector rendering engine for all game visuals.
/// No external PNGs or asset files needed.
class ProceduralPainter {
  /// Render cute cartoon mouse matching reference style
  static void drawMouse(
    Canvas canvas,
    Size size, {
    double animTimer = 0.0,
    bool isHappy = false,
    String skinId = 'mouse_classic',
  }) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 48.0;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    // Subtle breathing / idle bounce
    final breath = math.sin(animTimer * 4) * 0.8;

    // 1. Shadow underneath
    final shadowPaint = Paint()..color = const Color(0x660A0E1A);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 18), width: 28, height: 10),
      shadowPaint,
    );

    // Dynamic Skin Palettes
    List<Color> bodyColors = [const Color(0xFFBAC5D9), const Color(0xFF7A879E)];
    Color earOuterColor = const Color(0xFF8E9AAF);
    Color earInnerColor = const Color(0xFFFFB3C6);
    Color bellyColor = const Color(0xCCEEF2F9);
    Color tailColor = const Color(0xFFF6A5B6);

    if (skinId == 'mouse_golden') {
      bodyColors = [const Color(0xFFFFE082), const Color(0xFFFFB300)];
      earOuterColor = const Color(0xFFFFA000);
      earInnerColor = const Color(0xFFFFF9C4);
      bellyColor = const Color(0xCCFFF8E1);
      tailColor = const Color(0xFFFFD54F);

      // Golden Halo / Aura
      final auraPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.35 + 0.15 * math.sin(animTimer * 6))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(0, breath), 22, auraPaint);
    } else if (skinId == 'mouse_ninja') {
      bodyColors = [const Color(0xFF374151), const Color(0xFF1F2937)];
      earOuterColor = const Color(0xFF111827);
      earInnerColor = const Color(0xFFEF4444);
      bellyColor = const Color(0xCC374151);
      tailColor = const Color(0xFF1F2937);
    } else if (skinId == 'mouse_cyber') {
      bodyColors = [const Color(0xFF00E5FF), const Color(0xFF0D47A1)];
      earOuterColor = const Color(0xFF1565C0);
      earInnerColor = const Color(0xFF84FFFF);
      bellyColor = const Color(0xCCB388FF);
      tailColor = const Color(0xFF00E5FF);

      // Cyber Shield Glow
      final cyberGlow = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(0, breath), 20, cyberGlow);
    }

    // 2. Curled Tail
    final tailPath = Path();
    tailPath.moveTo(-8, 12);
    tailPath.quadraticBezierTo(-20, 16 + breath, -18, 4);
    tailPath.quadraticBezierTo(-16, -6, -22, -8);
    final tailPaint = Paint()
      ..color = tailColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(tailPath, tailPaint);

    // 3. Ears
    final earOuterPaint = Paint()..color = earOuterColor;
    final earInnerPaint = Paint()..color = earInnerColor;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-13, -12), width: 14, height: 16),
      earOuterPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-13, -12), width: 9, height: 11),
      earInnerPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(13, -12), width: 14, height: 16),
      earOuterPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(13, -12), width: 9, height: 11),
      earInnerPaint,
    );

    // 4. Body & Head
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: bodyColors,
        center: const Alignment(0.0, -0.2),
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: Offset(0, breath), radius: 18));
    
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 4 + breath), width: 28, height: 26),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -3 + breath), width: 26, height: 24),
      bodyPaint,
    );

    // Belly patch
    final bellyPaint = Paint()..color = bellyColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 8 + breath), width: 16, height: 16),
      bellyPaint,
    );

    // 5. Eyes
    final eyeBlack = Paint()..color = skinId == 'mouse_ninja' ? const Color(0xFFEF4444) : const Color(0xFF1E2430);
    final eyeSparkle = Paint()..color = Colors.white;

    canvas.drawOval(Rect.fromCenter(center: Offset(-6, -4 + breath), width: 7, height: 9), eyeBlack);
    canvas.drawCircle(Offset(-7.5, -6 + breath), 1.8, eyeSparkle);
    canvas.drawCircle(Offset(-4.5, -2 + breath), 0.9, eyeSparkle);

    canvas.drawOval(Rect.fromCenter(center: Offset(6, -4 + breath), width: 7, height: 9), eyeBlack);
    canvas.drawCircle(Offset(4.5, -6 + breath), 1.8, eyeSparkle);
    canvas.drawCircle(Offset(7.5, -2 + breath), 0.9, eyeSparkle);

    // 6. Cheeks
    final cheekPaint = Paint()..color = const Color(0x88FF8FA3);
    canvas.drawCircle(Offset(-10, 1 + breath), 3.2, cheekPaint);
    canvas.drawCircle(Offset(10, 1 + breath), 3.2, cheekPaint);

    // 7. Pink Nose & Smile
    final nosePaint = Paint()..color = const Color(0xFFFF5D8F);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 0 + breath), width: 4.5, height: 3), nosePaint);

    final mouthPaint = Paint()
      ..color = const Color(0xFF4A5568)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final mouthPath = Path();
    mouthPath.moveTo(-3, 3 + breath);
    mouthPath.quadraticBezierTo(0, 5 + breath, 3, 3 + breath);
    canvas.drawPath(mouthPath, mouthPaint);

    // 8. Whiskers
    final whiskerPaint = Paint()
      ..color = const Color(0x994A5568)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(-7, 1 + breath), Offset(-18, -1 + breath), whiskerPaint);
    canvas.drawLine(Offset(-7, 3 + breath), Offset(-18, 5 + breath), whiskerPaint);
    canvas.drawLine(Offset(7, 1 + breath), Offset(18, -1 + breath), whiskerPaint);
    canvas.drawLine(Offset(7, 3 + breath), Offset(18, 5 + breath), whiskerPaint);

    // 9. Tiny Paws
    final pawPaint = Paint()..color = const Color(0xFFF6A5B6);
    canvas.drawCircle(Offset(-6, 12 + breath), 2.5, pawPaint);
    canvas.drawCircle(Offset(6, 12 + breath), 2.5, pawPaint);

    // 10. Accessory Overlays
    if (skinId == 'mouse_ninja') {
      // Red headband
      final headband = Paint()..color = const Color(0xFFDC2626)..strokeWidth = 3.5..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(-13, -7 + breath), Offset(13, -7 + breath), headband);
      // Headband tails
      final tails = Paint()..color = const Color(0xFFDC2626)..strokeWidth = 2.0;
      canvas.drawLine(Offset(12, -7 + breath), Offset(18, -2 + breath), tails);
      canvas.drawLine(Offset(12, -7 + breath), Offset(19, -9 + breath), tails);
    } else if (skinId == 'mouse_cyber') {
      // Neon Visor
      final visor = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-9, -7 + breath, 18, 5), const Radius.circular(2)),
        visor,
      );
    }

    canvas.restore();
  }

  /// Render cozy mouse house matching reference style
  static void drawHouse(
    Canvas canvas,
    Size size, {
    double animTimer = 0.0,
    String skinId = 'house_cottage',
  }) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 54.0;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    // Base Shadow
    final shadowPaint = Paint()..color = const Color(0x660A0E1A);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 22), width: 46, height: 12),
      shadowPaint,
    );

    if (skinId == 'house_scifi') {
      // Sci-Fi Bio-Dome
      final domeGlow = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35 + 0.1 * math.sin(animTimer * 4))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(const Offset(0, 4), 22, domeGlow);

      final domePaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF80D8FF), Color(0xFF0091EA)],
          center: Alignment(0.0, -0.4),
          radius: 0.9,
        ).createShader(Rect.fromCircle(center: const Offset(0, 4), radius: 20));
      canvas.drawCircle(const Offset(0, 4), 20, domePaint);

      // Metallic ring base
      final ringPaint = Paint()..color = const Color(0xFF37474F);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 18), width: 42, height: 8), const Radius.circular(4)),
        ringPaint,
      );
      // Portal Door
      final portalPaint = Paint()..color = const Color(0xFF00E5FF);
      canvas.drawOval(Rect.fromCenter(center: const Offset(0, 12), width: 12, height: 14), portalPaint);
      canvas.restore();
      return;
    } else if (skinId == 'house_cheese') {
      // Grand Cheese Palace
      final palaceRect = Rect.fromLTWH(-18, -4, 36, 24);
      final cheeseBody = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFDE047), Color(0xFFD97706)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(palaceRect);
      canvas.drawRRect(RRect.fromRectAndRadius(palaceRect, const Radius.circular(5)), cheeseBody);

      // Cheese holes
      final holePaint = Paint()..color = const Color(0xFFB45309);
      canvas.drawCircle(const Offset(-8, 2), 3.5, holePaint);
      canvas.drawCircle(const Offset(9, 6), 2.5, holePaint);
      canvas.drawCircle(const Offset(1, 14), 2.0, holePaint);

      // Royal Golden Crown Roof
      final crownPath = Path();
      crownPath.moveTo(-20, -4);
      crownPath.lineTo(-14, -20);
      crownPath.lineTo(-6, -10);
      crownPath.lineTo(0, -22);
      crownPath.lineTo(6, -10);
      crownPath.lineTo(14, -20);
      crownPath.lineTo(20, -4);
      crownPath.close();
      final crownPaint = Paint()..color = const Color(0xFFF59E0B);
      canvas.drawPath(crownPath, crownPaint);

      // Ruby jewels on crown
      final rubyPaint = Paint()..color = const Color(0xFFEF4444);
      canvas.drawCircle(const Offset(0, -22), 2.5, rubyPaint);
      canvas.drawCircle(const Offset(-14, -20), 2.0, rubyPaint);
      canvas.drawCircle(const Offset(14, -20), 2.0, rubyPaint);

      // Mouse Door
      final doorPaint = Paint()..color = const Color(0xFF78350F);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-6, 8, 12, 12), const Radius.circular(4)), doorPaint);
      canvas.restore();
      return;
    }

    // Default Cozy Red Cottage
    // Small bushes beside house
    final bushPaint = Paint()..color = const Color(0xFF388E3C);
    canvas.drawCircle(const Offset(-18, 16), 6, bushPaint);
    canvas.drawCircle(const Offset(18, 16), 6.5, bushPaint);

    // House Wall (Warm stucco plaster)
    final wallRect = Rect.fromLTWH(-16, -2, 32, 22);
    final wallPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF7ED), Color(0xFFFED7AA)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(wallRect);
    canvas.drawRRect(RRect.fromRectAndRadius(wallRect, const Radius.circular(3)), wallPaint);

    // Chimney (Red brick)
    final chimneyRect = Rect.fromLTWH(8, -20, 8, 14);
    final chimneyPaint = Paint()..color = const Color(0xFFB91C1C);
    canvas.drawRRect(RRect.fromRectAndRadius(chimneyRect, const Radius.circular(2)), chimneyPaint);

    // Smoke puff
    final smokeAlpha = (0.5 + 0.3 * math.sin(animTimer * 3)).clamp(0.2, 0.8);
    final smokePaint = Paint()..color = Colors.white.withValues(alpha: smokeAlpha);
    canvas.drawCircle(Offset(12, -23 + math.sin(animTimer * 2) * 1.5), 3.5, smokePaint);
    canvas.drawCircle(Offset(14, -28 + math.sin(animTimer * 2 + 1) * 2), 4.5, smokePaint);

    // Red Gable Roof
    final roofPath = Path();
    roofPath.moveTo(0, -22);
    roofPath.lineTo(-24, 0);
    roofPath.lineTo(24, 0);
    roofPath.close();
    final roofPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(-24, -22, 48, 22));
    canvas.drawPath(roofPath, roofPaint);

    // Roof edge trim
    final roofTrim = Paint()
      ..color = const Color(0xFF7F1D1D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(roofPath, roofTrim);

    // Round Attic Window
    final windowFrame = Paint()..color = const Color(0xFF78350F);
    final windowGlass = Paint()..color = const Color(0xFF67E8F9);
    canvas.drawCircle(const Offset(0, -9), 4.5, windowFrame);
    canvas.drawCircle(const Offset(0, -9), 3.0, windowGlass);

    // Arched Mouse Door (Cozy warm interior glow)
    final doorPath = Path();
    doorPath.moveTo(-6, 20);
    doorPath.lineTo(-6, 10);
    doorPath.arcToPoint(const Offset(6, 10), radius: const Radius.circular(6));
    doorPath.lineTo(6, 20);
    doorPath.close();

    final doorPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFEF08A), Color(0xFF78350F)],
        center: Alignment(0.0, 0.2),
        radius: 0.8,
      ).createShader(Rect.fromLTWH(-6, 6, 12, 14));
    canvas.drawPath(doorPath, doorPaint);

    // Door knob
    canvas.drawCircle(const Offset(3.5, 14), 1.0, Paint()..color = const Color(0xFFFDE047));

    canvas.restore();
  }

  /// Render Glowing Spawn / Goal Tile Pad (Vibrant green pad matching screenshot)
  static void drawGlowingPad(Canvas canvas, Size size, {bool isGoal = false, double animTimer = 0.0}) {
    final pulse = 0.85 + math.sin(animTimer * 4) * 0.15;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(8),
    );

    // Outer Neon Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF39FF14).withValues(alpha: 0.45 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(rrect, glowPaint);

    // Background Pad
    final padPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rrect.outerRect);
    canvas.drawRRect(rrect, padPaint);

    // Bright Green Neon Border
    final borderPaint = Paint()
      ..color = const Color(0xFF52B788)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, borderPaint);
  }

  /// Render Mouse Trap Obstacle (Wooden block, metallic spring snap, cheese bait)
  static void drawMouseTrap(Canvas canvas, Size size, {bool isSprung = false, double animTimer = 0.0}) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 36.0;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    // Wooden base plate
    final baseRect = Rect.fromCenter(center: const Offset(0, 2), width: 30, height: 20);
    final woodPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD97706), Color(0xFF92400E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(baseRect);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(3)), woodPaint);

    // Wood grain grooves
    final grainPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(-13, 0), const Offset(13, 0), grainPaint);
    canvas.drawLine(const Offset(-13, 5), const Offset(13, 5), grainPaint);

    // Metallic Snap Bar (Silver spring lever)
    final metalPaint = Paint()
      ..color = isSprung ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final springPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Coiled spring in center
    canvas.drawCircle(const Offset(0, 2), 3.0, springPaint);

    if (isSprung) {
      // Snapped shut diagonally!
      canvas.drawLine(const Offset(-10, 8), const Offset(10, -6), metalPaint);
      // Warning sparks
      final sparkPaint = Paint()..color = const Color(0xFFFBBF24);
      canvas.drawCircle(const Offset(0, -6), 2, sparkPaint);
    } else {
      // Armed rectangle wire frame waiting to snap
      final wireRect = Rect.fromCenter(center: const Offset(0, -1), width: 20, height: 12);
      canvas.drawRRect(RRect.fromRectAndRadius(wireRect, const Radius.circular(2)), metalPaint);
      
      // Tiny cheese wedge bait
      drawCheese(canvas, const Size(14, 14), Offset.zero);
    }

    canvas.restore();
  }

  /// Render Wooden Crate / Box obstacle
  static void drawCrate(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    final cratePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFB45309), Color(0xFF78350F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), cratePaint);

    // Frame border
    final borderPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);

    // 'X' crossbeams
    final crossPaint = Paint()
      ..color = const Color(0xFF92400E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(rect.topLeft, rect.bottomRight, crossPaint);
    canvas.drawLine(rect.topRight, rect.bottomLeft, crossPaint);
  }

  /// Render Wooden Bridge crossing plank
  static void drawBridge(Canvas canvas, Size size, {bool isVertical = false}) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    
    // Planks base
    final plankPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD97706), Color(0xFFB45309)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), plankPaint);

    // Guard rails
    final railPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    if (isVertical) {
      canvas.drawLine(rect.topLeft, rect.bottomLeft, railPaint);
      canvas.drawLine(rect.topRight, rect.bottomRight, railPaint);
      // Horizontal wood planks
      final step = rect.height / 5;
      final linePaint = Paint()..color = const Color(0xFF5A2A06)..strokeWidth = 1.5;
      for (int i = 1; i < 5; i++) {
        final y = rect.top + step * i;
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), linePaint);
      }
    } else {
      canvas.drawLine(rect.topLeft, rect.topRight, railPaint);
      canvas.drawLine(rect.bottomLeft, rect.bottomRight, railPaint);
      // Vertical wood planks
      final step = rect.width / 5;
      final linePaint = Paint()..color = const Color(0xFF5A2A06)..strokeWidth = 1.5;
      for (int i = 1; i < 5; i++) {
        final x = rect.left + step * i;
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), linePaint);
      }
    }
  }

  /// Render Bush / Shrub foliage obstacle
  static void drawBush(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.36;

    final darkGreen = Paint()..color = const Color(0xFF1E4620);
    final midGreen = Paint()..color = const Color(0xFF2E7D32);
    final lightGreen = Paint()..color = const Color(0xFF4CAF50);

    // Layered leaf clusters
    canvas.drawCircle(Offset(cx - 5, cy + 3), r * 0.85, darkGreen);
    canvas.drawCircle(Offset(cx + 5, cy + 3), r * 0.85, darkGreen);
    canvas.drawCircle(Offset(cx, cy - 3), r * 0.9, midGreen);
    canvas.drawCircle(Offset(cx - 3, cy - 2), r * 0.7, lightGreen);
    canvas.drawCircle(Offset(cx + 4, cy - 1), r * 0.65, lightGreen);
  }

  /// Render Shiny Golden Cheese Wedge
  static void drawCheese(Canvas canvas, Size size, [Offset center = Offset.zero]) {
    final cx = center == Offset.zero ? size.width / 2 : center.dx;
    final cy = center == Offset.zero ? size.height / 2 : center.dy;
    final scale = size.width / 28.0;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    // Cheese triangular body
    final path = Path();
    path.moveTo(-8, -8);
    path.lineTo(-10, 8);
    path.lineTo(11, 4);
    path.close();

    final cheesePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFDE047), Color(0xFFEAB308)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(-10, -8, 21, 16));
    canvas.drawPath(path, cheesePaint);

    // Swiss holes
    final holePaint = Paint()..color = const Color(0xFFCA8A04);
    canvas.drawCircle(const Offset(-3, 0), 2.2, holePaint);
    canvas.drawCircle(const Offset(4, 2), 1.8, holePaint);
    canvas.drawCircle(const Offset(-4, 5), 1.5, holePaint);

    canvas.restore();
  }

  /// Render cute stealth cat matching child-friendly art direction
  static void drawCat(
    Canvas canvas,
    Size size, {
    double animTimer = 0.0,
    bool isAlert = false,
    bool isChasing = false,
    String skinId = 'cat_tabby',
  }) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 44.0;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    final breath = math.sin(animTimer * 5) * 0.8;

    // Shadow
    final shadowPaint = Paint()..color = const Color(0x660A0E1A);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 16), width: 30, height: 10),
      shadowPaint,
    );

    // Dynamic Cat Palettes
    Color tailColor = const Color(0xFFE67E22);
    Color earOuterColor = const Color(0xFFD35400);
    Color earInnerColor = const Color(0xFFFFB3BA);
    List<Color> bodyColors = [const Color(0xFFF39C12), const Color(0xFFD35400)];
    Color stripeColor = const Color(0xFFB94A00);

    if (skinId == 'cat_shadow') {
      tailColor = const Color(0xFF1F2937);
      earOuterColor = const Color(0xFF111827);
      earInnerColor = const Color(0xFF374151);
      bodyColors = [const Color(0xFF374151), const Color(0xFF111827)];
      stripeColor = const Color(0xFF030712);
    } else if (skinId == 'cat_robo') {
      tailColor = const Color(0xFF00E5FF);
      earOuterColor = const Color(0xFF37474F);
      earInnerColor = const Color(0xFF00E5FF);
      bodyColors = [const Color(0xFF78909C), const Color(0xFF37474F)];
      stripeColor = const Color(0xFF00E5FF);
    }

    // Sleek Cat Tail (wags smoothly)
    final tailWag = math.sin(animTimer * 6) * 4;
    final tailPath = Path();
    tailPath.moveTo(-6, 12);
    tailPath.quadraticBezierTo(-18 + tailWag, 14, -16 + tailWag, -4);
    final tailPaint = Paint()
      ..color = tailColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(tailPath, tailPaint);

    // Pointy Cat Ears
    final earOuter = Paint()..color = earOuterColor;
    final earInner = Paint()..color = earInnerColor;

    // Left ear (triangular)
    final leftEar = Path()
      ..moveTo(-16, -2)
      ..lineTo(-11, -18)
      ..lineTo(-3, -8)
      ..close();
    canvas.drawPath(leftEar, earOuter);
    final leftEarInner = Path()
      ..moveTo(-14, -3)
      ..lineTo(-11, -14)
      ..lineTo(-5, -7)
      ..close();
    canvas.drawPath(leftEarInner, earInner);

    // Right ear (triangular)
    final rightEar = Path()
      ..moveTo(16, -2)
      ..lineTo(11, -18)
      ..lineTo(3, -8)
      ..close();
    canvas.drawPath(rightEar, earOuter);
    final rightEarInner = Path()
      ..moveTo(14, -3)
      ..lineTo(11, -14)
      ..lineTo(5, -7)
      ..close();
    canvas.drawPath(rightEarInner, earInner);

    // Cat Body / Head
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: bodyColors,
        center: const Alignment(0.0, -0.2),
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: Offset(0, breath), radius: 18));

    // Body
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 4 + breath), width: 28, height: 26), bodyPaint);
    // Head
    canvas.drawOval(Rect.fromCenter(center: Offset(0, -3 + breath), width: 26, height: 24), bodyPaint);

    // Tabby Forehead Stripes
    final stripePaint = Paint()
      ..color = stripeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, -12 + breath), Offset(0, -6 + breath), stripePaint);
    canvas.drawLine(Offset(-4, -11 + breath), Offset(-2, -6 + breath), stripePaint);
    canvas.drawLine(Offset(4, -11 + breath), Offset(2, -6 + breath), stripePaint);

    // Cat Eyes (Amber glowing or alert red/yellow)
    final eyePaint = Paint()
      ..color = isChasing
          ? const Color(0xFFFF3366)
          : (isAlert ? const Color(0xFFFFD700) : const Color(0xFF2ECC71));

    // Almond eye shape
    canvas.drawOval(Rect.fromCenter(center: Offset(-6, -4 + breath), width: 6, height: 7), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(6, -4 + breath), width: 6, height: 7), eyePaint);

    // Slit Pupils
    final pupilPaint = Paint()..color = const Color(0xFF1E2430);
    final pupilWidth = isAlert || isChasing ? 3.0 : 1.8;
    canvas.drawOval(Rect.fromCenter(center: Offset(-6, -4 + breath), width: pupilWidth, height: 6), pupilPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(6, -4 + breath), width: pupilWidth, height: 6), pupilPaint);

    // Glint
    canvas.drawCircle(Offset(-7.5, -6 + breath), 1.2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(4.5, -6 + breath), 1.2, Paint()..color = Colors.white);

    // Cute Pink Nose & Muzzle
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 0 + breath), width: 4, height: 3), Paint()..color = const Color(0xFFFF80AB));
    // White muzzle
    final muzzlePaint = Paint()..color = const Color(0xCCFFFFFF);
    canvas.drawOval(Rect.fromCenter(center: Offset(-3, 3 + breath), width: 5, height: 4), muzzlePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(3, 3 + breath), width: 5, height: 4), muzzlePaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(-6, 2 + breath), Offset(-18, 0 + breath), whiskerPaint);
    canvas.drawLine(Offset(-6, 4 + breath), Offset(-18, 5 + breath), whiskerPaint);
    canvas.drawLine(Offset(6, 2 + breath), Offset(18, 0 + breath), whiskerPaint);
    canvas.drawLine(Offset(6, 4 + breath), Offset(18, 5 + breath), whiskerPaint);

    canvas.restore();
  }

  /// Draw Vision Cone (Translucent wedge)
  static void drawVisionCone(
    Canvas canvas, {
    required double range,
    required double fovDegrees,
    required Color color,
  }) {
    final halfAngle = (fovDegrees * math.pi / 180.0) / 2.0;
    final path = Path();
    path.moveTo(0, 0);

    const segments = 16;
    for (int i = 0; i <= segments; i++) {
      final angle = -halfAngle + (2 * halfAngle * i / segments);
      final x = range * math.cos(angle);
      final y = range * math.sin(angle);
      path.lineTo(x, y);
    }
    path.close();

    // Soft gradient from source to edge
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0.08)],
        stops: const [0.3, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: range))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Border line
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  /// Draw 360-degree Circular Awareness Radar (Tuned Minor Range)
  static void draw360AwarenessZone(
    Canvas canvas, {
    required double range,
    required Color color,
    double animTimer = 0.0,
  }) {
    final pulse = 0.9 + 0.1 * math.sin(animTimer * 5);
    final effectiveRange = range * pulse;

    // Translucent filled circle with soft radial glow
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.04)],
        stops: const [0.4, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: effectiveRange))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, effectiveRange, fillPaint);

    // Outer radar ring
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset.zero, effectiveRange, borderPaint);
  }

  /// Draw Alert Icon (! or ?) floating above head
  static void drawAlertIcon(Canvas canvas, Offset position, {required String symbol, required Color color}) {
    final bgPaint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(position, 10, bgPaint);
    canvas.drawCircle(position, 8, Paint()..color = const Color(0xFF1E2438));

    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }
}
