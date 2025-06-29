// controllers/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  // Observable for dark mode
  var isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  // Load theme preference from local storage
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? false;

    // Apply theme on startup
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  // Toggle theme and persist preference
  Future<void> toggleTheme(bool value) async {
    isDarkMode.value = value;

    // Apply the actual theme
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);

    // Persist the preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }
}
