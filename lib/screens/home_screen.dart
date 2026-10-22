import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/services/progress_service.dart';
import '../ui/theme/app_theme.dart';
import '../ui/age_gate_dialog.dart';
import '../ui/art/poster_card.dart';
import '../ui/widgets/game_ui.dart';
import '../ui/widgets/outlined_text.dart';
import '../ui/tutorial_overlay.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    // Ask the age for very first time downloader
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ProgressService().hasSetAge && mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AgeGateDialog(
            onAgeConfirmed: () {
              Navigator.of(ctx).pop();
              setState(() {});
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  final progress = ProgressService();

  void _openGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => TutorialOverlay(onDone: () => Navigator.of(ctx).pop(), finishLabel: 'GOT IT'),
      ),
    );
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

    return Scaffold(
      body: GameBackground(
        moon: false,
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
                      SizedBox(height: compact ? 6 : 14),

                      // Logo (gently bobbing)
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, math.sin(_pulse.value * math.pi * 2) * 3),
                          child: child,
                        ),
                        child: Column(
                          children: [
                            OutlinedText(
                              'MOUSE',
                              size: compact ? 44 : 58,
                              color: const Color(0xFFFFD54F),
                              outline: const Color(0xFF1B2250),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -8),
                              child: OutlinedText('STEALTH', size: compact ? 38 : 50, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 14),

                      // The key art in a window, with small ambient animations
                      PosterCard(height: compact ? 190 : 300),
                      const SizedBox(height: 10),
                      Text(
                        'Sneak past the cats. Grab the cheese. Get home.',
                        textAlign: TextAlign.center,
                        style: AppText.body(14.5, color: const Color(0xFFD7E2FF)),
                      ),
                      SizedBox(height: compact ? 14 : 22),

                      // Play button breathes so it draws the eye
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, child) {
                          final k = 0.5 + 0.5 * math.sin(_pulse.value * math.pi * 4);
                          return Transform.scale(
                            scale: 1 + 0.018 * k,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9A1F).withValues(alpha: 0.18 + 0.3 * k),
                                    blurRadius: 14 + 12 * k,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: ChunkyButton(
                          label: 'PLAY  LEVEL $level',
                          icon: Icons.play_arrow_rounded,
                          color: AppColors.cheeseDeep,
                          shadeColor: const Color(0xFFA35400),
                          height: 64,
                          fontSize: 22,
                          onPressed: () => _open(GameScreen(levelNumber: level)),
                        ),
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

                      GestureDetector(
                        onTap: _openGuide,
                        child: GlassCard(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _Tip(
                                    icon: Icons.touch_app_rounded,
                                    color: AppColors.mint,
                                    title: 'Tap',
                                    sub: 'to move',
                                  ),
                                  _Tip(
                                    icon: Icons.radar_rounded,
                                    color: AppColors.coral,
                                    title: 'Radar',
                                    sub: 'stay outside',
                                  ),
                                  _Tip(
                                    icon: Icons.grid_view_rounded,
                                    color: AppColors.violet,
                                    title: 'Walls',
                                    sub: 'break sight',
                                  ),
                                  _Tip(
                                    icon: Icons.home_rounded,
                                    color: AppColors.cheese,
                                    title: 'House',
                                    sub: 'to win',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.help_outline_rounded, size: 15, color: AppColors.textMuted),
                                  const SizedBox(width: 5),
                                  Text('Tap for the full guide', style: AppText.body(12)),
                                ],
                              ),
                            ],
                          ),
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
