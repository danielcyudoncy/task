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

  static const cardTitleStyle = TextStyle(fontSize: 18, color: Colors.white);
  static const cardValueStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const sectionTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.indigo,
  );

  static const tabSelectedStyle = TextStyle(color: Colors.white);
  static const tabUnselectedStyle = TextStyle(color: Colors.black);
}
