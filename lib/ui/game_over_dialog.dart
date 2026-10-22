import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'widgets/arcade_art.dart';
import 'widgets/game_ui.dart';
import 'widgets/outlined_text.dart';

/// Defeat screen: red tiled backdrop, a grinning cat and big clear options.
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
    return Material(
      color: Colors.black,
      child: GameBackground(
        top: const Color(0xFFD1405F),
        bottom: const Color(0xFF3A0F3C),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              children: [
                const Spacer(flex: 2),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, s, child) => Transform.scale(scale: s, child: child),
                  child: OutlinedText(
                    timeUp ? "TIME'S UP!" : 'DEFEAT',
                    size: 58,
                    color: const Color(0xFFFFE0E8),
                    outline: const Color(0xFF4A0F2A),
                  ),
                ),
                const SizedBox(height: 4),
                RibbonBanner(
                  fillTop: const Color(0xFFFF8FA8),
                  fillBottom: const Color(0xFFD03A68),
                  border: const Color(0xFF5A1230),
                  height: 56,
                  child: OutlinedText(
                    timeUp ? 'The clock won this round' : 'The cats got you',
                    size: 20,
                    outline: const Color(0xFF5A1230),
                  ),
                ),
                const Spacer(),
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    const CharacterArt(kind: ArtKind.cat, size: 150, alert: true),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        timeUp ? Icons.timer_off_rounded : Icons.heart_broken_rounded,
                        color: const Color(0xFFFFE0E8),
                        size: 44,
                        shadows: const [Shadow(color: Color(0xFF4A0F2A), offset: Offset(0, 3), blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  timeUp
                      ? 'Plan a faster route, or smash a wall for a shortcut.'
                      : 'Stay outside the radar, hide behind walls and grab an orb before a cat.',
                  textAlign: TextAlign.center,
                  style: AppText.body(14, color: const Color(0xFFFFD6E0)),
                ),
                const Spacer(flex: 2),
                ChunkyButton(
                  label: timeUp ? 'CONTINUE  +30s' : 'CONTINUE  +1 ❤',
                  icon: Icons.play_circle_fill_rounded,
                  color: AppColors.cheeseDeep,
                  shadeColor: const Color(0xFFA35400),
                  fontSize: 19,
                  onPressed: onWatchAdContinue,
                ),
                const SizedBox(height: 12),
                ChunkyButton(
                  label: 'TRY AGAIN',
                  icon: Icons.refresh_rounded,
                  color: AppColors.skyDeep,
                  shadeColor: const Color(0xFF14559A),
                  fontSize: 19,
                  onPressed: onRestart,
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: onBackToLevels,
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFD6E0), size: 18),
                  label: Text('Back to menu', style: AppText.body(14, color: const Color(0xFFFFD6E0))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
