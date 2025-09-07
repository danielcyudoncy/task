// views/privacy_screen_backup.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task/controllers/privacy_controller.dart';
import 'package:task/controllers/settings_controller.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late final PrivacyController privacyController;

  @override
  void initState() {
    super.initState();
    privacyController = Get.find<PrivacyController>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? colorScheme.surface
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
            Divider(height: 1, color: colorScheme.onPrimary.withValues(alpha: 0.3), thickness: 1),
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
                    Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Get alerts of new assignments",
                            style: GoogleFonts.raleway(
                              color: colorScheme.onPrimary.withValues(alpha: 0.8),
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        Switch(
                          value: privacyController.thirdPartyServices.value,
                          activeThumbColor: colorScheme.secondary,
                          onChanged: privacyController.toggleThirdPartyServices,
                        ),
                      ],
                    )),
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
                    Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Enable/Disable Location",
                            style: GoogleFonts.raleway(
                              color: colorScheme.onPrimary.withValues(alpha: 0.8),
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        Switch(
                          value: privacyController.locationServices.value,
                          activeThumbColor: colorScheme.secondary,
                          onChanged: privacyController.toggleLocationServices,
                        ),
                      ],
                    )),
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
                    Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Targeted Ads",
                            style: GoogleFonts.raleway(
                              color: colorScheme.onPrimary.withValues(alpha: 0.8),
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        Switch(
                          value: privacyController.adPreferences.value,
                          activeThumbColor: colorScheme.secondary,
                          onChanged: privacyController.toggleAdPreferences,
                        ),
                      ],
                    )),
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
                          color: colorScheme.onPrimary.withValues(alpha: 0.8),
                          fontSize: 14.sp,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, color: colorScheme.onPrimary),
                      onTap: () {
                        Get.find<SettingsController>().triggerFeedback();
                        Get.toNamed('/privacy-policy');
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
                    Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Enable App Lock (Biometric Authentication)",
                            style: GoogleFonts.raleway(
                              color: colorScheme.onPrimary.withValues(alpha: 0.8),
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        Switch(
                          value: privacyController.twoFactorAuth.value,
                          activeThumbColor: colorScheme.secondary,
                          onChanged: privacyController.toggleTwoFactorAuth,
                        ),
                      ],
                    )),
                     const SizedBox(height: 20),

                     // Data Management Section
                     Align(
                       alignment: Alignment.centerLeft,
                       child: Text(
                         "Data Management",
                         style: GoogleFonts.raleway(
                           fontWeight: FontWeight.w600,
                           fontSize: 16.sp,
                           color: colorScheme.onPrimary,
                         ),
                       ),
                     ),
                     const SizedBox(height: 10),
                     
                     // Export Data
                     ListTile(
                       leading: Icon(
                         Icons.download,
                         color: colorScheme.onPrimary,
                         size: 24.sp,
                       ),
                       title: Text(
                         "Export My Data",
                         style: GoogleFonts.raleway(
                           color: colorScheme.onPrimary,
                           fontSize: 16.sp,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                       subtitle: Text(
                         "Download a copy of your data",
                         style: GoogleFonts.raleway(
                           color: colorScheme.onPrimary.withValues(alpha: 0.7),
                           fontSize: 12.sp,
                         ),
                       ),
                       trailing: Icon(
                         Icons.arrow_forward_ios,
                         color: colorScheme.onPrimary.withValues(alpha: 0.6),
                         size: 16.sp,
                       ),
                       onTap: privacyController.exportUserData,
                     ),
                     
                     Divider(
                       color: colorScheme.onPrimary.withValues(alpha: 0.2),
                       thickness: 1,
                     ),
                     
                     // Delete Account
                     ListTile(
                       leading: Icon(
                         Icons.delete_forever,
                         color: Colors.red,
                         size: 24.sp,
                       ),
                       title: Text(
                         "Delete Account",
                         style: GoogleFonts.raleway(
                           color: Colors.red,
                           fontSize: 16.sp,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                       subtitle: Text(
                         "Permanently delete your account and data",
                         style: GoogleFonts.raleway(
                           color: colorScheme.onPrimary.withValues(alpha: 0.7),
                           fontSize: 12.sp,
                         ),
                       ),
                       trailing: Icon(
                         Icons.arrow_forward_ios,
                         color: colorScheme.onPrimary.withValues(alpha: 0.6),
                         size: 16.sp,
                       ),
                       onTap: privacyController.deleteUserAccount,
                     ),
                     
                     const SizedBox(height: 30),
                     // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: Obx(() => ElevatedButton(
                        onPressed: privacyController.isSaving.value 
                            ? null 
                            : privacyController.savePrivacySettings,
                        child: privacyController.isSaving.value
                            ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Text(
                                "Save",
                                style: GoogleFonts.raleway(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      )),
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
