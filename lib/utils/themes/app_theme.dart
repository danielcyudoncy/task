// utils/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _primaryBlue = Color(0xFF08169D);
  static const Color _secondaryBlue = Color(0xFF00B0FF);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
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
    textTheme: GoogleFonts.ralewayTextTheme(),
    dividerTheme: const DividerThemeData(
      color: Colors.black12,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF181B2A), // allow override
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white), // white hamburger
      titleTextStyle: GoogleFonts.raleway(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20.sp,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF3F6FD),
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
    scaffoldBackgroundColor: const Color(0xFF181B2A),
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
    textTheme: GoogleFonts.ralewayTextTheme(ThemeData.dark().textTheme),
    dividerTheme: const DividerThemeData(
      color: Colors.white24,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent, // allow override
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.raleway(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20.sp,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF23243A),
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
}
