// views/onboarding_screen.dart
import 'package:flutter/material.dart';
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
      Get.offAllNamed("/home"); // Use offAllNamed to clear the stack
    } else {
      Get.offAllNamed("/login"); // Use offAllNamed to clear the stack
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // App's primary color (as requested)
    const Color appPrimaryColor = Color(0xFF2E3BB5);

    // Interchanged: white at top and bottom, primary in the middle
    final gradientColors = isDark
        ? [
            colorScheme.surface,
            colorScheme.primaryContainer,
            colorScheme.surface,
          ]
        : [
            Colors.white, // Top
            colorScheme.primary, // Middle
            Colors.white, // Bottom
          ];

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
            stops: const [
              0.0,
              0.5,
              1.0
            ], // White at top and bottom, color in the middle
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AppIcons.logo,
                width: 250,
                height: 250,
              ),
              const SizedBox(height: 60),
              // Welcome: outlined and shadowed text
              Stack(
                children: [
                  // Outline
                  Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFontsStyles.openSans,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 4
                        ..color = Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Fill with shadow
                  Text(
                    'Welcome!',
                    style: TextStyle(
                      color: isDark ? appPrimaryColor : Colors.black,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFontsStyles.openSans,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 3),
                          blurRadius: 12,
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
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontFamily: AppFontsStyles.montserrat,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 300),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 144,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: _handleGetStarted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? colorScheme.surface : Colors.white,
                        foregroundColor:
                            isDark ? colorScheme.primary : Colors.black,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: isDark
                            ? BorderSide(color: colorScheme.primary, width: 1.2)
                            : BorderSide.none,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: AppSizes.fontVerySmall,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 26),
                  SizedBox(
                    width: 144,
                    height: 38,
                    child: OutlinedButton(
                      onPressed: _handleMyAccount,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: appPrimaryColor,
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: appPrimaryColor,
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'My Account',
                        style: TextStyle(
                          fontSize: AppSizes.fontVerySmall,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Ensure text is white
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
