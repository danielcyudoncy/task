// views/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../controllers/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController settingsController = Get.find<SettingsController>();
  final ThemeController themeController = Get.find<ThemeController>();

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor:
          isLightMode ? const Color(0xFF05168E) : const Color(0xFF181B2A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            isLightMode ? const Color(0xFF05168E) : const Color(0xFF181B2A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            await settingsController.triggerFeedback();
            Get.back();
          },
        ),
        title: Text(
          'Settings',
          style: TextStyle(
              fontFamily: 'raleway',
              color: Colors.white,
              fontSize: 30.sp,
              fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() => SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: GestureDetector(
                        onTap: () => settingsController.triggerFeedback(),
                        child: Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 10),
                          child: Image.asset(
                            'assets/png/logo.png',
                            width: 100,
                            height: 100,
                          ),
                        ),
                      ),
                    ),
                    sectionTitle("App Preferences"),
                    settingsSwitchTile(
                      "Dark Mode",
                      "Activate Dark background for app",
                      themeController.isDarkMode.value,
                      (value) async {
                        await settingsController.triggerFeedback();
                        themeController.toggleTheme(value);
                      },
                    ),
                    sectionTitle("Sound and Vibration"),
                    settingsSwitchTile(
                      "Sounds",
                      "Enable Sound",
                      settingsController.isSoundEnabled.value,
                      (value) async {
                        await settingsController.triggerFeedback();
                        settingsController.toggleSound(value);
                      },
                    ),
                    settingsSwitchTile(
                      "Vibration",
                      "Enable/Disable Vibration",
                      settingsController.isVibrationEnabled.value,
                      (value) async {
                        await settingsController.triggerFeedback();
                        settingsController.toggleVibration(value);
                      },
                    ),
                    sectionTitle("Account Preferences"),
                    settingsDropdownTile(
                      "Language",
                      settingsController.selectedLanguage.value,
                      [
                        "English (Default)",
                        "French",
                        "Hausa",
                        "Yoruba",
                        "Igbo"
                      ],
                      (lang) async {
                        await settingsController.triggerFeedback();
                        settingsController.setLanguage(lang);
                      },
                    ),
                    sectionTitle("Sync Settings"),
                    settingsSwitchTile(
                      "Synchronize data across all devices",
                      "",
                      settingsController.isSyncEnabled.value,
                      (value) async {
                        await settingsController.triggerFeedback();
                        settingsController.toggleSync(value);
                      },
                    ),
                    const SizedBox(height: 14),
                    saveButton(settingsController),
                    const SizedBox(height: 30),
                    nextPageButton(settingsController),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            )),
      ),
    );
  }

  // Keep all your existing UI widgets exactly the same
  Widget sectionTitle(String title) => Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.only(top: 18, bottom: 6),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );

  Widget settingsSwitchTile(
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
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF2F80ED),
          inactiveThumbColor: Colors.white70,
          inactiveTrackColor: Colors.white24,
        ),
      ),
    );
  }

  Widget settingsDropdownTile(
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
        title: Text(
          title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        trailing: DropdownButton<String>(
          value: selected,
          dropdownColor: const Color(0xFF05168E),
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
          underline: Container(),
          items: options
              .map((lang) => DropdownMenuItem(
                    value: lang,
                    child: Text(lang),
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
            "Settings Saved",
            "Your preferences have been updated.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.grey[900],
            colorText: Colors.white,
          );
        },
        child: const Text(
          "Save",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
    );
  }

  Widget nextPageButton(SettingsController controller) {
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
        onPressed: () async {
          await controller.triggerFeedback();
          Get.toNamed('/privacy');
        },
        child: const Text("Next: Privacy Settings",
            style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
