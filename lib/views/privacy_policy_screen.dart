// views/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task/controllers/settings_controller.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                    icon: Icon(Icons.arrow_back, color: isDark ? colorScheme.onSurface : colorScheme.onPrimary),
                    onPressed: () {
                      Get.find<SettingsController>().triggerFeedback();
                      Get.back();
                    },
                  ),
                  const Spacer(),
                  Text(
                    "Privacy Policy",
                    style: GoogleFonts.raleway(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? colorScheme.onSurface : colorScheme.onPrimary),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
            Divider(height: 1, color: (isDark ? colorScheme.onSurface : colorScheme.onPrimary).withValues(alpha: 0.3), thickness: 1),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.secondary.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.privacy_tip_outlined,
                          size: 40.sp,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                    
                    // Title
                    Center(
                      child: Text(
                        "Privacy Policy",
                        style: GoogleFonts.raleway(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Dates
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "Effective Date: 12/08/2025",
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: (isDark ? colorScheme.onSurface : colorScheme.onPrimary).withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            "Last Updated: 12/08/2025",
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: (isDark ? colorScheme.onSurface : colorScheme.onPrimary).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Introduction
                    _buildSection(
                      colorScheme,
                      "",
                      "Thank you for using our Task Management App (\"we\", \"our\", or \"us\"). Your privacy is important to us. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application (the \"App\"). Please read this policy carefully. If you do not agree with the terms of this Privacy Policy, please do not use the App.",
                      isDark,
                    ),
                    
                    // Section 1
                    _buildSection(
                      colorScheme,
                      "1. Information We Collect",
                      "We may collect the following types of information:",
                      isDark,
                    ),
                    
                    _buildSubSection(
                      colorScheme,
                      "a. Personal Information",
                      ["Name", "Email address", "User role (e.g., admin, user, librarian)", "Profile photo (if uploaded)"],
                      isDark,
                    ),
                    
                    _buildSubSection(
                      colorScheme,
                      "b. Task-related Data",
                      ["Tasks you create or are assigned", "Task metadata such as due dates, tags, and completion status", "Comments or notes on tasks"],
                      isDark,
                    ),
                    
                    _buildSubSection(
                      colorScheme,
                      "c. Usage Information",
                      ["App usage statistics", "Device information (e.g., model, operating system)", "Log files (e.g., errors, crashes)"],
                      isDark,
                    ),
                    
                    _buildSubSection(
                      colorScheme,
                      "d. Optional Permissions",
                      ["Access to device storage (for file attachments)", "Notifications (to alert users about task updates)"],
                      isDark,
                    ),
                    
                    // Section 2
                    _buildSection(
                      colorScheme,
                      "2. How We Use Your Information",
                      "We use the collected information for the following purposes:",
                      isDark,
                    ),
                    
                    _buildBulletList(
                      colorScheme,
                      [
                        "To create and manage your account",
                        "To assign and track tasks",
                        "To send notifications related to tasks",
                        "To improve the functionality and performance of the app",
                        "To provide customer support",
                        "To ensure compliance with app policies and terms"
                      ],
                      isDark,
                    ),
                    
                    // Section 3
                    _buildSection(
                      colorScheme,
                      "3. Sharing Your Information",
                      "We do not sell or rent your personal data. We may share your information in the following cases:",
                      isDark,
                    ),
                    
                    _buildBulletList(
                      colorScheme,
                      [
                        "With other users in your team or organization (e.g., task assignments)",
                        "With service providers who help us operate the app (e.g., Firebase, analytics)",
                        "If required by law or in response to valid legal requests"
                      ],
                      isDark,
                    ),
                    
                    // Section 4
                    _buildSection(
                      colorScheme,
                      "4. Data Retention",
                      "We retain your personal and task data for as long as necessary to provide our services, fulfill legal obligations, resolve disputes, and enforce our agreements.",
                      isDark,
                    ),
                    
                    // Section 5
                    _buildSection(
                      colorScheme,
                      "5. Security",
                      "We implement reasonable administrative, technical, and physical safeguards to protect your information. However, no method of transmission over the internet or electronic storage is 100% secure.",
                      isDark,
                    ),
                    
                    // Section 6
                    _buildSection(
                      colorScheme,
                      "6. Your Choices and Rights",
                      "Depending on your location, you may have the right to:",
                      isDark,
                    ),
                    
                    _buildBulletList(
                      colorScheme,
                      [
                        "Access the personal information we hold about you",
                        "Request correction or deletion of your data",
                        "Object to processing or request data portability"
                      ],
                      isDark,
                    ),
                    
                    _buildParagraph(
                      colorScheme,
                      "You can manage your account settings or contact us directly at danielcyudoncy@gmail.com for assistance.",
                      isDark,
                    ),
                    
                    // Section 7
                    _buildSection(
                      colorScheme,
                      "7. Children's Privacy",
                      "Our App is not intended for children under the age of 13 (or under the age of 16 in some jurisdictions), and we do not knowingly collect data from them.",
                      isDark,
                    ),
                    
                    // Section 8
                    _buildSection(
                      colorScheme,
                      "8. Third-Party Services",
                      "Our App may link to or use third-party services (e.g., Firebase). Their privacy practices are governed by their own policies. We encourage you to review them.",
                      isDark,
                    ),
                    
                    // Section 9
                    _buildSection(
                      colorScheme,
                      "9. Changes to This Privacy Policy",
                      "We may update this policy from time to time. We will notify you of any significant changes by updating the \"Effective Date\" and, where appropriate, via in-app notification.",
                      isDark,
                    ),
                    
                    // Section 10
                    _buildSection(
                      colorScheme,
                      "10. Contact Us",
                      "If you have any questions or concerns about this Privacy Policy, please contact us at:",
                      isDark,
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Contact Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.secondary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: colorScheme.secondary,
                                size: 20.sp,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Email: danieludoncy@gmail.com",
                                style: GoogleFonts.raleway(
                                  fontSize: 14.sp,
                                  color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: colorScheme.secondary,
                                size: 20.sp,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Developer: Daniel Udoncy",
                                style: GoogleFonts.raleway(
                                  fontSize: 14.sp,
                                  color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(ColorScheme colorScheme, String title, String content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: GoogleFonts.raleway(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          content,
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            color: (isDark ? colorScheme.onSurface : colorScheme.onPrimary).withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
  
  Widget _buildSubSection(ColorScheme colorScheme, String title, List<String> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            title,
            style: GoogleFonts.raleway(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, right: 8),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: (isDark ? colorScheme.onSurface : colorScheme.onPrimary).withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildBulletList(ColorScheme colorScheme, List<String> items, bool isDark) {
    return Column(
      children: [
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, right: 12),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: (isDark ? colorScheme.onSurface : colorScheme.onPrimary).withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildParagraph(ColorScheme colorScheme, String content, bool isDark) {
    return Column(
      children: [
        Text(
          content,
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            color: (isDark ? colorScheme.onSurface : colorScheme.onPrimary).withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}