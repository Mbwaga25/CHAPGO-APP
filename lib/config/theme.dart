import 'package:flutter/material.dart';

class AppTheme {
  // ─── Brand Palette ─────────────────────────────────────
  static const Color navy     = Color(0xFF0F172A); // slate-900
  static const Color navyLight= Color(0xFF1E293B); // slate-800
  static const Color navyMid  = Color(0xFF334155); // slate-700
  static const Color navyDark = Color(0xFF0A0F1C);

  static const Color gold     = Color(0xFFF59E0B); // amber-500
  static const Color goldLight= Color(0xFFFBBF24); // amber-400
  static const Color goldDark = Color(0xFFD97706); // amber-600

  static const Color accent   = Color(0xFF3B82F6); // blue-500
  static const Color accentLight = Color(0xFF60A5FA); // blue-400

  static const Color green    = Color(0xFF10B981); // emerald-500
  static const Color greenLight = Color(0xFF34D399); // emerald-400
  static const Color red      = Color(0xFFEF4444); // red-500
  static const Color redLight = Color(0xFFFCA5A5); // red-300
  static const Color orange   = Color(0xFFF97316); // orange-500
  static const Color teal     = Color(0xFF14B8A6); // teal-500
  static const Color purple   = Color(0xFF8B5CF6); // violet-500

  // ─── Neutral / Surface ──────────────────────────────────
  static const Color bg       = Color(0xFFF8FAFC); // slate-50
  static const Color surface  = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // slate-100
  static const Color border   = Color(0xFFE2E8F0); // slate-200
  static const Color gray     = Color(0xFF64748B); // slate-500
  static const Color grayLight= Color(0xFF94A3B8); // slate-400
  static const Color white    = Color(0xFFFFFFFF);

  // ─── Semantic aliases (keep old names for compatibility) ─
  static const Color cream    = Color(0xFFF8FAFC);
  static const Color soft     = Color(0xFFF1F5F9);

  // ─── Text Styles ────────────────────────────────────────
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: navy, letterSpacing: -0.5,
  );
  static const TextStyle headingMedium = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700, color: navy,
  );
  static const TextStyle headingSmall = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, color: navy,
  );
  static const TextStyle labelStyle = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: gray, letterSpacing: 0.5,
  );
  static const TextStyle valueStyle = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w800, color: navy,
  );

  // ─── Card Decoration ────────────────────────────────────
  static BoxDecoration cardDecoration({
    Color color = surface,
    double radius = 16,
    bool withShadow = true,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: navy.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      );

  // ─── Gradient Decoration ────────────────────────────────
  static BoxDecoration gradientDecoration({
    List<Color>? colors,
    double radius = 20,
  }) =>
      BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ?? [navy, navyMid],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  // ─── Theme Data ─────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.light(
        primary: navy,
        secondary: gold,
        error: red,
        surface: surface,
        surfaceContainerHighest: surfaceVariant,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: navy,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: navy, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
        labelStyle: const TextStyle(color: gray, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: grayLight),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: navy,
        unselectedItemColor: grayLight,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),
    );
  }
}
