import 'package:flutter/material.dart';

import 'demo/demo_scene.dart';
import 'theme/app_theme.dart';
import 'widgets/game_ui.dart';

/// Step-by-step "how to play" guide: animated demo pages plus a legend of the
/// on-screen controls. Shown before the very first level and from the home screen.
class TutorialOverlay extends StatefulWidget {
  final VoidCallback onDone;
  final String finishLabel;

  const TutorialOverlay({super.key, required this.onDone, this.finishLabel = "LET'S PLAY"});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  static const _demos = [DemoKind.goal, DemoKind.tapMove, DemoKind.radar, DemoKind.zoomPan];
  static const _pageCount = 5; // 4 demos + the controls legend
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pageCount - 1) {
      widget.onDone();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pageCount - 1;
    return Material(
      color: AppColors.bgBottom.withValues(alpha: 0.97),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Text('How to play', style: AppText.display(24)),
                  const Spacer(),
                  if (!last)
                    TextButton(
                      onPressed: widget.onDone,
                      child: Text('Skip', style: AppText.title(15, color: AppColors.textMuted)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pageCount,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => i < _demos.length
                      ? _DemoPage(step: i + 1, kind: _demos[i])
                      : const _ControlsPage(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < _pageCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.cheese : AppColors.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              ChunkyButton(
                label: last ? widget.finishLabel : 'NEXT',
                icon: last ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                color: last ? const Color(0xFF22C55E) : AppColors.violetDeep,
                shadeColor: last ? const Color(0xFF15803D) : const Color(0xFF3A2AA8),
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoPage extends StatelessWidget {
  final int step;
  final DemoKind kind;
  const _DemoPage({required this.step, required this.kind});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('STEP $step', style: AppText.body(12, color: AppColors.mint).copyWith(letterSpacing: 2.5)),
          const SizedBox(height: 2),
          Text(kind.title, style: AppText.display(30)),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(8),
            borderColor: AppColors.violet.withValues(alpha: 0.5),
            child: DemoView(kind: kind, height: 190),
          ),
          const SizedBox(height: 16),
          Text(kind.caption, style: AppText.body(16, color: AppColors.text)),
        ],
      ),
    );
  }
}

/// Legend of everything on the playing screen.
class _ControlsPage extends StatelessWidget {
  const _ControlsPage();

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, Color color, String title, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.16),
                  border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.title(15.5)),
                    Text(text, style: AppText.body(13)),
                  ],
                ),
              ),
            ],
          ),
        );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('GOOD TO KNOW', style: AppText.body(12, color: AppColors.mint).copyWith(letterSpacing: 2.5)),
          const SizedBox(height: 2),
          Text('Your toolkit', style: AppText.display(30)),
          const SizedBox(height: 10),
          row(Icons.favorite_rounded, AppColors.coral, 'Hearts',
              'You have 3. A cat catch or a trap costs one and sends everyone back to the start.'),
          row(Icons.timer_rounded, AppColors.sky, 'Timer', 'Reach the house before it runs out.'),
          row(Icons.lunch_dining_rounded, AppColors.cheese, 'Cheese', 'Collect all three for three stars.'),
          row(Icons.construction_rounded, const Color(0xFFF08A00), 'BREAK',
              'Smash one wall or crate to open a shortcut. Limited uses per level.'),
          row(Icons.lightbulb_rounded, AppColors.violet, 'HINT', 'Shows the way to your next goal for a few seconds.'),
          row(Icons.fit_screen_rounded, AppColors.text, 'Fit', 'Brings the whole map back into view.'),
        ],
      ),
    );
  }
}
