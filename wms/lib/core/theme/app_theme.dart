import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color darkBlue = Color(0xFF004251);
  static const Color lightBlue = Color(0xFF006D84);
  static const Color yellow = Color(0xFFFFDE14);
  static const Color red = Color(0xFFF83737);
  static const Color green = Color(0xFF86B15A);
  static const Color darkGrey = Color(0xFF232323);
  static const Color mediumGrey = Color(0xFF434343);
  static const Color lightGrey = Color(0xFFD7D5D5);
  static const Color veryLightGrey = Color(0xFFF4F2F2);
  
  static const Color primaryTeal = Color(0xFF00796B);
  /// Dark teal for headers (BMS design)
  static const Color headerTeal = Color(0xFF006B70);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color errorBackground = Color(0xFFFFCCCC);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor:  Color(0xFFF4F2F2),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: accentGold,
        error: errorRed,
      ),
      textTheme: GoogleFonts.latoTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
