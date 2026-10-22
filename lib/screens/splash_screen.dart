import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/rendering/procedural_painter.dart';
import '../game/services/cosmetics_service.dart';
import '../ui/widgets/outlined_text.dart';
import 'home_screen.dart';

/// Loading screen: the key-art poster exactly as designed, nothing on it moves
/// except the loader at the bottom (the bar fills while a tiny mouse runs home).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Poster size in pixels; the loader is positioned in poster coordinates.
  static const double posterW = 926, posterH = 2000;
  static const String posterAsset = 'assets/images/loading_bg.jpg';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _load;
  late final AnimationController _run;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _run = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..repeat();
    _load = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      // Show the poster fully decoded, then start the loader.
      // Wait for the poster to decode, but never hold the loader longer than a moment.
      Future.any<void>([
        precacheImage(const AssetImage(SplashScreen.posterAsset), context),
        Future<void>.delayed(const Duration(milliseconds: 800)),
      ]).whenComplete(() {
        if (mounted && !_load.isAnimating && _load.value == 0) _load.forward().whenComplete(_goHome);
      });
    }
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _load.dispose();
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B1E),
      body: LayoutBuilder(
        builder: (context, box) {
          // Fit the whole poster on screen (contain); any side margin is filled
          // with a blurred, darkened copy so there are never bare bars.
          final s = math.min(box.maxWidth / SplashScreen.posterW, box.maxHeight / SplashScreen.posterH);
          final pw = SplashScreen.posterW * s, ph = SplashScreen.posterH * s;
          final left = (box.maxWidth - pw) / 2, top = (box.maxHeight - ph) / 2;
          return Stack(
            fit: StackFit.expand,
            children: [
              ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Image.asset(SplashScreen.posterAsset, fit: BoxFit.cover),
              ),
              Container(color: Colors.black.withValues(alpha: 0.45)),
              Positioned(
                left: left,
                top: top,
                width: pw,
                height: ph,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(SplashScreen.posterAsset, fit: BoxFit.fill, gaplessPlayback: true),
                    // Elegant vignette top & bottom
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: ph * 0.28,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xCC070B1E), Color(0x66070B1E), Colors.transparent],
                            stops: [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Title Logo
                    Positioned(
                      top: ph * 0.055,
                      left: pw * 0.05,
                      right: pw * 0.05,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedText(
                            'MOUSE',
                            size: math.max(34.0, pw * 0.12),
                            color: const Color(0xFFFFD54F),
                            outline: const Color(0xFF1B2250),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -6),
                            child: OutlinedText(
                              'STEALTH',
                              size: math.max(28.0, pw * 0.10),
                              color: Colors.white,
                              outline: const Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A223E).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF4A5D99), width: 1.5),
                            ),
                            child: Text(
                              'SNEAK  •  COLLECT  •  ESCAPE',
                              style: TextStyle(
                                color: const Color(0xFFFFD54F),
                                fontSize: math.max(10.0, pw * 0.033),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom gradient for loader readability
                    Positioned(
                      left: 0,
                      right: 0,
                      top: ph * 0.78,
                      bottom: 0,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xDD070B1E), Color(0xFF070B1E)],
                            stops: [0, 0.35, 1],
                          ),
                        ),
                      ),
                    ),
                    // Live loader
                    Positioned(
                      left: pw * 0.04,
                      right: pw * 0.04,
                      top: ph * 0.85,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_load, _run]),
                        builder: (context, _) {
                          final progress = Curves.easeInOutCubic.transform(_load.value);
                          return Column(
                            children: [
                              _StoneBar(progress: progress, phase: _run.value, scale: math.max(0.8, pw / 360)),
                              SizedBox(height: ph * 0.01),
                              OutlinedText('LOADING ${(progress * 100).round()}%', size: math.max(16.0, pw * 0.055)),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Stone-and-wood progress bar like the poster's: orange fill, rivets, a little
/// house at the end and a mouse running along the top toward it.
class _StoneBar extends StatelessWidget {
  final double progress;
  final double phase;
  final double scale;
  const _StoneBar({required this.progress, required this.phase, required this.scale});

  @override
  Widget build(BuildContext context) {
    final barH = 30.0 * scale, icon = 44.0 * scale;
    return LayoutBuilder(
      builder: (context, box) {
        final trackW = box.maxWidth - icon * 0.6;
        final x = (trackW - icon * 0.6) * progress;
        final cycle = phase * math.pi * 2;
        final bob = math.sin(cycle).abs() * 3 * scale;
        return SizedBox(
          height: icon + barH * 0.2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                width: trackW,
                bottom: 0,
                height: barH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFA9B2C4), Color(0xFF5E687C)],
                    ),
                    borderRadius: BorderRadius.circular(barH * 0.3),
                    border: Border.all(color: const Color(0xFF2A3042), width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(barH * 0.16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B2412),
                        borderRadius: BorderRadius.circular(barH * 0.2),
                        border: Border.all(color: const Color(0xFF1E1208), width: 2),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress.clamp(0.04, 1.0),
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(barH * 0.18),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFFD36B), Color(0xFFFF9A1F), Color(0xFFE2780A)],
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: FractionallySizedBox(
                                heightFactor: 0.38,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(barH * 0.18),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Wooden strap on each end
              for (final dx in [barH * 0.5, trackW - barH * 0.9])
                Positioned(
                  left: dx,
                  bottom: -2,
                  child: Container(
                    width: barH * 0.4,
                    height: barH + 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8A5A2B),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: const Color(0xFF4A2E12), width: 1.5),
                    ),
                  ),
                ),
              Positioned(
                right: -icon * 0.1,
                bottom: -2,
                child: SizedBox(width: icon, height: icon, child: CustomPaint(painter: _HousePainter())),
              ),
              Positioned(
                left: x,
                bottom: barH * 0.82 + bob,
                child: Transform.rotate(
                  angle: math.sin(cycle) * 0.08,
                  child: SizedBox(width: icon * 0.9, height: icon * 0.9, child: CustomPaint(painter: _RunnerPainter(phase * 8))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RunnerPainter extends CustomPainter {
  final double t;
  _RunnerPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) =>
      ProceduralPainter.drawMouse(canvas, size, animTimer: t, isHappy: true, skinId: CosmeticsService().equippedMouseId);
  @override
  bool shouldRepaint(covariant _RunnerPainter old) => old.t != t;
}

class _HousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) =>
      ProceduralPainter.drawHouse(canvas, size, skinId: CosmeticsService().equippedHouseId);
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
