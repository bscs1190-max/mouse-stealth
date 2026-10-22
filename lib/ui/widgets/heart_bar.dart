import 'package:flutter/material.dart';

class HeartBar extends StatelessWidget {
  final int currentHearts;
  final int maxHearts;

  const HeartBar({super.key, required this.currentHearts, required this.maxHearts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2438).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF333D5E), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxHearts, (index) {
          final isAlive = index < currentHearts;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: isAlive ? 1.0 : 0.75,
              child: Icon(
                Icons.favorite_rounded,
                color: isAlive ? const Color(0xFFFF3366) : const Color(0xFF555F7A),
                size: 22,
              ),
            ),
          );
        }),
      ),
    );
  }
}
