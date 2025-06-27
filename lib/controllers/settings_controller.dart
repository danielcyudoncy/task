// controllers/settings_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class SettingsController extends GetxController {
  final AudioPlayer audioPlayer;

  // App Preferences
  final isDarkMode = false.obs;
  final isSoundEnabled = true.obs;
  final isVibrationEnabled = true.obs;
  final selectedLanguage = "English (Default)".obs;
  final isSyncEnabled = true.obs;

  // Privacy/Other Preferences
  final isAssignmentAlertEnabled = false.obs;
  final isLocationEnabled = false.obs;
  final isTargetedAdsEnabled = false.obs;

  SettingsController(this.audioPlayer);

  bool get shouldVibrate => isVibrationEnabled.value;
  bool get shouldPlaySound => isSoundEnabled.value;

  /// Plays any app sound by filename (must be under `assets/sounds/`)
  Future<void> _playSound(String fileName) async {
    if (!shouldPlaySound) return;
    try {
      await audioPlayer.play(AssetSource('sounds/$fileName'), volume: 1.0);
    } catch (e) {
      debugPrint('🔊 Sound error: $e');
    }
  }

  /// Triggers sound and vibration feedback together
  Future<void> triggerFeedback() async {
    if (shouldVibrate && await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 50);
    }
    await _playSound('click.wav');
  }

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  @override
  void onClose() {
    audioPlayer.dispose();
    super.onClose();
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
    await Future.wait([
      prefs.setBool('isDarkMode', isDarkMode.value),
      prefs.setBool('isSoundEnabled', isSoundEnabled.value),
      prefs.setBool('isVibrationEnabled', isVibrationEnabled.value),
      prefs.setString('selectedLanguage', selectedLanguage.value),
      prefs.setBool('isSyncEnabled', isSyncEnabled.value),
      prefs.setBool('isAssignmentAlertEnabled', isAssignmentAlertEnabled.value),
      prefs.setBool('isLocationEnabled', isLocationEnabled.value),
      prefs.setBool('isTargetedAdsEnabled', isTargetedAdsEnabled.value),
    ]);
    await _playSound('success.wav');
  }

  void toggleDarkMode(bool value) {
    isDarkMode.value = value;
    triggerFeedback();
    saveSettings();
  }

  void toggleSound(bool value) {
    isSoundEnabled.value = value;
    if (value) _playSound('click.wav');
    saveSettings();
  }

  void toggleVibration(bool value) {
    isVibrationEnabled.value = value;
    if (value) Vibration.vibrate(duration: 50);
    saveSettings();
  }

  void toggleSync(bool value) {
    isSyncEnabled.value = value;
    triggerFeedback();
    saveSettings();
  }

  void toggleAssignmentAlert(bool value) {
    isAssignmentAlertEnabled.value = value;
    triggerFeedback();
    saveSettings();
  }

  void toggleLocation(bool value) {
    isLocationEnabled.value = value;
    triggerFeedback();
    saveSettings();
  }

  void toggleTargetedAds(bool value) {
    isTargetedAdsEnabled.value = value;
    triggerFeedback();
    saveSettings();
  }

  void setLanguage(String lang) {
    selectedLanguage.value = lang;
    triggerFeedback();
    saveSettings();
  }
}
