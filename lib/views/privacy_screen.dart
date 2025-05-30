// views/privacy_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colors
    final Color baseColor =
        isDark ? const Color(0xFF121212) : const Color(0xFF1019A6);
    final Color sectionTitleColor = isDark ? Colors.white : Colors.white;
    final Color textColor = isDark ? Colors.white70 : Colors.white;
    final Color dividerColor = isDark ? Colors.white24 : Colors.white54;
    final Color saveButtonColor =
        isDark ? const Color(0xFF1E88E5) : const Color(0xFF19A2FF);

    return Scaffold(
      backgroundColor: baseColor,
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
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  const Spacer(),
                  const Text(
                    "Settings",
                    style: TextStyle(
                        fontSize: 33,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
            Divider(height: 1, color: dividerColor, thickness: 2),
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
                    Align(
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
                    Align(
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
                        Expanded(
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
                    Align(
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
                        Expanded(
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Ad’s Prference",
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
                        Expanded(
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
                    Align(
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
                      title: Text(
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
                    Align(
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
                      title: Text(
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
