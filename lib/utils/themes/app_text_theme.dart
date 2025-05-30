// utils/themes/app_text_theme.dart
import 'package:flutter/material.dart';
import 'package:task/utils/constants/app_colors.dart';

class AppTextTheme {
  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    displayMedium: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    displaySmall: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    headlineLarge: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    headlineMedium: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    headlineSmall: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    titleLarge: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    titleMedium: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    titleSmall: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    bodyLarge: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    bodyMedium: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    bodySmall: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    labelLarge: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    labelMedium: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
    labelSmall: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
  );

  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(color: AppColors.white),
    displayMedium: TextStyle(color: AppColors.white),
    displaySmall: TextStyle(color: AppColors.white),
    headlineLarge: TextStyle(color: AppColors.white),
    headlineMedium: TextStyle(color: AppColors.white),
    headlineSmall: TextStyle(color: AppColors.white),
    titleLarge: TextStyle(color: AppColors.white),
    titleMedium: TextStyle(color: AppColors.white),
    titleSmall: TextStyle(color: AppColors.white),
    bodyLarge: TextStyle(color: AppColors.white),
    bodyMedium: TextStyle(color: AppColors.white),
    bodySmall: TextStyle(color: AppColors.white),
    labelLarge: TextStyle(color: AppColors.white),
    labelMedium: TextStyle(color: AppColors.white),
    labelSmall: TextStyle(color: AppColors.white),
  );
}
