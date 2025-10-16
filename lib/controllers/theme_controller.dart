// controllers/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum for theme modes
enum AppThemeMode {
  light('Light'),
  dark('Dark'),
  system('System');

  const AppThemeMode(this.displayName);
  final String displayName;
}

class ThemeController extends GetxController {
  // Observable for current theme mode
  var currentThemeMode = AppThemeMode.light.obs;

  // Observable for actual dark mode state (computed based on theme mode and system)
  var isDarkMode = false.obs;

  // Observable for system dark mode state
  var isSystemDark = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Listen to system theme changes
    _updateSystemTheme();

    // Add a small delay to ensure proper initialization
    Future.delayed(const Duration(milliseconds: 100), () {
      loadTheme();
    });
  }

  // Update system theme state
  void _updateSystemTheme() {
    final window = WidgetsBinding.instance.platformDispatcher;
    isSystemDark.value = window.platformBrightness == Brightness.dark;

    // Listen for system theme changes
    window.onPlatformBrightnessChanged = () {
      isSystemDark.value = window.platformBrightness == Brightness.dark;
      _applyTheme(); // Re-apply theme when system changes
    };
  }

  // Load theme preference from local storage
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // Try to load the new theme mode preference
    final savedThemeName = prefs.getString('appThemeMode');
    if (savedThemeName != null) {
      // Load new format
      try {
        currentThemeMode.value = AppThemeMode.values.firstWhere(
          (mode) => mode.name == savedThemeName,
        );
      } catch (e) {
        currentThemeMode.value = AppThemeMode.light;
      }
    } else {
      // Migrate from old format
      final oldSavedTheme = prefs.getBool('isDarkMode');
      if (oldSavedTheme != null) {
        currentThemeMode.value =
            oldSavedTheme ? AppThemeMode.dark : AppThemeMode.light;
        // Save in new format and remove old
        await _saveThemePreference();
        await prefs.remove('isDarkMode');
      } else {
        currentThemeMode.value = AppThemeMode.light;
      }
    }

    debugPrint(
        "ThemeController: Loading theme - mode: ${currentThemeMode.value.displayName}");
    _applyTheme();
  }

  // Apply theme based on current mode
  void _applyTheme() {
    ThemeMode themeMode;
    bool shouldBeDark;

    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        themeMode = ThemeMode.light;
        shouldBeDark = false;
        break;
      case AppThemeMode.dark:
        themeMode = ThemeMode.dark;
        shouldBeDark = true;
        break;
      case AppThemeMode.system:
        themeMode = ThemeMode.system;
        shouldBeDark = isSystemDark.value;
        break;
    }

    isDarkMode.value = shouldBeDark;
    Get.changeThemeMode(themeMode);

    debugPrint(
        "ThemeController: Applied theme - mode: ${currentThemeMode.value.displayName}, dark: $shouldBeDark");
  }

  // Save theme preference
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appThemeMode', currentThemeMode.value.name);
    debugPrint(
        "ThemeController: Theme preference saved - ${currentThemeMode.value.displayName}");
  }

  // Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    debugPrint("ThemeController: Setting theme mode to ${mode.displayName}");

    currentThemeMode.value = mode;
    _applyTheme();
    await _saveThemePreference();
  }

  // Legacy method for backward compatibility
  Future<void> toggleTheme(bool value) async {
    final mode = value ? AppThemeMode.dark : AppThemeMode.light;
    await setThemeMode(mode);
  }

  // Check if current theme is dark (considering system theme)
  bool get isCurrentlyDark {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        return isSystemDark.value;
    }
  }

  // Force refresh theme (useful for debugging)
  void forceRefreshTheme() {
    debugPrint("ThemeController: Force refreshing theme");
    _updateSystemTheme();
    _applyTheme();
  }

  // Reset theme to default (light mode)
  Future<void> resetToDefaultTheme() async {
    debugPrint("ThemeController: Resetting to default light theme");
    await setThemeMode(AppThemeMode.light);
  }
}
