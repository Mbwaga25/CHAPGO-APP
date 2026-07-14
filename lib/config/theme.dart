import 'package:flutter/material.dart';

// ============================================================
// THEME MODE
// Both palettes below resolve their colors at runtime based on
// [ThemeState.isDark], so a single toggle recolors the whole app.
// Call ThemeState.setDark(bool) then rebuild the widget tree.
// ============================================================
class ThemeState {
  static bool isDark = true;
  static void setDark(bool v) => isDark = v;
  static Color _c(int dark, int light) => Color(isDark ? dark : light);
}

/// Driver dark/light palette (mirrors the Chapgo HTML prototype in dark mode,
/// with a matching light variant).
class DriverDark {
  static Color get dark        => ThemeState._c(0xFF061220, 0xFFEFF3F8); // app background
  static Color get navy        => ThemeState._c(0xFF0B1D2E, 0xFFFFFFFF); // nav/surfaces
  static Color get gold        => const Color(0xFFD4A843);
  static Color get green       => const Color(0xFF1B7A4A);
  static Color get greenLight  => ThemeState._c(0xFF24A060, 0xFF178A4E);
  static Color get red         => const Color(0xFFC0392B);
  static Color get white       => ThemeState._c(0xFFF8F6F1, 0xFF0B1D2E); // PRIMARY TEXT
  static Color get grey        => ThemeState._c(0xFF8899AA, 0xFF5B6B7B); // secondary text
  static Color get greyLight   => ThemeState._c(0xFFB0BFCF, 0xFF8595A5);
  static Color get card        => ThemeState._c(0x0AFFFFFF, 0x07000000);
  static Color get cardBorder  => ThemeState._c(0x14FFFFFF, 0x16000000);
  static Color get cardSurface => ThemeState._c(0xFF0E2233, 0xFFFFFFFF);

  static Color tierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum': return const Color(0xFF7FD4E0);
      case 'gold':     return gold;
      case 'silver':   return greyLight;
      case 'bronze':   return const Color(0xFFCD7F32);
      default:         return grey;
    }
  }

  static BoxDecoration cardDeco({Color? borderColor, Color? fill}) => BoxDecoration(
        color: fill ?? card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? cardBorder),
      );
}

class AppTheme {
  // ----- Brand Palette (dynamic) -----
  // `navy` is the PRIMARY FOREGROUND (text/icons): light on dark, dark on light.
  static Color get navy      => ThemeState._c(0xFFE8EEF5, 0xFF0F172A);
  static Color get navyLight => ThemeState._c(0xFF13283B, 0xFFE8EEF2);
  static Color get navyMid   => ThemeState._c(0xFF0E2233, 0xFFFFFFFF);
  static Color get navyDark  => ThemeState._c(0xFF061220, 0xFFF8FAFC);

  static Color get gold      => const Color(0xFFF59E0B);
  static Color get goldLight => const Color(0xFFFBBF24);
  static Color get goldDark  => const Color(0xFFD97706);

  static Color get accent      => const Color(0xFF3B82F6);
  static Color get accentLight => const Color(0xFF60A5FA);

  static Color get green      => const Color(0xFF10B981);
  static Color get greenLight => const Color(0xFF34D399);
  static Color get red        => const Color(0xFFEF4444);
  static Color get redLight   => const Color(0xFFFCA5A5);
  static Color get orange     => const Color(0xFFF97316);
  static Color get teal       => const Color(0xFF14B8A6);
  static Color get purple     => const Color(0xFF8B5CF6);

  // ----- Neutral / Surface (dynamic) -----
  static Color get bg             => ThemeState._c(0xFF061220, 0xFFF8FAFC);
  static Color get surface        => ThemeState._c(0xFF0E2233, 0xFFFFFFFF);
  static Color get surfaceVariant => ThemeState._c(0xFF13283B, 0xFFF1F5F9);
  static Color get border         => ThemeState._c(0x1AFFFFFF, 0xFFE2E8F0);
  static Color get gray           => ThemeState._c(0xFF9AAABB, 0xFF64748B);
  static Color get grayLight      => ThemeState._c(0xFF74879B, 0xFF94A3B8);
  static Color get white          => const Color(0xFFF8FAFC);

  static Color get cream => bg;
  static Color get soft  => surfaceVariant;

  // ----- Text Styles (dynamic) -----
  static TextStyle get headingLarge =>
      TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: navy, letterSpacing: -0.5);
  static TextStyle get headingMedium =>
      TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: navy);
  static TextStyle get headingSmall =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: navy);
  static TextStyle get labelStyle =>
      TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: gray, letterSpacing: 0.5);
  static TextStyle get valueStyle =>
      TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: navy);

  // ----- Decorations -----
  static BoxDecoration cardDecoration({Color? color, double radius = 16, bool withShadow = true}) =>
      BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: withShadow
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      );

  static BoxDecoration gradientDecoration({List<Color>? colors, double radius = 20}) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ?? [surfaceVariant, surface],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      );

  // ----- Theme Data (rebuilt per mode) -----
  static ThemeData get lightTheme => themeData;
  static ThemeData get darkTheme => themeData;

  static ThemeData get themeData {
    final brightness = ThemeState.isDark ? Brightness.dark : Brightness.light;
    final baseScheme = ThemeState.isDark ? const ColorScheme.dark() : const ColorScheme.light();
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      colorScheme: baseScheme.copyWith(
        primary: gold,
        secondary: green,
        error: red,
        surface: surface,
        onSurface: navy,
        surfaceContainerHighest: surfaceVariant,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        iconTheme: IconThemeData(color: navy),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: gold, width: 2)),
        labelStyle: TextStyle(color: gray, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: grayLight),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navyMid,
        selectedItemColor: gold,
        unselectedItemColor: gray,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: surface),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
      popupMenuTheme: PopupMenuThemeData(color: surface),
      textSelectionTheme: TextSelectionThemeData(cursorColor: gold, selectionHandleColor: gold),
      listTileTheme: ListTileThemeData(iconColor: navy, textColor: navy),
      iconTheme: IconThemeData(color: navy),
      expansionTileTheme: ExpansionTileThemeData(
        textColor: navy, collapsedTextColor: navy, iconColor: gold, collapsedIconColor: gray,
      ),
    );
  }
}
