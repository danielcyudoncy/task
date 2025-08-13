// utils/themes/app_text_theme.dart
import 'package:flutter/material.dart';
import 'package:task/utils/constants/app_colors.dart';

class AppTextTheme {
  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(color: Colors.black),
    displayMedium: TextStyle(color: Colors.black),
    displaySmall: TextStyle(color: Colors.black),
    headlineLarge: TextStyle(color: Colors.black),
    headlineMedium: TextStyle(color: Colors.black),
    headlineSmall: TextStyle(color: Colors.black),
    titleLarge: TextStyle(color: Colors.black),
    titleMedium: TextStyle(color: Colors.black),
    titleSmall: TextStyle(color: Colors.black),
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
    bodySmall: TextStyle(color: Colors.black),
    labelLarge: TextStyle(color: Colors.black),
    labelMedium: TextStyle(color: Colors.black),
    labelSmall: TextStyle(color: Colors.black),
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
