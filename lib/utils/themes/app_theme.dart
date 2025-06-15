// utils/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:task/utils/constants/app_colors.dart';
import 'package:task/utils/themes/app_text_theme.dart';

class AppTheme {
  // Main color palette
  static const Color _lightPrimary = Color(0xFF05168E);
  static const Color _lightOnPrimary = Colors.white;
  static const Color _lightSecondary = Color(0xFF2F80ED);
  static const Color _lightOnSecondary = Colors.white;
  static const Color _lightSurface = AppColors.white;
  static const Color _lightOnSurface = Colors.black;
  static const Color _lightBackground = AppColors.white;
  static const Color _lightOnBackground = Colors.black;

  static const Color _darkPrimary = Color(0xFF22223B); // deep indigo/blue
  static const Color _darkOnPrimary = Colors.white;
  static const Color _darkSecondary = Color(0xFF2F80ED);
  static const Color _darkOnSecondary = Colors.white;
  static const Color _darkSurface = Color(0xFF181826);
  static const Color _darkOnSurface = Colors.white;
  static const Color _darkBackground = Colors.black;
  static const Color _darkOnBackground = Colors.white;

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _lightPrimary,
    scaffoldBackgroundColor: _lightBackground,
    colorScheme:  const ColorScheme(
      brightness: Brightness.light,
      primary: _lightPrimary,
      onPrimary: _lightOnPrimary,
      secondary: _lightSecondary,
      onSecondary: _lightOnSecondary,
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      background: _lightBackground,
      onBackground: _lightOnBackground,
      error: Colors.red,
      onError: Colors.white,
      tertiary: Color(0xFF0E9B6C),
      onTertiary: Colors.white,
      outline: Color(0xFFBDBDBD),
      shadow: Colors.black54,
      inverseSurface: Colors.black,
      onInverseSurface: Colors.white,
      inversePrimary: _lightSecondary,
      surfaceContainerHighest: Color(0xFFF5F6FA),
      onSurfaceVariant: _lightOnSurface,
      scrim: Colors.black38,
    ),
    textTheme: AppTextTheme.lightTextTheme,
    appBarTheme:  const AppBarTheme(
      backgroundColor: _lightPrimary,
      foregroundColor: _lightOnPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme:  const CardTheme(
      color: _lightSurface,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    ),
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _darkPrimary,
    scaffoldBackgroundColor: _darkBackground,
    colorScheme:   const ColorScheme(
      brightness: Brightness.dark,
      primary: _darkPrimary,
      onPrimary: _darkOnPrimary,
      secondary: _darkSecondary,
      onSecondary: _darkOnSecondary,
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      background: _darkBackground,
      onBackground: _darkOnBackground,
      error: Colors.redAccent,
      onError: Colors.black,
      tertiary: Color(0xFF52CBA7),
      onTertiary: Colors.black,
      outline: Color(0xFF757575),
      shadow: Colors.black,
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black,
      inversePrimary: _darkSecondary,
      surfaceContainerHighest: Color(0xFF181826),
      onSurfaceVariant: _darkOnSurface,
      scrim: Colors.black26,
    ),
    textTheme: AppTextTheme.darkTextTheme,
    appBarTheme:  const AppBarTheme(
      backgroundColor: _darkPrimary,
      foregroundColor: _darkOnPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme:  const CardTheme(
      color: _darkSurface,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    ),
    useMaterial3: true,
  );

  /// Returns the appropriate gradient based on theme brightness.
  static LinearGradient getGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? [_darkPrimary, _darkSurface]
          : [_lightPrimary, _lightSecondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
