// utils/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Custom Theme Extension for extra colors ---
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.warning,
    required this.accent1,
  });

  final Color? success;
  final Color? warning;
  final Color? accent1;

  @override
  AppColors copyWith({Color? success, Color? warning, Color? accent1}) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      accent1: accent1 ?? this.accent1,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      success: Color.lerp(success, other.success, t),
      warning: Color.lerp(warning, other.warning, t),
      accent1: Color.lerp(accent1, other.accent1, t),
    );
  }
}

class AppTheme {
  // --- Standard Theme Colors ---
  static const Color _primaryBlue = Color(0xFF08169D);
  static const Color _secondaryBlue = Color(0xFF00B0FF);
  static const Color _lightSurfaceVariant = Color(0xFFF3F6FD);
  static const Color _darkSurfaceVariant = Color(0xFF23243A);

  // --- NEW: Define the custom dashboard colors here ---
  static const Color _success = Color(0xFF2E7D32); // A nice green
  static const Color _warning = Color(0xFFEF6C00); // A nice orange
  static const Color _accent1 = Color(0xFF6A1B9A); // A nice purple

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
      error: Colors.red,
      onError: isDark ? Colors.black : Colors.white,
      surface: surface,
      onSurface: onSurface,
      background: background,
      onBackground: onBackground,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      surfaceTint: primaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      textTheme: GoogleFonts.ralewayTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(
        bodyColor: colorScheme.onBackground,
        displayColor: colorScheme.onBackground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        titleTextStyle: GoogleFonts.raleway(
          color: colorScheme.onPrimary,
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
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(colorScheme.primary),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(colorScheme.primary),
          side: WidgetStatePropertyAll(BorderSide(color: colorScheme.primary)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),

      // Register your custom AppColors extension with the theme.
      extensions: const <ThemeExtension<dynamic>>[
        AppColors(
          success: _success,
          warning: _warning,
          accent1: _accent1,
        ),
      ],
    );
  }
}
