import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'widgets/arcade_art.dart';
import 'widgets/game_ui.dart';
import 'widgets/outlined_text.dart';

/// Full-screen "Mouse vs Cats" showdown shown before each level: the cats'
/// red banner slides in from the left, yours from the right, the VS shield
/// slams in between. Tap to skip; it also continues by itself.
class VersusIntro extends StatefulWidget {
  final int level;
  final String difficultyTag;
  final String worldName;
  final int catCount;
  final int cheeseCount;
  final VoidCallback onDone;

  const VersusIntro({
    super.key,
    required this.level,
    required this.difficultyTag,
    required this.worldName,
    required this.catCount,
    required this.cheeseCount,
    required this.onDone,
  });

  @override
  State<VersusIntro> createState() => _VersusIntroState();
}

class _VersusIntroState extends State<VersusIntro> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _auto;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
    _auto = Timer(const Duration(milliseconds: 2800), _finish);
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _auto?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _finish,
          child: Material(
            color: Colors.black,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                double span(double a, double b, Curve curve) =>
                    curve.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));
                final slideTop = 1 - span(0.0, 0.5, Curves.easeOutCubic);
                final slideBottom = 1 - span(0.1, 0.6, Curves.easeOutCubic);
                final width = MediaQuery.sizeOf(context).width;
                final catCount = widget.catCount.clamp(1, 3);
                // Keep every line clear of the central shield (about 70px each way) on any screen height.
                final art = ((MediaQuery.sizeOf(context).height / 2) - 76 - 58 - 28 - 52).clamp(64.0, 128.0);

                return Column(
                  children: [
                    // ---------------- CATS (red) ----------------
                    Expanded(
                      child: GameBackground(
                        top: const Color(0xFFFF6B8B),
                        bottom: const Color(0xFF9B2350),
                        child: SafeArea(
                          bottom: false,
                          child: Transform.translate(
                            offset: Offset(-width * slideTop, 0),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 12, 0, 80),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      for (int i = 0; i < catCount; i++)
                                        Transform.translate(
                                          offset: Offset(i == 1 ? 0 : (i == 0 ? 14 : -14), i == 1 ? -10 : 0),
                                          child: CharacterArt(
                                            kind: ArtKind.cat,
                                            size: i == 1 ? art * 1.18 : art * 0.92,
                                            alert: true,
                                            flip: i == 2,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: RibbonBanner(
                                      fillTop: const Color(0xFFFF8FA8),
                                      fillBottom: const Color(0xFFD03A68),
                                      border: const Color(0xFF5A1230),
                                      height: 58,
                                      child: OutlinedText('CAT PATROL', size: 30, outline: const Color(0xFF5A1230)),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _InfoLine(
                                    icon: Icons.pets_rounded,
                                    text: '${widget.catCount} cat${widget.catCount == 1 ? '' : 's'} on watch',
                                    color: const Color(0xFFFFE0E8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // ---------------- MOUSE (blue) ----------------
                    Expanded(
                      child: GameBackground(
                        top: const Color(0xFF2F78FF),
                        bottom: const Color(0xFF14297E),
                        child: SafeArea(
                          top: false,
                          child: Transform.translate(
                            offset: Offset(width * slideBottom, 0),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 80, 0, 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: RibbonBanner(
                                      fillTop: const Color(0xFF6FB1FF),
                                      fillBottom: const Color(0xFF2B63E0),
                                      border: const Color(0xFF0E1D5C),
                                      height: 58,
                                      child: OutlinedText('YOU', size: 30, outline: const Color(0xFF0E1D5C)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CharacterArt(kind: ArtKind.mouse, size: art * 1.05),
                                  _InfoLine(
                                    icon: Icons.lunch_dining_rounded,
                                    text: 'Collect ${widget.cheeseCount} cheese',
                                    color: const Color(0xFFD7E6FF),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (int i = 0; i < 3; i++)
                                        Padding(
                                          padding: EdgeInsets.only(top: i == 1 ? 0 : 8, left: 4, right: 4),
                                          child: Icon(
                                            Icons.star_rounded,
                                            size: i == 1 ? 44 : 36,
                                            color: const Color(0xFFFFD54F),
                                            shadows: const [Shadow(color: Color(0xFF8A5200), offset: Offset(0, 3))],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        _VersusOverlay(anim: _c, level: widget.level, difficultyTag: widget.difficultyTag),
      ],
    );
  }
}

class _VersusOverlay extends StatelessWidget {
  final Animation<double> anim;
  final int level;
  final String difficultyTag;
  const _VersusOverlay({required this.anim, required this.level, required this.difficultyTag});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, _) {
          final shield = Curves.elasticOut.transform(((anim.value - 0.45) / 0.35).clamp(0.0, 1.0));
          final tag = Curves.easeOut.transform(((anim.value - 0.7) / 0.3).clamp(0.0, 1.0));
          return SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Transform.scale(scale: shield, child: const VsShield(size: 124)),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Opacity(
                    opacity: tag,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedText('LEVEL $level', size: 24),
                          const SizedBox(width: 10),
                          DifficultyBadge(tag: difficultyTag),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Opacity(
                    opacity: tag * (0.55 + 0.45 * math.sin(anim.value * 40).abs()),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'TAP TO CONTINUE',
                        style: AppText.title(13, color: Colors.white70).copyWith(letterSpacing: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoLine({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(text, style: AppText.title(16, color: color)),
      ],
    );
  }
}
