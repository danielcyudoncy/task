// views/privacy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? colorScheme.background
          : colorScheme.primary,
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
                    icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
                    onPressed: () {
                      Get.find<SettingsController>().triggerFeedback();
                      Get.back();
                    },
                  ),
                  const Spacer(),
                   Text(
                    "Privacy",
                    style: GoogleFonts.raleway(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.onPrimary.withOpacity(0.3), thickness: 1),
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
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Third Party Services
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Third Party Services",
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Get alerts of new assignments",
                            style: GoogleFonts.raleway(
                              color: colorScheme.onPrimary.withOpacity(0.8),
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        Switch(
                          value: thirdPartyAlerts,
                          activeColor: colorScheme.secondary,
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
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Enable/Disable Location",
                            style: GoogleFonts.raleway(
                              color: colorScheme.onPrimary.withOpacity(0.8),
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        Switch(
                          value: locationServices,
                          activeColor: colorScheme.secondary,
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
                        "Ad's Preference",
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Targeted Ads",
                            style: GoogleFonts.raleway(
                              color: colorScheme.onPrimary.withOpacity(0.8),
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        Switch(
                          value: targetedAds,
                          activeColor: colorScheme.secondary,
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
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "View Privacy Policy",
                        style: GoogleFonts.raleway(
                          color: colorScheme.onPrimary.withOpacity(0.8),
                          fontSize: 14.sp,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, color: colorScheme.onPrimary),
                      onTap: () {
                        // Navigate to privacy policy
                      },
                    ),

                    // Security
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Security",
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Set up two - factor authentication",
                        style: GoogleFonts.raleway(
                          color: colorScheme.onPrimary.withOpacity(0.8),
                          fontSize: 14.sp,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, color: colorScheme.onPrimary),
                      onTap: () {
                        // Navigate to security setup
                      },
                    ),
                    const SizedBox(height: 30),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () {
                          // Save action
                          Get.snackbar(
                            'Success',
                            'Privacy settings saved successfully',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: const Color(0xFF2E7D32),
                            colorText: Colors.white,
                          );
                        },
                        child: Text(
                          "Save",
                          style: GoogleFonts.raleway(
                              fontSize: 16.sp, fontWeight: FontWeight.bold),
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
