// utils/themes/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryBlue = Color(0xFF2E3BB5);
  static const Color _secondaryBlue = Color(0xFF00B0FF);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _primaryBlue,
      onPrimary: Colors.white,
      secondary: _secondaryBlue,
      onSecondary: Colors.white,
      background: Colors.white,
      onBackground: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black,
      error: Colors.red,
      onError: Colors.white,
      primaryContainer: Color(0xFFDDE1F9),
      onPrimaryContainer: _primaryBlue,
      surfaceVariant: Color(0xFFF3F6FD),
    ),
    scaffoldBackgroundColor: Colors.white,
    dividerTheme: const DividerThemeData(
      color: Colors.black12,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: _primaryBlue,
      elevation: 0,
      iconTheme: IconThemeData(color: _primaryBlue),
      titleTextStyle: TextStyle(
        color: _primaryBlue,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF3F6FD), // Solid color, not opacity
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.black54),
    ),
    elevatedButtonTheme: const ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(_primaryBlue),
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        )),
        elevation: WidgetStatePropertyAll(0),
      ),
    ),
    outlinedButtonTheme: const OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(_primaryBlue),
        side: WidgetStatePropertyAll(BorderSide(color: _primaryBlue)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        )),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _primaryBlue,
      onPrimary: Colors.white,
      secondary: _secondaryBlue,
      onSecondary: Colors.black,
      background: Color(0xFF181B2A),
      onBackground: Colors.white,
      surface: Color(0xFF23243A),
      onSurface: Colors.white,
      error: Colors.red,
      onError: Colors.black,
      primaryContainer: Color(0xFF23243A),
      onPrimaryContainer: Colors.white,
      surfaceVariant: Color(0xFF23243A),
    ),
    scaffoldBackgroundColor: const Color(0xFF181B2A),
    dividerTheme: const DividerThemeData(
      color: Colors.white24,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF181B2A),
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF23243A), // Solid color, not opacity
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.white70),
    ),
    elevatedButtonTheme: const ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(_primaryBlue),
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        )),
        elevation: WidgetStatePropertyAll(0),
      ),
    ),
    outlinedButtonTheme: const OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        side: WidgetStatePropertyAll(BorderSide(color: _primaryBlue)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        )),
      ),
    ),
  );

  // Centralized gradient getter for screens that want the app's signature gradient
  static LinearGradient getGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              colorScheme.background,
              colorScheme.surfaceVariant,
              colorScheme.background,
            ]
          : [
              Colors.white,
              colorScheme.primary,
            ],
      stops: isDark ? const [0.0, 0.7, 1.0] : const [0.0, 1.0],
    );
  }
}
