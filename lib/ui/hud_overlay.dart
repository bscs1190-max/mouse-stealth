import 'package:flutter/material.dart';

import '../game/models/game_state.dart';
import '../game/models/power_up.dart';
import '../game/services/level_repository.dart';
import 'demo/demo_scene.dart';
import 'theme/app_theme.dart';
import 'widgets/game_ui.dart';
import 'widgets/outlined_text.dart';

/// Heights the HUD occupies (excluding safe-area padding); the game uses them
/// to fit the board between the bars.
class HudMetrics {
  static const double top = 112;
  static const double bottom = 84;
}

class HudOverlay extends StatelessWidget {
  final MazeLevelData levelData;
  final GameSessionState session;
  final bool spotted;
  final String? lifeLostMessage;
  final String? toastMessage;
  final Map<PowerUpKind, double> activeEffects;
  final int hammerCharges;
  final bool breakMode;
  final bool? keyCollected; // null: this level has no key
  final bool? gateOpen; // null: this level has no gate
  final VoidCallback onFitPressed;
  final VoidCallback onHintPressed;
  final VoidCallback onResetPressed;
  final VoidCallback onBackPressed;
  final VoidCallback onBreakPressed;

  const HudOverlay({
    super.key,
    required this.levelData,
    required this.session,

    required this.onFitPressed,
    required this.onHintPressed,
    required this.onResetPressed,
    required this.onBackPressed,
    required this.onBreakPressed,
    required this.hammerCharges,
    this.breakMode = false,
    this.activeEffects = const {},
    this.keyCollected,
    this.gateOpen,
    this.spotted = false,
    this.lifeLostMessage,
    this.toastMessage,
  });

  String _formatTime(double seconds) {
    final totalSec = seconds.ceil();
    return '${(totalSec ~/ 60).toString().padLeft(2, '0')}:${(totalSec % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final time = session.remainingTime;
    final isTimeLow = time != null && time <= 15.0;
    final diffColor = difficultyColor(levelData.difficultyTag);

    // Highest-priority banner first.
    Widget banner = const SizedBox.shrink(key: ValueKey('none'));
    if (lifeLostMessage != null) {
      banner = _Banner(
        key: const ValueKey('lost'),
        color: AppColors.coral,
        icon: Icons.heart_broken_rounded,
        text: '$lifeLostMessage!  −1 ❤',
      );
    } else if (toastMessage != null) {
      banner = _Banner(
        key: ValueKey('toast$toastMessage'),
        color: AppColors.violetDeep,
        icon: Icons.auto_awesome_rounded,
        text: toastMessage!,
      );
    } else if (spotted) {
      banner = const _Banner(
        key: ValueKey('spotted'),
        color: AppColors.cheeseDeep,
        icon: Icons.warning_amber_rounded,
        text: 'Spotted! Hide behind a wall',
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          // ---------------- TOP BAR ----------------
          Positioned(
            top: 6,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Row(
                  children: [
                    RoundIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onTap: onBackPressed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassCard(
                        radius: 18,
                        borderColor: diffColor.withValues(alpha: 0.7),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  OutlinedText('Level ${levelData.levelNumber}', size: 20, align: TextAlign.left),
                                  Text(
                                    levelData.theme.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(11, color: AppColors.textFaint),
                                  ),
                                ],
                              ),
                            ),
                            DifficultyBadge(tag: levelData.difficultyTag),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    RoundIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart level', onTap: onResetPressed),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Pill(
                              borderColor: AppColors.coral.withValues(alpha: 0.6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(session.maxHearts, (i) {
                                  final alive = i < session.hearts;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 1),
                                    child: Icon(
                                      alive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      size: 18,
                                      color: alive ? AppColors.coral : AppColors.textFaint,
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _Pill(
                              borderColor: AppColors.cheese.withValues(alpha: 0.6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🧀', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${session.collectedCheese}/${session.totalCheese}',
                                    style: AppText.number(14, color: AppColors.cheese),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            _Pill(
                              borderColor: AppColors.textFaint.withValues(alpha: 0.6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🐱', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text('${levelData.cats.length}', style: AppText.number(14)),
                                ],
                              ),
                            ),
                            if (keyCollected != null) ...[
                              const SizedBox(width: 6),
                              _Pill(
                                borderColor: (keyCollected! ? AppColors.mint : AppColors.cheese).withValues(alpha: 0.7),
                                child: Icon(
                                  keyCollected! ? Icons.lock_open_rounded : Icons.vpn_key_rounded,
                                  size: 16,
                                  color: keyCollected! ? AppColors.mint : AppColors.cheese,
                                ),
                              ),
                            ],
                            if (gateOpen != null) ...[
                              const SizedBox(width: 6),
                              _Pill(
                                borderColor: (gateOpen! ? AppColors.mint : AppColors.violet).withValues(alpha: 0.7),
                                child: Icon(
                                  gateOpen! ? Icons.meeting_room_rounded : Icons.fence_rounded,
                                  size: 16,
                                  color: gateOpen! ? AppColors.mint : AppColors.violet,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (time != null)
                      _Pill(
                        color: isTimeLow ? AppColors.coralDeep.withValues(alpha: 0.85) : null,
                        borderColor: isTimeLow ? AppColors.coral : AppColors.sky.withValues(alpha: 0.6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_rounded, size: 16, color: isTimeLow ? Colors.white : AppColors.sky),
                            const SizedBox(width: 4),
                            Text(_formatTime(time), style: AppText.number(14)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ---------------- BANNERS + ACTIVE POWER-UPS ----------------
          Positioned(
            top: HudMetrics.top + 2,
            left: 12,
            right: 12,
            child: IgnorePointer(
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: banner,
                  ),
                  if (activeEffects.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      alignment: WrapAlignment.center,
                      children: [for (final e in activeEffects.entries) _EffectChip(kind: e.key, secondsLeft: e.value)],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ---------------- BOTTOM ACTIONS ----------------
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: Row(
              children: [
                Expanded(
                  child: ChunkyButton(
                    label: breakMode ? 'CANCEL' : 'BREAK ×$hammerCharges',
                    leading: Text(breakMode ? '✖' : '🔨', style: const TextStyle(fontSize: 18)),
                    color: breakMode ? AppColors.coralDeep : AppColors.cheeseDeep,
                    shadeColor: breakMode ? const Color(0xFF8E1238) : const Color(0xFFA35400),
                    height: 52,
                    fontSize: 16,
                    onPressed: hammerCharges > 0 || breakMode ? onBreakPressed : null,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Show whole map',
                  child: GestureDetector(
                    onTap: onFitPressed,
                    child: const GlassCard(
                      radius: 18,
                      padding: EdgeInsets.all(13),
                      child: Icon(Icons.fit_screen_rounded, color: AppColors.text, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChunkyButton(
                    label: 'HINT',
                    icon: Icons.lightbulb_rounded,
                    color: AppColors.violetDeep,
                    shadeColor: const Color(0xFF3A2AA8),
                    height: 52,
                    fontSize: 16,
                    onPressed: onHintPressed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card shown before a level starts.
class LevelIntroCard extends StatefulWidget {
  final MazeLevelData levelData;
  final List<String> notes;
  final List<DemoKind> demos; // short looping demos of things new in this level
  final VoidCallback onStart;

  const LevelIntroCard({
    super.key,
    required this.levelData,
    required this.notes,
    required this.onStart,
    this.demos = const [],
  });

  @override
  State<LevelIntroCard> createState() => _LevelIntroCardState();
}

class _LevelIntroCardState extends State<LevelIntroCard> {
  int _demoPage = 0;

  @override
  Widget build(BuildContext context) {
    final levelData = widget.levelData;
    final notes = widget.notes;
    final demos = widget.demos;
    final onStart = widget.onStart;

    final color = difficultyColor(levelData.difficultyTag);
    final powerUps = levelData.powerUps.map((p) => p.kind).toSet();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          builder: (context, s, child) => Transform.scale(scale: s, child: child),
          child: GlassCard(
            color: AppColors.surface,
            borderColor: color,
            radius: 28,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DifficultyBadge(tag: levelData.difficultyTag, large: true),
                const SizedBox(height: 10),
                Text('Level ${levelData.levelNumber}', style: AppText.display(34)),
                Text(levelData.theme.name, style: AppText.body(14)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _InfoChip(icon: '🐱', text: '${levelData.cats.length} cat${levelData.cats.length > 1 ? 's' : ''}'),
                    _InfoChip(icon: '🧀', text: '${levelData.cheesePositions.length} cheese'),
                    _InfoChip(icon: '⏱', text: '${levelData.timeLimitSeconds}s'),
                    _InfoChip(icon: '🔨', text: '×${levelData.hammerCharges}'),
                    for (final k in powerUps) _InfoChip(icon: k.emoji, text: k.label),
                  ],
                ),
                if (demos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'NEW IN THIS LEVEL',
                      style: AppText.body(11.5, color: AppColors.mint).copyWith(letterSpacing: 2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 262,
                    child: PageView.builder(
                      itemCount: demos.length,
                      onPageChanged: (i) => setState(() => _demoPage = i),
                      itemBuilder: (context, i) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DemoView(kind: demos[i], height: 130),
                          const SizedBox(height: 8),
                          Text(demos[i].title, style: AppText.title(16)),
                          const SizedBox(height: 2),
                          Text(demos[i].caption, style: AppText.body(12.5)),
                        ],
                      ),
                    ),
                  ),
                  if (demos.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < demos.length; i++)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _demoPage ? 18 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _demoPage ? AppColors.mint : AppColors.outline,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  for (final n in notes)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.mint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.mint.withValues(alpha: 0.5)),
                      ),
                      child: Text(n, style: AppText.body(13, color: AppColors.text)),
                    ),
                ],
                const SizedBox(height: 14),
                ChunkyButton(
                  label: 'START',
                  icon: Icons.play_arrow_rounded,
                  color: const Color(0xFF22C55E),
                  shadeColor: const Color(0xFF15803D),
                  onPressed: onStart,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgBottom.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(text, style: AppText.body(13, color: AppColors.text)),
        ],
      ),
    );
  }
}

class _EffectChip extends StatelessWidget {
  final PowerUpKind kind;
  final double secondsLeft;
  const _EffectChip({required this.kind, required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    const colors = {
      PowerUpKind.freeze: Color(0xFF38BDF8),
      PowerUpKind.speed: Color(0xFFFACC15),
      PowerUpKind.ghost: Color(0xFFC084FC),
    };
    final c = colors[kind]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c, width: 1.5),
      ),
      child: Text(
        '${kind.emoji} ${kind.label} ${secondsLeft.ceil()}s',
        style: AppText.title(12.5, color: Colors.white),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color borderColor;
  const _Pill({required this.child, required this.borderColor, this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: child,
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _Banner({super.key, required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 16)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Flexible(
            child: Text(text, style: AppText.title(13.5), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
