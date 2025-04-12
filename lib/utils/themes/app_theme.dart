import 'package:flutter/material.dart';
import 'package:task/utils/constants/app_colors.dart';
import 'package:task/utils/themes/app_text_theme.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color.fromARGB(255, 13, 28, 170),
      scaffoldBackgroundColor: AppColors.white,
      textTheme: AppTextTheme.lightTextTheme);

  static ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color.fromARGB(255, 4, 18, 150),
      scaffoldBackgroundColor: AppColors.black,
      textTheme: AppTextTheme.darkTextTheme);
}
