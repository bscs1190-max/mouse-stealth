import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-screen gradient backdrop with soft glowing orbs.
class GameBackground extends StatelessWidget {
  final Widget child;
  const GameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(top: -80, left: -60, child: _Orb(220, AppColors.violet)),
          const Positioned(top: 180, right: -90, child: _Orb(200, AppColors.mint)),
          const Positioned(bottom: -70, left: 40, child: _Orb(240, AppColors.cheeseDeep)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb(this.size, this.color);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}

/// Translucent rounded panel used for cards and HUD pieces.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.borderColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.outline.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

/// Chunky "3D" game button that sinks when pressed.
class ChunkyButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Widget? leading;
  final Color color;
  final Color shadeColor;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final bool expand;

  const ChunkyButton({
    super.key,
    required this.label,
    required this.color,
    required this.shadeColor,
    this.icon,
    this.leading,
    this.onPressed,
    this.height = 58,
    this.fontSize = 20,
    this.expand = true,
  });

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 6.0;
    final enabled = widget.onPressed != null;
    final face = enabled ? widget.color : AppColors.surfaceHigh;
    final shade = enabled ? widget.shadeColor : AppColors.outline;
    final offset = _down ? depth - 1 : 0.0;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 10)],
        if (widget.icon != null) ...[
          Icon(widget.icon, color: Colors.white, size: widget.fontSize + 6),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          maxLines: 1,
          style: AppText.display(widget.fontSize, color: enabled ? Colors.white : AppColors.textFaint).copyWith(
            letterSpacing: 0.8,
            shadows: enabled ? [Shadow(color: Colors.black.withValues(alpha: 0.25), offset: const Offset(0, 2))] : null,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onPressed!();
              }
            : null,
        child: SizedBox(
          height: widget.height + depth,
          width: widget.expand ? double.infinity : null,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: widget.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: shade, borderRadius: BorderRadius.circular(20)),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 70),
                left: 0,
                right: 0,
                top: offset,
                height: widget.height,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.lerp(face, Colors.white, 0.18)!, face],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: enabled ? 0.25 : 0.05), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(fit: BoxFit.scaleDown, child: content),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round icon button used in top bars.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final double size;
  final Color? color;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.size = 44,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (color ?? AppColors.surfaceHigh).withValues(alpha: 0.92),
              border: Border.all(color: AppColors.outline, width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: AppColors.text, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}

/// Cheese currency counter pill.
class CheeseCounter extends StatelessWidget {
  final int amount;
  const CheeseCounter({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cheese.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.cheese, AppColors.cheeseDeep]),
            ),
            child: const Text('🧀', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 8),
          Text('$amount', style: AppText.number(17, color: AppColors.cheese)),
        ],
      ),
    );
  }
}

/// Small coloured tag (e.g. difficulty).
class TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const TagChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1.2),
      ),
      child: Text(label, style: AppText.title(11, color: color).copyWith(letterSpacing: 1.2)),
    );
  }
}

/// Three stars, earned ones in gold.
class StarRow extends StatelessWidget {
  final int stars;
  final double size;
  final double spacing;
  const StarRow({super.key, required this.stars, this.size = 16, this.spacing = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final earned = i < stars;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: Icon(
            Icons.star_rounded,
            size: size,
            color: earned ? AppColors.cheese : AppColors.outline,
            shadows: earned ? [Shadow(color: AppColors.cheese.withValues(alpha: 0.6), blurRadius: 8)] : null,
          ),
        );
      }),
    );
  }
}

/// EASY = mint, MEDIUM = orange, HARD = red.
Color difficultyColor(String tag) {
  switch (tag) {
    case 'HARD':
      return const Color(0xFFFF3B5C);
    case 'MEDIUM':
      return const Color(0xFFFF9F1A);
    default:
      return AppColors.mint;
  }
}

/// Coloured difficulty pill with an icon (leaf easy, bolt medium, flame hard).
class DifficultyBadge extends StatelessWidget {
  final String tag;
  final bool large;
  const DifficultyBadge({super.key, required this.tag, this.large = false});

  @override
  Widget build(BuildContext context) {
    final c = difficultyColor(tag);
    final icon = switch (tag) {
      'HARD' => Icons.whatshot_rounded,
      'MEDIUM' => Icons.bolt_rounded,
      _ => Icons.eco_rounded,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 9, vertical: large ? 5 : 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color.lerp(c, Colors.white, 0.15)!, Color.lerp(c, Colors.black, 0.2)!]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.45), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: large ? 16 : 12),
          const SizedBox(width: 4),
          Text(tag, style: AppText.title(large ? 14 : 11, color: Colors.white).copyWith(letterSpacing: 1.2)),
        ],
      ),
    );
  }
}
