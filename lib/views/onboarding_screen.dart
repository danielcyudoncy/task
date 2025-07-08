// views/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/utils/constants/app_colors.dart';
import 'package:task/utils/constants/app_fonts_family.dart';
import 'package:task/utils/constants/app_icons.dart';
import 'package:task/utils/constants/app_sizes.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _handleGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    Get.offAllNamed("/signup");
  }

  void _handleMyAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Get.offAllNamed("/home");
    } else {
      Get.offAllNamed("/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).canvasColor
              : Theme.of(context).colorScheme.primary,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AppIcons.logo,
                width: 250.w,
                height: 250.h,
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFontsStyles.raleway,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 4
                        ..color = colorScheme.onPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Welcome!',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFontsStyles.raleway,
                      shadows: [
                        Shadow(
                          color: colorScheme.onSurface.withAlpha(92),
                          offset: const Offset(0, 6.0),
                          blurRadius: 12.0,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Thanks for joining! Access or\n'
                'create your account below, and get\n'
                'started on your journey!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 18.sp,
                  fontFamily: AppFontsStyles.openSans,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 150),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 144.w,
                    height: 38.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.find<SettingsController>().triggerFeedback();
                        _handleGetStarted();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: AppSizes.fontNormal,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 26),
                  SizedBox(
                    width: 144.w,
                    height: 38.h,
                    child: OutlinedButton(
                      onPressed: () {
                        Get.find<SettingsController>().triggerFeedback();
                        _handleMyAccount();
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'My Account',
                        style: TextStyle(
                          fontSize: AppSizes.fontNormal,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}
