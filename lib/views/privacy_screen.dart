// views/privacy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool thirdPartyAlerts = false;
  bool locationServices = false;
  bool targetedAds = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color baseColor = colorScheme.primary;
    const Color sectionTitleColor = Colors.white;
    const Color textColor = Colors.white70;
    const Color dividerColor = Colors.white54;
    const Color saveButtonColor = Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).canvasColor
          : Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.only(
                  left: 12, top: 12, right: 12, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
                    onPressed: () {
                      Get.find<SettingsController>().triggerFeedback();
                      Get.back();
                    },
                  ),
                  const Spacer(),
                   Text(
                    "Settings",
                    style: TextStyle(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'raleway',
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
            const Divider(height: 1, color: dividerColor, thickness: 2),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // App logo
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 18, top: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/png/logo.png', // Replace with your asset path
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Privacy Settings Title
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Privacy Settings",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: sectionTitleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Third Party Services
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Third Party Services",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: sectionTitleColor,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            "Get alerts of new assignments",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Switch(
                          value: thirdPartyAlerts,
                          activeColor: saveButtonColor,
                          onChanged: (val) =>
                              setState(() => thirdPartyAlerts = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Location Services
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Location Services",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: sectionTitleColor,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            "Enable/Disable Location",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Switch(
                          value: locationServices,
                          activeColor: saveButtonColor,
                          onChanged: (val) =>
                              setState(() => locationServices = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Ad's Preference
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Ad's Prference",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: sectionTitleColor,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            "Targeted Ads",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Switch(
                          value: targetedAds,
                          activeColor: saveButtonColor,
                          onChanged: (val) => setState(() => targetedAds = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Privacy Policy
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Privacy Policy",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: sectionTitleColor,
                        ),
                      ),
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "View Privacy Policy",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white),
                      onTap: () {
                        // Navigate to privacy policy
                      },
                    ),

                    // Security
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Security",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: sectionTitleColor,
                        ),
                      ),
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Set up two - factor authentication",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white),
                      onTap: () {
                        // Navigate to security setup
                      },
                    ),
                    const SizedBox(height: 30),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          // Save action
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: saveButtonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
