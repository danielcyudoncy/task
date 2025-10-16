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
  // --- Channels TV Theme Colors ---
  static const Color _primaryBlue =
      Color(0xFF0040A8); // Channels TV primary blue
  static const Color _secondaryBlue =
      Color(0xFF0050D0); // Lighter variation of primary
  static const Color _lightSurfaceVariant =
      Color(0xFFF0F0F0); // Light gray from logo
  static const Color _darkSurfaceVariant =
      Color(0xFF003080); // Darker variation of primary

  // --- Brand Accent Colors ---
  static const Color _success =
      Color(0xFF00A8A8); // Teal variation matching brand
  static const Color _warning = Color(0xFFC0C0C0); // Silver from logo
  static const Color _accent1 = Color(0xFF002060); // Darker blue accent

  static ThemeData lightTheme = _baseTheme(
    brightness: Brightness.light,
    primaryColor: _primaryBlue,
    secondaryColor: _secondaryBlue,
    background: Colors.white,
    onBackground: _primaryBlue,
    surface: Colors.white,
    onSurface: _primaryBlue,
    surfaceVariant: _lightSurfaceVariant,
    onSurfaceVariant: const Color(0xB30040A8), // 70% alpha of _primaryBlue
    primaryContainer: const Color(0xFFE8F0FF), // Light blue background
    onPrimaryContainer: _primaryBlue,
    dividerColor: const Color(0x4DC0C0C0), // 30% alpha of _warning
    hintColor: const Color(0x800040A8), // 50% alpha of _primaryBlue
    appBarBackgroundColor: _primaryBlue,
    inputFillColor: _lightSurfaceVariant,
    textColor: _primaryBlue,
    isDark: false,
  );

  static ThemeData darkTheme = _baseTheme(
    brightness: Brightness.dark,
    primaryColor: _primaryBlue,
    secondaryColor: _secondaryBlue,
    background: _darkSurfaceVariant,
    onBackground: Colors.white,
    surface: _primaryBlue,
    onSurface: Colors.white,
    surfaceVariant: _darkSurfaceVariant,
    onSurfaceVariant: _warning, // Silver color for contrast
    primaryContainer: _accent1,
    onPrimaryContainer: Colors.white,
    dividerColor: _warning.withAlpha(5), // Silver with opacity
    hintColor: _warning.withAlpha(7),
    appBarBackgroundColor: _primaryBlue,
    inputFillColor: _darkSurfaceVariant,
    textColor: Colors.white,
    isDark: true,
    // Custom dialog background for dark mode
    // Removed invalid parameter 'dialogBackgroundColor'
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
      onPrimary: const Color(0xFFDBDBDB),
      secondary: secondaryColor,
      onSecondary: isDark ? Colors.black : const Color(0xFFDBDBDB),
      error: Colors.red,
      onError: isDark ? Colors.black : const Color(0xFFDBDBDB),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      surfaceTint: primaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.ralewayTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
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
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF232323) : Colors.white,
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
          backgroundColor: const WidgetStatePropertyAll(Color(0xFF2F46A3)),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(Color(0xFF2F46A3)),
          side: const WidgetStatePropertyAll(
              BorderSide(color: Color(0xFF2F46A3))),
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
