import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CheeseBadge extends StatelessWidget {
  final int collected;
  final int total;

  const CheeseBadge({
    super.key,
    required this.collected,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2050), Color(0xFF1E2438)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🧀', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '$collected / $total',
            style: GoogleFonts.sniglet(
              color: const Color(0xFFFFD54F),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
