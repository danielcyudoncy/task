// utils/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:task/utils/constants/app_colors.dart';
import 'package:task/utils/themes/app_text_theme.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF05168E),
    scaffoldBackgroundColor: AppColors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF05168E),
      onPrimary: Colors.white,
      surface: AppColors.white,
      onSurface: Colors.black,
      secondary: Color(0xFF2F80ED),
    ),
    textTheme: AppTextTheme.lightTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF05168E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
      secondary: Colors.grey,
    ),
    textTheme: AppTextTheme.darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    useMaterial3: true,
  );

  /// Returns the appropriate gradient based on theme brightness.
  static LinearGradient getGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? [Colors.black, Colors.grey.shade900]
          : [const Color(0xFF05168E), const Color(0xFF2F80ED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
