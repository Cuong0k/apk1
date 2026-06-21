import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary      = Color(0xFF0D47A1);
  static const Color accent       = Color(0xFF00BCD4);
  static const Color connected    = Color(0xFF00C853);
  static const Color disconnected = Color(0xFFEF5350);

  // Dark palette
  static const Color darkBg      = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF131929);
  static const Color darkCard    = Color(0xFF1A2236);

  // Light palette
  static const Color lightBg     = Color(0xFFEFF3FB);
  static const Color lightCard   = Colors.white;

  // Legacy aliases
  static const Color bg      = darkBg;
  static const Color surface = darkSurface;
  static const Color card    = darkCard;

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: darkSurface,
    ),
    scaffoldBackgroundColor: darkBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white70),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
    ),
    cardTheme: CardTheme(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkCard,
      selectedItemColor: accent,
      unselectedItemColor: Colors.white38,
      type: BottomNavigationBarType.fixed,
    ),
    dividerColor: Colors.white12,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    useMaterial3: true,
  );

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: Color(0xFFF5F8FF),
    ),
    scaffoldBackgroundColor: lightBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Color(0x14000000),
      iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
      titleTextStyle: TextStyle(color: Color(0xFF1A1A2E), fontSize: 18, fontWeight: FontWeight.w600),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 1,
      shadowColor: const Color(0x1A000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: accent,
      unselectedItemColor: Colors.black38,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerColor: Colors.black12,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    useMaterial3: true,
  );
}

// Context extension for theme-aware colors
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Text layers
  Color get c1 => isDark ? Colors.white           : const Color(0xFF1A1A2E); // primary text
  Color get c2 => isDark ? Colors.white60         : Colors.black54;          // secondary
  Color get c3 => isDark ? Colors.white38         : Colors.black38;          // hint
  Color get c4 => isDark ? Colors.white12         : Colors.black12;          // divider/border

  // Backgrounds
  Color get cardBg  => isDark ? AppTheme.darkCard : Colors.white;
  Color get navBg   => isDark ? AppTheme.darkCard : Colors.white;
  Color get inputBg => isDark ? AppTheme.darkCard : Colors.white;
  Color get iconColor => isDark ? Colors.white38  : Colors.black38;
}
