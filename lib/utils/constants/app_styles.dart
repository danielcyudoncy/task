// utils/constants/app_styles.dart
import 'package:flutter/material.dart';

class AppStyles {
  static const gradientBackground = LinearGradient(
    colors:  [Color(0xFF08169D), Color(0xFF08169D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFF6773EC), Color(0xFF3A49D9)],
  );

  // Note: These styles should be used with theme-aware colors
  // Use Theme.of(context).textTheme or colorScheme instead of these hardcoded styles
  static const cardTitleStyle = TextStyle(fontSize: 18);
  static const cardValueStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const sectionTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  // Deprecated: Use theme-aware colors instead
  @Deprecated('Use theme-aware colors instead')
  static const tabSelectedStyle = TextStyle(color: Colors.white);
  @Deprecated('Use theme-aware colors instead')
  static const tabUnselectedStyle = TextStyle(color: Colors.black);
}
