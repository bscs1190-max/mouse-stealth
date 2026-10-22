import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/rendering/procedural_painter.dart';
import 'theme/app_theme.dart';
import 'widgets/arcade_art.dart';
import 'widgets/game_ui.dart';
import 'widgets/outlined_text.dart';

/// Level result in two beats: a VICTORY banner with the earned stars, then a
/// chest that bursts open and pays out the cheese you collected.
class LevelCompleteDialog extends StatefulWidget {
  final int level;
  final String worldName;
  final int stars;
  final int collectedCheese;
  final int totalCheese;
  final int heartsLeft;
  final int cheeseBank; // total cheese AFTER this reward was added
  final VoidCallback onReplay;
  final VoidCallback onNextLevel;

  const LevelCompleteDialog({
    super.key,
    required this.level,
    required this.worldName,
    required this.stars,
    required this.collectedCheese,
    required this.totalCheese,
    required this.heartsLeft,
    required this.cheeseBank,
    required this.onReplay,
    required this.onNextLevel,
  });

  @override
  State<LevelCompleteDialog> createState() => _LevelCompleteDialogState();
}

class _LevelCompleteDialogState extends State<LevelCompleteDialog> with TickerProviderStateMixin {
  bool _reward = false;
  late AnimationController _victory;
  late AnimationController _chest;

  @override
  void initState() {
    super.initState();
    _victory = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();
    _chest = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  }

  @override
  void dispose() {
    _victory.dispose();
    _chest.dispose();
    super.dispose();
  }

  void _toReward() {
    setState(() => _reward = true);
    _chest.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _reward ? _buildReward(context) : _buildVictory(context),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 1. VICTORY
  // --------------------------------------------------------------------------
  Widget _buildVictory(BuildContext context) {
    return GameBackground(
      key: const ValueKey('victory'),
      top: const Color(0xFF3E7BFF),
      bottom: const Color(0xFF13286F),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _victory,
          builder: (context, _) {
            double part(double a, double b, Curve c) => c.transform(((_victory.value - a) / (b - a)).clamp(0.0, 1.0));
            final title = part(0.0, 0.3, Curves.elasticOut);
            final info = part(0.55, 0.8, Curves.easeOut);
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Transform.scale(
                    scale: title,
                    child: OutlinedText('VICTORY!', size: 62, color: const Color(0xFFFFD54F)),
                  ),
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: info.clamp(0.0, 1.0),
                    child: RibbonBanner(
                      fillTop: const Color(0xFF6FB1FF),
                      fillBottom: const Color(0xFF2B63E0),
                      border: const Color(0xFF0E1D5C),
                      height: 62,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedText('Level ${widget.level} cleared', size: 22, outline: const Color(0xFF0E1D5C)),
                          Text(widget.worldName, style: AppText.body(12, color: const Color(0xFFD7E6FF))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  // Three stars with a staggered pop
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < 3; i++)
                        Padding(
                          padding: EdgeInsets.only(bottom: i == 1 ? 18 : 0, left: 4, right: 4),
                          child: _StarMedal(
                            earned: i < widget.stars,
                            size: i == 1 ? 108 : 88,
                            pop: part(0.25 + i * 0.12, 0.45 + i * 0.12, Curves.elasticOut),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Opacity(
                    opacity: info.clamp(0.0, 1.0),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _StatChip(
                          icon: Icons.lunch_dining_rounded,
                          color: AppColors.cheese,
                          text: '${widget.collectedCheese}/${widget.totalCheese}',
                        ),
                        _StatChip(
                          icon: Icons.favorite_rounded,
                          color: AppColors.coral,
                          text: '${widget.heartsLeft} hearts left',
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  Opacity(
                    opacity: info.clamp(0.0, 1.0),
                    child: ChunkyButton(
                      label: 'CONTINUE',
                      icon: Icons.arrow_forward_rounded,
                      color: const Color(0xFF22C55E),
                      shadeColor: const Color(0xFF15803D),
                      onPressed: _toReward,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 2. REWARD CHEST
  // --------------------------------------------------------------------------
  Widget _buildReward(BuildContext context) {
    final reward = widget.collectedCheese;
    final before = widget.cheeseBank - reward;
    return GameBackground(
      key: const ValueKey('reward'),
      top: const Color(0xFF1E64B8),
      bottom: const Color(0xFF0B2150),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _chest,
          builder: (context, _) {
            double part(double a, double b, Curve c) => c.transform(((_chest.value - a) / (b - a)).clamp(0.0, 1.0));
            final open = part(0.18, 0.4, Curves.easeOutBack);
            final card = part(0.35, 0.55, Curves.easeOutBack);
            final count = part(0.5, 0.9, Curves.easeOut);
            final shown = (before + reward * count).round();
            final buttons = part(0.85, 1.0, Curves.easeOut);
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              child: Column(
                children: [
                  // Reward card + bank bar (top row)
                  Transform.scale(
                    scale: card,
                    alignment: Alignment.topLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CheeseCard(amount: reward),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlinedText('Cheese', size: 34, align: TextAlign.left),
                              Text('Reward', style: AppText.title(18, color: const Color(0xFFFFF1A8))),
                              const SizedBox(height: 12),
                              Text('Your cheese:', style: AppText.body(13, color: const Color(0xFFB9D2FF))),
                              const SizedBox(height: 4),
                              _BankBar(amount: shown),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // The chest
                  SizedBox(
                    height: 250,
                    width: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(child: CustomPaint(painter: ChestPainter(open, _chest.value * 6))),
                        // Cheese popping out
                        for (int i = 0; i < math.min(reward, 7); i++)
                          _PoppingCheese(
                            index: i,
                            total: math.min(reward, 7),
                            progress: part(0.3 + i * 0.03, 0.8, Curves.easeOutCubic),
                          ),
                        Positioned(
                          right: 22,
                          top: 28,
                          child: Opacity(
                            opacity: card.clamp(0.0, 1.0),
                            child: Transform.rotate(angle: 0.18, child: _StarBadge(count: widget.stars)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Opacity(
                    opacity: buttons.clamp(0.0, 1.0),
                    child: IgnorePointer(
                      ignoring: buttons < 0.6,
                      child: Column(
                        children: [
                          ChunkyButton(
                            label: 'NEXT LEVEL',
                            icon: Icons.arrow_forward_rounded,
                            color: const Color(0xFF22C55E),
                            shadeColor: const Color(0xFF15803D),
                            onPressed: widget.onNextLevel,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: widget.onReplay,
                            icon: const Icon(Icons.replay_rounded, color: Color(0xFFB9D2FF)),
                            label: Text(
                              'Replay for more stars',
                              style: AppText.body(14, color: const Color(0xFFB9D2FF)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A big gold star medal that pops in.
class _StarMedal extends StatelessWidget {
  final bool earned;
  final double size;
  final double pop;
  const _StarMedal({required this.earned, required this.size, required this.pop});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: earned ? pop : 1.0,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: earned
                ? const [Color(0xFF6FB1FF), Color(0xFF2B63E0)]
                : const [Color(0xFF2A3A78), Color(0xFF1B2556)],
          ),
          border: Border.all(color: earned ? const Color(0xFFFFD54F) : const Color(0xFF3A4A8C), width: 5),
          boxShadow: [
            BoxShadow(
              color: (earned ? const Color(0xFFFFD54F) : Colors.black).withValues(alpha: earned ? 0.55 : 0.25),
              blurRadius: earned ? 22 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          Icons.star_rounded,
          size: size * 0.66,
          color: earned ? const Color(0xFFFFD54F) : const Color(0xFF3A4A8C),
          shadows: earned ? const [Shadow(color: Color(0xFF8A5200), offset: Offset(0, 3))] : null,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _StatChip({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1D5C).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(text, style: AppText.title(16)),
        ],
      ),
    );
  }
}

/// Framed card showing the cheese reward.
class _CheeseCard extends StatelessWidget {
  final int amount;
  const _CheeseCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1B2556), width: 5),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD8E2F5), Color(0xFF8E9DBF)],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 14,
            child: SizedBox(width: 74, height: 74, child: CustomPaint(painter: _CheesePilePainter())),
          ),
          Positioned(bottom: 4, child: OutlinedText('+$amount', size: 34)),
        ],
      ),
    );
  }
}

class _CheesePilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in const [Offset(0.5, 0.62), Offset(0.28, 0.5), Offset(0.72, 0.46), Offset(0.5, 0.3)]) {
      canvas.save();
      canvas.translate(size.width * p.dx - 17, size.height * p.dy - 17);
      ProceduralPainter.drawCheese(canvas, const Size(34, 34));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// "Your cheese:" bar with a coin at the end.
class _BankBar extends StatelessWidget {
  final int amount;
  const _BankBar({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Container(
          height: 34,
          width: double.infinity,
          padding: const EdgeInsets.only(right: 40),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1740),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF061029), width: 3),
          ),
          child: OutlinedText('$amount', size: 22, outline: const Color(0xFF061029)),
        ),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE27A), Color(0xFFE59A00)],
            ),
          ),
          child: const Icon(Icons.lunch_dining_rounded, color: Color(0xFF8A5200), size: 24),
        ),
      ],
    );
  }
}

/// A cheese wedge flying up out of the open chest.
class _PoppingCheese extends StatelessWidget {
  final int index;
  final int total;
  final double progress;
  const _PoppingCheese({required this.index, required this.total, required this.progress});

  @override
  Widget build(BuildContext context) {
    final spread = (index - (total - 1) / 2) / math.max(1, total - 1);
    final dx = spread * 170 * progress;
    final dy = -math.sin(progress * math.pi) * 90 - progress * 40;
    return Positioned(
      top: 84 + dy,
      left: 100 + dx,
      child: Opacity(
        opacity: progress <= 0 ? 0 : (1 - progress * 0.7),
        child: Transform.rotate(
          angle: (index.isEven ? 1 : -1) * progress * 1.2,
          child: const SizedBox(width: 44, height: 44, child: CustomPaint(painter: _SingleCheesePainter())),
        ),
      ),
    );
  }
}

class _SingleCheesePainter extends CustomPainter {
  const _SingleCheesePainter();
  @override
  void paint(Canvas canvas, Size size) => ProceduralPainter.drawCheese(canvas, size);
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Little red card on the chest showing how many stars you earned.
class _StarBadge extends StatelessWidget {
  final int count;
  const _StarBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF6B6B), Color(0xFFC81D4E)],
        ),
        border: Border.all(color: const Color(0xFF5A1230), width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 22),
          OutlinedText('×$count', size: 22),
        ],
      ),
    );
  }
}
