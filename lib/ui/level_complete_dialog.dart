import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'widgets/game_ui.dart';

class LevelCompleteDialog extends StatelessWidget {
  final int stars;
  final int collectedCheese;
  final int totalCheese;
  final VoidCallback onReplay;
  final VoidCallback onNextLevel;

  const LevelCompleteDialog({
    super.key,
    required this.stars,
    required this.collectedCheese,
    required this.totalCheese,
    required this.onReplay,
    required this.onNextLevel,
  });

  static const _headlines = ['Made it home!', 'Nice sneaking!', 'Sneaky genius!', 'Purr-fect run!'];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.7, end: 1.0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.elasticOut,
        builder: (context, s, child) => Transform.scale(scale: s, child: child),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              GlassCard(
                color: AppColors.surface,
                borderColor: AppColors.cheese.withValues(alpha: 0.8),
                radius: 30,
                padding: const EdgeInsets.fromLTRB(22, 46, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('LEVEL COMPLETE', style: AppText.body(13, color: AppColors.mint).copyWith(letterSpacing: 3)),
                    const SizedBox(height: 4),
                    Text(_headlines[stars.clamp(0, 3)], style: AppText.display(30)),
                    const SizedBox(height: 18),
                    _AnimatedStars(stars: stars),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.bgBottom.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🧀', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Text('$collectedCheese / $totalCheese', style: AppText.number(20, color: AppColors.cheese)),
                          const SizedBox(width: 8),
                          Text('cheese', style: AppText.body(14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    ChunkyButton(
                      label: 'NEXT LEVEL',
                      icon: Icons.arrow_forward_rounded,
                      color: const Color(0xFF22C55E),
                      shadeColor: const Color(0xFF15803D),
                      onPressed: onNextLevel,
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: onReplay,
                      icon: const Icon(Icons.replay_rounded, color: AppColors.textMuted),
                      label: Text('Replay for more stars', style: AppText.body(14)),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -34,
                child: Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [AppColors.cheese, AppColors.cheeseDeep]),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: AppColors.cheese.withValues(alpha: 0.6), blurRadius: 24)],
                  ),
                  child: const Text('🏆', style: TextStyle(fontSize: 32)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedStars extends StatelessWidget {
  final int stars;
  const _AnimatedStars({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final earned = i < stars;
        final big = i == 1;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 350 + i * 220),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Transform.scale(scale: earned ? v : 1, child: child),
          child: Padding(
            padding: EdgeInsets.only(left: 4, right: 4, bottom: big ? 12 : 0),
            child: Icon(
              Icons.star_rounded,
              size: big ? 68 : 54,
              color: earned ? AppColors.cheese : AppColors.outline,
              shadows: earned ? [Shadow(color: AppColors.cheese.withValues(alpha: 0.7), blurRadius: 18)] : null,
            ),
          ),
        );
      }),
    );
  }
}
