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
    // Add a small delay to ensure proper initialization
    Future.delayed(const Duration(milliseconds: 100), () {
      loadTheme();
    });
  }

  // Load theme preference from local storage
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getBool('isDarkMode') ?? false;
    isDarkMode.value = savedTheme;

    debugPrint("ThemeController: Loading theme - isDarkMode: $savedTheme");

    // Apply theme on startup
    Get.changeThemeMode(savedTheme ? ThemeMode.dark : ThemeMode.light);
    debugPrint("ThemeController: Theme applied - ${savedTheme ? 'Dark' : 'Light'}");
  }

  // Toggle theme and persist preference
  Future<void> toggleTheme(bool value) async {
    debugPrint("ThemeController: Toggling theme to ${value ? 'Dark' : 'Light'}");
    
    isDarkMode.value = value;

    // Apply the actual theme
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    debugPrint("ThemeController: Theme changed to ${value ? 'Dark' : 'Light'}");

    // Persist the preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    debugPrint("ThemeController: Theme preference saved");
  }

  // Force refresh theme (useful for debugging)
  void forceRefreshTheme() {
    debugPrint("ThemeController: Force refreshing theme");
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    debugPrint("ThemeController: Theme force refreshed to ${isDarkMode.value ? 'Dark' : 'Light'}");
  }

  // Reset theme to default (light mode)
  Future<void> resetToDefaultTheme() async {
    debugPrint("ThemeController: Resetting to default light theme");
    isDarkMode.value = false;
    Get.changeThemeMode(ThemeMode.light);
    
    // Clear saved preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isDarkMode');
    debugPrint("ThemeController: Theme reset to light mode");
  }
}
