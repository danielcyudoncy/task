// views/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());

   SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05168E), // Deep blue background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF05168E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
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
                    // Logo
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 10),
                        child: Image.asset(
                          'assets/png/logo.png', // Use your asset path!
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ),

                    // ----------- App Preferences -----------
                    sectionTitle("App Preferences"),
                    settingsSwitchTile(
                      "Dark Mode",
                      "Activate Dark background for app",
                      controller.isDarkMode.value,
                      controller.toggleDarkMode,
                    ),

                    // ----------- Sound and Vibration -----------
                    sectionTitle("Sound and Vibration"),
                    settingsSwitchTile(
                      "Sounds",
                      "Enable Sound",
                      controller.isSoundEnabled.value,
                      controller.toggleSound,
                    ),
                    settingsSwitchTile(
                      "Vibration",
                      "Enable/Disable Vibration",
                      controller.isVibrationEnabled.value,
                      controller.toggleVibration,
                    ),

                    // ----------- Account Preferences -----------
                    sectionTitle("Account Preferences"),
                    settingsDropdownTile(
                      "Language",
                      controller.selectedLanguage.value,
                      [
                        "English (Default)",
                        "French",
                        "Hausa",
                        "Yoruba",
                        "Igbo"
                      ],
                      controller.setLanguage,
                    ),

                    // ----------- Sync Settings -----------
                    sectionTitle("Sync Settings"),
                    settingsSwitchTile(
                      "Synchronize data across all devices",
                      "",
                      controller.isSyncEnabled.value,
                      controller.toggleSync,
                    ),

                    const SizedBox(height: 14),
                    // Save Button
                    saveButton(controller),
                    const SizedBox(height: 30),
                    // Go to next page button
                    nextPageButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            )),
      ),
    );
  }

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
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 13),
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
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
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
          await controller.onSave();
          Get.snackbar(
            "Settings Saved",
            "Your preferences have been updated.",
            backgroundColor: Colors.black.withOpacity(0.7),
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
          Get.to(() => SettingsPrivacyScreen());
        },
        child: const Text("Next: Privacy Settings",
            style: TextStyle(fontSize: 16)),
      ),
    );
  }
}

// ------- Second screen (Privacy Settings) -------
class SettingsPrivacyScreen extends StatelessWidget {
  final SettingsController controller = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05168E),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF05168E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
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
                    // Logo
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 10),
                        child: Image.asset(
                          'assets/images/channels_logo.png', // Use your asset path!
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ),
                    sectionTitle("Privacy Settings"),
                    settingsSwitchTile(
                      "Third Party Services",
                      "Get alerts of new assignments",
                      controller.isAssignmentAlertEnabled.value,
                      controller.toggleAssignmentAlert,
                    ),
                    settingsSwitchTile(
                      "Location Services",
                      "Enable/Disable Location",
                      controller.isLocationEnabled.value,
                      controller.toggleLocation,
                    ),
                    settingsSwitchTile(
                      "Ad’s Prference",
                      "Targeted Ads",
                      controller.isTargetedAdsEnabled.value,
                      controller.toggleTargetedAds,
                    ),
                    const SizedBox(height: 14),
                    // Privacy Policy
                    ListTile(
                      title: const Text(
                        "Privacy Policy",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text("View Privacy Policy",
                          style: TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 18),
                      onTap: () => controller.viewPrivacyPolicy(),
                    ),
                    // Security (2FA)
                    ListTile(
                      title: const Text(
                        "Security",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text("Set up two - factor authentication",
                          style: TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 18),
                      onTap: () => controller.setupTwoFactorAuthentication(),
                    ),
                    const SizedBox(height: 14),
                    saveButton(controller),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            )),
      ),
    );
  }

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
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 13),
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
          await controller.onSave();
          Get.snackbar(
            "Settings Saved",
            "Your preferences have been updated.",
            backgroundColor: Colors.black.withOpacity(0.7),
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
}
