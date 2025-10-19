// controllers/settings_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/localization/app_localizations.dart';
import '../utils/constants/app_constants.dart';

class SettingsController extends GetxController {
  final AudioPlayer audioPlayer;

  // App Preferences
  final isSoundEnabled = true.obs;
  final isVibrationEnabled = true.obs;
  final selectedLanguage = "English (Default)".obs;
  final isSyncEnabled = true.obs;

  // Privacy/Other Preferences
  final isAssignmentAlertEnabled = false.obs;
  final isLocationEnabled = false.obs;
  final isTargetedAdsEnabled = false.obs;
  final isBiometricEnabled = false.obs;

  SettingsController(this.audioPlayer);

  bool get shouldVibrate => isVibrationEnabled.value;
  bool get shouldPlaySound => isSoundEnabled.value;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _playSound(String fileName) async {
    if (!shouldPlaySound) return;
    try {
      await audioPlayer.play(AssetSource('sounds/$fileName'), volume: 1.0);
    } catch (e) {
      debugPrint('🔊 Sound error: $e');
    }
  }

  Future<void> triggerFeedback() async {
    if (shouldVibrate && await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 50);
    }
    await _playSound('click.wav');
  }

  @override
  void onInit() {
    super.onInit();
    loadSettings(); // this also triggers Firestore sync if needed
  }

  @override
  void onClose() {
    audioPlayer.dispose();
    super.onClose();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load from local storage first
    isSoundEnabled.value = prefs.getBool('isSoundEnabled') ?? true;
    isVibrationEnabled.value = prefs.getBool('isVibrationEnabled') ?? true;
    selectedLanguage.value =
        prefs.getString('selectedLanguage') ?? "English (Default)";
    isSyncEnabled.value = prefs.getBool('isSyncEnabled') ?? true;
    isAssignmentAlertEnabled.value =
        prefs.getBool('isAssignmentAlertEnabled') ?? false;
    isLocationEnabled.value = prefs.getBool('isLocationEnabled') ?? false;
    isTargetedAdsEnabled.value = prefs.getBool('isTargetedAdsEnabled') ?? false;
    isBiometricEnabled.value = prefs.getBool(AppConstants.biometricEnabledKey) ?? false;

    // If sync is enabled and user is logged in, fetch from Firestore
    if (isSyncEnabled.value && _auth.currentUser != null) {
      await _loadSettingsFromFirestore();
    }
  }

  Future<void> _loadSettingsFromFirestore() async {
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('user_settings').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        isSoundEnabled.value = data['isSoundEnabled'] ?? isSoundEnabled.value;
        isVibrationEnabled.value =
            data['isVibrationEnabled'] ?? isVibrationEnabled.value;
        selectedLanguage.value =
            data['selectedLanguage'] ?? selectedLanguage.value;
        isAssignmentAlertEnabled.value =
            data['isAssignmentAlertEnabled'] ?? isAssignmentAlertEnabled.value;
        isLocationEnabled.value =
            data['isLocationEnabled'] ?? isLocationEnabled.value;
        isTargetedAdsEnabled.value =
            data['isTargetedAdsEnabled'] ?? isTargetedAdsEnabled.value;
        isBiometricEnabled.value =
            data[AppConstants.biometricEnabledKey] ?? isBiometricEnabled.value;

        // Save pulled settings to local preferences too
        await saveSettings(localOnly: true);
      }
    } catch (e) {
      debugPrint('⚠️ Firestore sync error: $e');
    }
  }

  Future<void> saveSettings({bool localOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      prefs.setBool('isSoundEnabled', isSoundEnabled.value),
      prefs.setBool('isVibrationEnabled', isVibrationEnabled.value),
      prefs.setString('selectedLanguage', selectedLanguage.value),
      prefs.setBool('isSyncEnabled', isSyncEnabled.value),
      prefs.setBool('isAssignmentAlertEnabled', isAssignmentAlertEnabled.value),
      prefs.setBool('isLocationEnabled', isLocationEnabled.value),
      prefs.setBool('isTargetedAdsEnabled', isTargetedAdsEnabled.value),
      prefs.setBool(AppConstants.biometricEnabledKey, isBiometricEnabled.value),
    ]);

    if (!localOnly && isSyncEnabled.value && _auth.currentUser != null) {
      try {
        final uid = _auth.currentUser!.uid;
        await _firestore.collection('user_settings').doc(uid).set({
          'isSoundEnabled': isSoundEnabled.value,
          'isVibrationEnabled': isVibrationEnabled.value,
          'selectedLanguage': selectedLanguage.value,
          'isAssignmentAlertEnabled': isAssignmentAlertEnabled.value,
          'isLocationEnabled': isLocationEnabled.value,
          'isTargetedAdsEnabled': isTargetedAdsEnabled.value,
          AppConstants.biometricEnabledKey: isBiometricEnabled.value,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('⚠️ Firestore save error: $e');
      }
    }

    await _playSound('success.wav');
  }

  // Toggle methods
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

  void toggleBiometric(bool value) {
    isBiometricEnabled.value = value;
    triggerFeedback();
    saveSettings();
  }

  void setLanguage(String lang) {
    selectedLanguage.value = lang;
    triggerFeedback();
    AppLocalizations.instance.changeLanguage(lang);
    saveSettings();
  }
}
