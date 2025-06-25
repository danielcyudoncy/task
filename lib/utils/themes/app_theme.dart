// utils/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _primaryBlue = Color(0xFF08169D);
  static const Color _secondaryBlue = Color(0xFF00B0FF);
  static const Color _lightSurfaceVariant = Color(0xFFF3F6FD);
  static const Color _darkSurfaceVariant = Color(0xFF23243A);

  static ThemeData lightTheme = _baseTheme(
    brightness: Brightness.light,
    primaryColor: _primaryBlue,
    secondaryColor: _secondaryBlue,
    background: Colors.white,
    onBackground: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black,
    surfaceVariant: _lightSurfaceVariant,
    onSurfaceVariant: Colors.black54,
    primaryContainer: const Color(0xFFDDE1F9),
    onPrimaryContainer: _primaryBlue,
    dividerColor: Colors.black12,
    hintColor: Colors.black54,
    appBarBackgroundColor: const Color(0xFF181B2A),
    inputFillColor: _lightSurfaceVariant,
    textColor: Colors.black,
    isDark: false,
  );

  static ThemeData darkTheme = _baseTheme(
    brightness: Brightness.dark,
    primaryColor: _primaryBlue,
    secondaryColor: _secondaryBlue,
    background: const Color(0xFF181B2A),
    onBackground: Colors.white,
    surface: const Color(0xFF23243A),
    onSurface: Colors.white,
    surfaceVariant: _darkSurfaceVariant,
    onSurfaceVariant: Colors.white70,
    primaryContainer: const Color(0xFF23243A),
    onPrimaryContainer: Colors.white,
    dividerColor: Colors.white24,
    hintColor: Colors.white70,
    appBarBackgroundColor: Colors.transparent,
    inputFillColor: _darkSurfaceVariant,
    textColor: Colors.white,
    isDark: true,
  );

  static ThemeData _baseTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color secondaryColor,
    required Color background,
    required Color onBackground,
    required Color surface,
    required Color onSurface,
    required Color surfaceVariant,
    required Color onSurfaceVariant,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Color dividerColor,
    required Color hintColor,
    required Color appBarBackgroundColor,
    required Color inputFillColor,
    required Color textColor,
    required bool isDark,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: isDark ? Colors.black : Colors.white,
      background: background,
      onBackground: onBackground,
      surface: surface,
      onSurface: onSurface,
      error: Colors.red,
      onError: isDark ? Colors.black : Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.ralewayTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.raleway(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20.sp,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: hintColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(primaryColor),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              WidgetStatePropertyAll(isDark ? Colors.white : primaryColor),
          side: WidgetStatePropertyAll(BorderSide(color: primaryColor)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}
