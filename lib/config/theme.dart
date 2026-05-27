import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF1A2332);
  static const Color navyLight = Color(0xFF2A3646);
  static const Color navyDark = Color(0xFF0D1520);
  static const Color gold = Color(0xFF8B6F1F);
  static const Color goldLight = Color(0xFFB8934A);
  static const Color green = Color(0xFF2D5A3D);
  static const Color red = Color(0xFF8B2E2E);
  static const Color cream = Color(0xFFF5F3EC);
  static const Color soft = Color(0xFFFAF4E0);
  static const Color gray = Color(0xFF555555);
  static const Color grayLight = Color(0xFFAAAAAA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF7F5EE);
  static const Color border = Color(0xFFE5E0D0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.light(
        primary: navy,
        secondary: gold,
        error: red,
        surface: white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: navy, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
        labelStyle: const TextStyle(color: navy, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: border),
    );
  }
}
