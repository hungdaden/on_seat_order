import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryBrown = Color(0xFF1A0F00);
  static const Color primaryOrange = Color(0xFFD35400);
  static const Color accentGold = Color(0xFFD4A84B);
  static const Color warmBrown = Color(0xFF2D1A0A);
  static const Color cardBrown = Color(0xFF3A2214);
  static const Color surfaceBrown = Color(0xFF241408);
  static const Color lightCream = Color(0xFFF5E6D3);
  static const Color textLight = Color(0xFFFAF0E6);
  static const Color textMuted = Color(0xFFB8A08C);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color warningYellow = Color(0xFFF39C12);
  static const Color dangerRed = Color(0xFFE74C3C);
  static const Color infoBlueDark = Color(0xFF2980B9);

  // Order status colors
  static Color statusColor(String status) {
    switch (status) {
      case 'pending': return warningYellow;
      case 'confirmed': return infoBlueDark;
      case 'preparing': return primaryOrange;
      case 'ready': return successGreen;
      case 'completed': return textMuted;
      default: return textMuted;
    }
  }

  static String statusText(String status) {
    switch (status) {
      case 'pending': return 'Chờ xác nhận';
      case 'confirmed': return 'Đã xác nhận';
      case 'preparing': return 'Đang chế biến';
      case 'ready': return 'Sẵn sàng';
      case 'completed': return 'Hoàn thành';
      default: return status;
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.schedule;
      case 'confirmed': return Icons.check_circle_outline;
      case 'preparing': return Icons.restaurant;
      case 'ready': return Icons.notifications_active;
      case 'completed': return Icons.done_all;
      default: return Icons.info_outline;
    }
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: primaryBrown,
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        secondary: accentGold,
        surface: warmBrown,
        error: dangerRed,
        onPrimary: Colors.white,
        onSecondary: primaryBrown,
        onSurface: textLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBrown,
        foregroundColor: textLight,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: accentGold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBrown,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textLight,
          side: const BorderSide(color: textMuted),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceBrown,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceBrown,
        selectedColor: primaryOrange,
        labelStyle: GoogleFonts.inter(fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.bold, color: accentGold),
        displayMedium: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: accentGold),
        headlineLarge: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: textLight),
        headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textLight),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textLight),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: textLight),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textLight),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textLight),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textMuted),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF3A2214), thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBrown,
        contentTextStyle: GoogleFonts.inter(color: textLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${formatted}đ';
  }
}
