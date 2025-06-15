// views/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task/utils/constants/app_fonts_family.dart';
import 'package:task/utils/constants/app_icons.dart';
import 'package:task/utils/constants/app_sizes.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _handleGetStarted() {
    Get.offAllNamed("/signup"); // Use offAllNamed to clear the stack
  }

  void _handleMyAccount() {
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

    // Use colorScheme.primary as app main blue if possible
    final Color appPrimaryColor = colorScheme.primary;

    // Gradient: white at top, blue at bottom for light theme, muted for dark theme
    final gradientColors = isDark
        ? [
            colorScheme.background,
            colorScheme.surfaceVariant,
            colorScheme.background,
          ]
        : [
            Colors.white, // Top
            appPrimaryColor, // Bottom (blue)
          ];

    final gradientStops = isDark ? const [0.0, 0.7, 1.0] : const [0.0, 1.0];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
            stops: gradientStops,
          ),
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
                      fontFamily: AppFontsStyles.montserrat,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 4
                        ..color = isDark
                            ? colorScheme.onSurface
                            : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Welcome!',
                    style: TextStyle(
                      color: isDark ? appPrimaryColor : Colors.black,
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFontsStyles.montserrat,
                      shadows: [
                        Shadow(
                          color: isDark
                              ? colorScheme.onSurface.withOpacity(0.36)
                              : Colors.black26,
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
                  color: isDark
                      ? colorScheme.onBackground
                      : colorScheme.onPrimaryContainer,
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
                      onPressed: _handleGetStarted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: AppSizes.fontNormal,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 26),
                  SizedBox(
                    width: 144.w,
                    height: 38.h,
                    child: OutlinedButton(
                      onPressed: _handleMyAccount,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(
                          color: colorScheme.primary,
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
                          color: colorScheme.primary,
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
