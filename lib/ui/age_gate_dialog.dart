import 'package:flutter/material.dart';

import '../game/rendering/procedural_painter.dart';
import '../game/services/progress_service.dart';
import 'theme/app_theme.dart';
import 'widgets/game_ui.dart';
import 'widgets/outlined_text.dart';

/// Attractive, kid-friendly age selection modal presented to first-time downloaders.
class AgeGateDialog extends StatefulWidget {
  final VoidCallback onAgeConfirmed;

  const AgeGateDialog({super.key, required this.onAgeConfirmed});

  @override
  State<AgeGateDialog> createState() => _AgeGateDialogState();
}

class _AgeGateDialogState extends State<AgeGateDialog> with SingleTickerProviderStateMixin {
  int _selectedAge = 9;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _confirm() {
    ProgressService().playerAge = _selectedAge;
    widget.onAgeConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2B5BE8), Color(0xFF142C7D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF70B1FF), width: 3.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Mascot Avatar with subtle idle bounce
            AnimatedBuilder(
              animation: _anim,
              builder: (context, child) {
                final bounce = _anim.value * 6.0;
                return Transform.translate(
                  offset: Offset(0, -bounce),
                  child: child,
                );
              },
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFDF7A), Color(0xFFE59C00)],
                    radius: 0.85,
                  ),
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _MascotPainter(),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Title
            OutlinedText(
              'WELCOME!',
              size: 32,
              color: const Color(0xFFFFE082),
              outline: const Color(0xFF0A184A),
            ),
            const SizedBox(height: 6),
            Text(
              'How old are you, little explorer?',
              textAlign: TextAlign.center,
              style: AppText.title(15, color: const Color(0xFFD6E6FF)),
            ),
            const SizedBox(height: 22),

            // Big Playful Age Pill Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F205A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF4C87F2), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _selectedAge > 3
                        ? () => setState(() => _selectedAge--)
                        : null,
                    icon: const Icon(Icons.remove_circle_rounded, color: Color(0xFFFFD54F), size: 36),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_selectedAge',
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Sniglet',
                          height: 1.0,
                          shadows: [
                            Shadow(color: Color(0xFF00E5FF), blurRadius: 12),
                          ],
                        ),
                      ),
                      Text(
                        'years old',
                        style: AppText.body(12, color: const Color(0xFFA5C5FF)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    onPressed: _selectedAge < 18
                        ? () => setState(() => _selectedAge++)
                        : null,
                    icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFFFD54F), size: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Slider for fast scrolling
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFFFB300),
                inactiveTrackColor: const Color(0xFF1B3B8A),
                thumbColor: const Color(0xFFFFD54F),
                overlayColor: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
              ),
              child: Slider(
                value: _selectedAge.toDouble(),
                min: 3,
                max: 18,
                divisions: 15,
                onChanged: (v) => setState(() => _selectedAge = v.round()),
              ),
            ),
            const SizedBox(height: 14),

            // Confirm Button
            ChunkyButton(
              label: "LET'S PLAY!",
              icon: Icons.play_arrow_rounded,
              color: const Color(0xFF22C55E),
              shadeColor: const Color(0xFF15803D),
              onPressed: _confirm,
            ),
            const SizedBox(height: 10),
            Text(
              'Your age customizes safety & level pace',
              style: AppText.body(11, color: const Color(0xFF90B5F0)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    ProceduralPainter.drawMouse(
      canvas,
      size,
      animTimer: 0.0,
      isHappy: true,
      skinId: 'mouse_classic',
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
