// views/settings_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../controllers/theme_controller.dart';
import '../utils/localization/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController settingsController = Get.find<SettingsController>();
  final ThemeController themeController = Get.find<ThemeController>();

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'settings'.tr,
          style: TextStyle(
            fontFamily: 'raleway',
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 30.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          // Add safety check to ensure controllers are registered
          if (!Get.isRegistered<ThemeController>() || !Get.isRegistered<SettingsController>()) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 10),
                      child: Image.asset(
                        'assets/png/logo.png',
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),
                  sectionTitle(context, "App Preferences"),
                  // App Preferences
                  // Only ThemeController manages dark mode. Do not use SettingsController for theme.
                  Obx(() {
                    // Add safety check to ensure controller is registered
                    if (!Get.isRegistered<ThemeController>()) {
                      return settingsSwitchTile(
                        context,
                        "Dark Mode",
                        "Activate dark background for app",
                        false,
                        (value) {},
                      );
                    }
                    
                    return settingsSwitchTile(
                      context,
                      "Dark Mode",
                      "Activate dark background for app",
                      themeController.isDarkMode.value,
                      (value) {
                        themeController.toggleTheme(value);
                      },
                    );
                  }),
                  sectionTitle(context, 'sound_and_vibration'.tr),
                  settingsSwitchTile(
                    context,
                    'sounds'.tr,
                    'enable_sound'.tr,
                    settingsController.isSoundEnabled.value,
                    (value) {
                      settingsController.toggleSound(value);
                      settingsController.saveSettings();
                    },
                  ),
                  settingsSwitchTile(
                    context,
                    'Enable Biometric Login',
                    'Use fingerprint or face to login',
                    settingsController.isBiometricEnabled.value,
                    (value) {
                      settingsController.toggleBiometric(value);
                    },
                  ),
                  settingsSwitchTile(
                    context,
                    'vibration'.tr,
                    'enable_disable_vibration'.tr,
                    settingsController.isVibrationEnabled.value,
                    (value) {
                      settingsController.toggleVibration(value);
                      settingsController.saveSettings();
                    },
                  ),
                  sectionTitle(context, 'account_preferences'.tr),
                  settingsDropdownTile(
                    context,
                    'language'.tr,
                    settingsController.selectedLanguage.value,
                    [
                      'English (Default)',
                      'French',
                      'Hausa',
                      'Yoruba',
                      'Igbo'
                    ],
                    (lang) {
                      settingsController.setLanguage(lang);
                      settingsController.saveSettings();
                    },
                  ),
                  // Warning message for unsupported languages
                  if (!AppLocalizations.isLanguageFullySupported(settingsController.selectedLanguage.value))
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'unsupported_language_note'.trParams({'language': settingsController.selectedLanguage.value}),
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  sectionTitle(context, 'sync_settings'.tr),
                  settingsSwitchTile(
                    context,
                    'synchronize_data'.tr,
                    "",
                    settingsController.isSyncEnabled.value,
                    (value) {
                      settingsController.toggleSync(value);
                      settingsController.saveSettings();
                    },
                  ),
                  // Debug section for theme issues
                  if (kDebugMode) ...[
                    sectionTitle(context, "Debug Options"),
                    ListTile(
                      title: Text(
                        "Reset Theme to Light",
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        "Force reset theme to light mode",
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
                        onPressed: () {
                          themeController.resetToDefaultTheme();
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  saveButton(settingsController),
                  const SizedBox(height: 30),
                  nextPageButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget sectionTitle(BuildContext context, String title) => Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.only(top: 18, bottom: 6),
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );

  Widget settingsSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 0, right: 0),
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 13),
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: Theme.of(context).colorScheme.secondary,
          inactiveThumbColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          inactiveTrackColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.24),
        ),
      ),
    );
  }

  Widget settingsDropdownTile(
    BuildContext context,
    String title,
    String selected,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 0, right: 0),
        title: Text(title,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w500)),
        trailing: DropdownButton<String>(
          value: selected,
          dropdownColor: Theme.of(context).colorScheme.primary,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w400),
          underline: Container(),
          items: options
              .map((lang) => DropdownMenuItem(
                    value: lang,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(lang),
                        if (!AppLocalizations.isLanguageFullySupported(lang)) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.orange,
                          ),
                        ],
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (String? value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }

  Widget saveButton(SettingsController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2F80ED),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: () async {
          await controller.triggerFeedback();
          await controller.saveSettings();

          Get.snackbar(
            'settings_saved'.tr,
            'preferences_updated'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.grey[900],
            colorText: Colors.white,
          );
        },
        child: Text(
          'save'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
    );
  }

  Widget nextPageButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF2F80ED), width: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () {
          Get.toNamed('/privacy');
        },
        child: Text('next_privacy_settings'.tr,
            style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
