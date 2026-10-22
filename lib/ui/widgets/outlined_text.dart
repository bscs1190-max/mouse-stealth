import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Chunky arcade text: a fill colour, a thick dark outline and a soft drop shadow.
class OutlinedText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final Color outline;
  final double strokeWidth;
  final TextAlign align;
  final double letterSpacing;
  final int? maxLines;

  const OutlinedText(
    this.text, {
    super.key,
    this.size = 24,
    this.color = Colors.white,
    this.outline = const Color(0xFF14183A),
    this.strokeWidth = 0,
    this.align = TextAlign.center,
    this.letterSpacing = 0.5,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final stroke = strokeWidth > 0 ? strokeWidth : size * 0.2;
    final base = AppText.display(size).copyWith(letterSpacing: letterSpacing);
    return Stack(
      alignment: Alignment.center,
      children: [
        // Drop shadow
        Transform.translate(
          offset: Offset(0, size * 0.07),
          child: Text(
            text,
            textAlign: align,
            maxLines: maxLines,
            style: base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = stroke
                ..strokeJoin = StrokeJoin.round
                ..color = Colors.black.withValues(alpha: 0.35),
            ),
          ),
        ),
        // Outline
        Text(
          text,
          textAlign: align,
          maxLines: maxLines,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke
              ..strokeJoin = StrokeJoin.round
              ..color = outline,
          ),
        ),
        // Fill
        Text(
          text,
          textAlign: align,
          maxLines: maxLines,
          style: base.copyWith(color: color),
        ),
      ],
    );
  }
}
