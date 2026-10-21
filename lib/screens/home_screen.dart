import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/rendering/procedural_painter.dart';
import '../game/services/cosmetics_service.dart';
import '../game/services/progress_service.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/game_ui.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final progress = ProgressService();
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final level = progress.highestUnlockedLevel.clamp(1, 100);
    final totalStars = progress.levelStars.values.fold<int>(0, (a, b) => a + b);
    // Shrink the hero on short phones so everything fits without scrolling.
    final compact = MediaQuery.sizeOf(context).height < 720;
    final hero = compact ? 130.0 : 190.0;

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    children: [
                      // Top bar: stars + cheese
                      Row(
                        children: [
                          _StatBadge(icon: Icons.star_rounded, color: AppColors.cheese, value: '$totalStars / 300'),
                          const Spacer(),
                          CheeseCounter(amount: progress.totalCheeseCurrency),
                        ],
                      ),
                      SizedBox(height: compact ? 14 : 28),

                      // Hero mouse with radar ring
                      AnimatedBuilder(
                        animation: _bob,
                        builder: (context, _) {
                          final t = _bob.value * 2 * math.pi;
                          return Transform.translate(
                            offset: Offset(0, math.sin(t) * 6),
                            child: SizedBox(
                              width: hero,
                              height: hero,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  for (final k in [0.0, 0.5])
                                    Opacity(
                                      opacity: (1 - ((_bob.value + k) % 1)).clamp(0.0, 1.0) * 0.5,
                                      child: Container(
                                        width: hero * 0.63 + hero * 0.37 * ((_bob.value + k) % 1),
                                        height: hero * 0.63 + hero * 0.37 * ((_bob.value + k) % 1),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.mint, width: 2),
                                        ),
                                      ),
                                    ),
                                  Container(
                                    width: hero * 0.67,
                                    height: hero * 0.67,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const RadialGradient(
                                        colors: [AppColors.surfaceHigh, AppColors.surface],
                                      ),
                                      border: Border.all(color: AppColors.mint.withValues(alpha: 0.6), width: 3),
                                      boxShadow: [
                                        BoxShadow(color: AppColors.mint.withValues(alpha: 0.35), blurRadius: 40),
                                      ],
                                    ),
                                    child: CustomPaint(painter: _HomeMousePainter(CosmeticsService().equippedMouseId)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // Title
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [AppColors.cheese, Color(0xFFFFE8A3), AppColors.cheese],
                        ).createShader(r),
                        child: Text(
                          'MOUSE\nSTEALTH',
                          textAlign: TextAlign.center,
                          style: AppText.display(compact ? 40 : 52, color: Colors.white).copyWith(
                            letterSpacing: 3,
                            shadows: [
                              Shadow(color: AppColors.cheeseDeep.withValues(alpha: 0.7), blurRadius: 24),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sneak past the cats. Grab the cheese. Get home.',
                        textAlign: TextAlign.center,
                        style: AppText.body(15),
                      ),
                      SizedBox(height: compact ? 20 : 36),

                      ChunkyButton(
                        label: 'PLAY  LEVEL $level',
                        icon: Icons.play_arrow_rounded,
                        color: AppColors.cheeseDeep,
                        shadeColor: const Color(0xFFA35400),
                        height: 64,
                        fontSize: 22,
                        onPressed: () => _open(GameScreen(levelNumber: level)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ChunkyButton(
                              label: 'LEVELS',
                              icon: Icons.map_rounded,
                              color: AppColors.violetDeep,
                              shadeColor: const Color(0xFF3A2AA8),
                              fontSize: 17,
                              onPressed: () => _open(const LevelSelectScreen()),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ChunkyButton(
                              label: 'SHOP',
                              icon: Icons.storefront_rounded,
                              color: AppColors.mintDeep,
                              shadeColor: const Color(0xFF07695B),
                              fontSize: 17,
                              onPressed: () => _open(const ShopScreen()),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 14 : 28),

                      // How to play
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _Tip(icon: Icons.touch_app_rounded, color: AppColors.mint, title: 'Tap', sub: 'to move'),
                            _Tip(icon: Icons.radar_rounded, color: AppColors.coral, title: 'Radar', sub: 'stay outside'),
                            _Tip(icon: Icons.grid_view_rounded, color: AppColors.violet, title: 'Walls', sub: 'break sight'),
                            _Tip(icon: Icons.home_rounded, color: AppColors.cheese, title: 'House', sub: 'to win'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  const _StatBadge({required this.icon, required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.outline, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(value, style: AppText.number(15)),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  const _Tip({required this.icon, required this.color, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.16),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(title, style: AppText.title(13)),
        Text(sub, style: AppText.body(11, color: AppColors.textFaint)),
      ],
    );
  }
}

class _HomeMousePainter extends CustomPainter {
  final String skinId;
  _HomeMousePainter(this.skinId);

  @override
  void paint(Canvas canvas, Size size) {
    ProceduralPainter.drawMouse(canvas, size, animTimer: 0.0, isHappy: true, skinId: skinId);
  }

  @override
  bool shouldRepaint(covariant _HomeMousePainter oldDelegate) => oldDelegate.skinId != skinId;
}
