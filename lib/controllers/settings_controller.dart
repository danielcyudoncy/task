// controllers/settings_controller.dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  // App Preferences
  var isDarkMode = false.obs;
  var isSoundEnabled = true.obs;
  var isVibrationEnabled = true.obs;
  var selectedLanguage = "English (Default)".obs;
  var isSyncEnabled = true.obs;

  // Privacy/Other Preferences
  var isAssignmentAlertEnabled = false.obs;
  var isLocationEnabled = false.obs;
  var isTargetedAdsEnabled = false.obs;

  // For settings that require navigation, just provide a method for UI to call
  void viewPrivacyPolicy() {
    // Implement navigation to privacy policy screen in your UI
  }

  void setupTwoFactorAuthentication() {
    // Implement navigation to 2FA setup screen in your UI
  }

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? false;
    isSoundEnabled.value = prefs.getBool('isSoundEnabled') ?? true;
    isVibrationEnabled.value = prefs.getBool('isVibrationEnabled') ?? true;
    selectedLanguage.value =
        prefs.getString('selectedLanguage') ?? "English (Default)";
    isSyncEnabled.value = prefs.getBool('isSyncEnabled') ?? true;
    isAssignmentAlertEnabled.value =
        prefs.getBool('isAssignmentAlertEnabled') ?? false;
    isLocationEnabled.value = prefs.getBool('isLocationEnabled') ?? false;
    isTargetedAdsEnabled.value = prefs.getBool('isTargetedAdsEnabled') ?? false;
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode.value);
    await prefs.setBool('isSoundEnabled', isSoundEnabled.value);
    await prefs.setBool('isVibrationEnabled', isVibrationEnabled.value);
    await prefs.setString('selectedLanguage', selectedLanguage.value);
    await prefs.setBool('isSyncEnabled', isSyncEnabled.value);
    await prefs.setBool(
        'isAssignmentAlertEnabled', isAssignmentAlertEnabled.value);
    await prefs.setBool('isLocationEnabled', isLocationEnabled.value);
    await prefs.setBool('isTargetedAdsEnabled', isTargetedAdsEnabled.value);
  }

  // Call this when the user presses the Save button
  Future<void> onSave() async {
    await saveSettings();
    // Optionally show a snackbar or dialog in the UI: "Settings saved"
  }

  // Optionally, add utility methods for toggling each setting
  void toggleDarkMode(bool value) => isDarkMode.value = value;
  void toggleSound(bool value) => isSoundEnabled.value = value;
  void toggleVibration(bool value) => isVibrationEnabled.value = value;
  void toggleSync(bool value) => isSyncEnabled.value = value;
  void toggleAssignmentAlert(bool value) =>
      isAssignmentAlertEnabled.value = value;
  void toggleLocation(bool value) => isLocationEnabled.value = value;
  void toggleTargetedAds(bool value) => isTargetedAdsEnabled.value = value;
  void setLanguage(String lang) => selectedLanguage.value = lang;
}
