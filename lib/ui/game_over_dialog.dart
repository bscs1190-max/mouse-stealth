import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'widgets/game_ui.dart';

class GameOverDialog extends StatelessWidget {
  final VoidCallback onWatchAdContinue;
  final VoidCallback onRestart;
  final VoidCallback onBackToLevels;
  final bool timeUp;

  const GameOverDialog({
    super.key,
    required this.onWatchAdContinue,
    required this.onRestart,
    required this.onBackToLevels,
    this.timeUp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (context, s, child) => Transform.scale(scale: s, child: child),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: GlassCard(
            color: AppColors.surface,
            borderColor: AppColors.coral.withValues(alpha: 0.8),
            radius: 30,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.coral.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.coral.withValues(alpha: 0.6), width: 2),
                  ),
                  child: Icon(
                    timeUp ? Icons.timer_off_rounded : Icons.heart_broken_rounded,
                    color: AppColors.coral,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 14),
                Text(timeUp ? "Time's up!" : 'Out of lives!', style: AppText.display(30)),
                const SizedBox(height: 6),
                Text(
                  timeUp
                      ? 'The clock beat you this time.'
                      : 'The cats got the better of you.\nStay outside their radar and hide behind walls.',
                  textAlign: TextAlign.center,
                  style: AppText.body(14),
                ),
                const SizedBox(height: 22),
                ChunkyButton(
                  label: timeUp ? 'CONTINUE  +30s' : 'CONTINUE  +1 ❤',
                  icon: Icons.play_circle_fill_rounded,
                  color: AppColors.cheeseDeep,
                  shadeColor: const Color(0xFFA35400),
                  fontSize: 18,
                  onPressed: onWatchAdContinue,
                ),
                const SizedBox(height: 12),
                ChunkyButton(
                  label: 'TRY AGAIN',
                  icon: Icons.refresh_rounded,
                  color: AppColors.skyDeep,
                  shadeColor: const Color(0xFF14559A),
                  fontSize: 18,
                  onPressed: onRestart,
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: onBackToLevels,
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMuted, size: 18),
                  label: Text('Back', style: AppText.body(14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
