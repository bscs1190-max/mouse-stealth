import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central colour palette for the whole app ("Midnight Cheese" theme).
class AppColors {
  static const bgTop = Color(0xFF151A3D);
  static const bgBottom = Color(0xFF0A0D20);
  static const surface = Color(0xFF1C2250);
  static const surfaceHigh = Color(0xFF262D66);
  static const outline = Color(0xFF3A4389);

  static const cheese = Color(0xFFFFC23D);
  static const cheeseDeep = Color(0xFFF08A00);
  static const mint = Color(0xFF34E0C0);
  static const mintDeep = Color(0xFF0E9F8A);
  static const coral = Color(0xFFFF4D6D);
  static const coralDeep = Color(0xFFC81D4E);
  static const violet = Color(0xFF8B7CFF);
  static const violetDeep = Color(0xFF5A46E0);
  static const sky = Color(0xFF4FC3FF);
  static const skyDeep = Color(0xFF1F7FE0);

  static const text = Color(0xFFF5F3FF);
  static const textMuted = Color(0xFFA4ABD6);
  static const textFaint = Color(0xFF6A72A8);
}

/// Typography: Lilita One for chunky "arcade" headings and numbers, Nunito for readable body text.
class AppText {
  static TextStyle display(double size, {Color color = AppColors.text}) =>
      GoogleFonts.lilitaOne(fontSize: size, color: color, height: 1.05);

  static TextStyle title(double size, {Color color = AppColors.text}) =>
      GoogleFonts.lilitaOne(fontSize: size, color: color);

  static TextStyle body(double size, {Color color = AppColors.textMuted, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color);

  static TextStyle number(double size, {Color color = AppColors.text}) =>
      GoogleFonts.lilitaOne(fontSize: size, color: color);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgBottom,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cheese,
        secondary: AppColors.mint,
        error: AppColors.coral,
        surface: AppColors.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: AppText.body(14, color: AppColors.text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
