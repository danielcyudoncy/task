// utils/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Basic colors
  static const black = Colors.black;
  static const lightGrey = Colors.grey;
  static const white = Color(0xFFDBDBDB); // Keep existing off-white
  static const errorRed = Color(0xFFFF3B30);

  // Updated to match app theme colors
  static const primaryColor = Color(0xFF0040A8); // Channels TV primary blue
  static const secondaryColor = Color(0xFF0050D0); // Channels TV secondary blue
  static const tertiaryColor = Color(0xFF333333); // Keep existing
  static const saveColor = Color(0xFF0040A8); // Match primary blue

  // Theme-aligned accent colors
  static const successColor = Color(0xFF00A8A8); // Teal from theme
  static const warningColor = Color(0xFFC0C0C0); // Silver from theme
  static const accentColor = Color(0xFF002060); // Darker blue accent

  // Dark theme colors - updated to match theme
  static const Color darkBackground =
      Color(0xFF003080); // Theme dark surface variant
  static const Color darkCard = Color(0xFF0040A8); // Theme primary blue
  static const Color darkAppBar = Color(0xFF0040A8); // Match primary

  // Text colors - aligned with theme
  static const Color primaryText = Color(0xFF0040A8); // Theme primary blue
  static const Color secondaryText = Color(0xFF666666); // Keep existing

  // Surface colors matching theme
  static const Color lightSurface =
      Color(0xFFF0F0F0); // Theme light surface variant
  static const Color primaryContainer =
      Color(0xFFE8F0FF); // Theme primary container
}
