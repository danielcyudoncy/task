// views/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task/utils/constants/app_icons.dart';
import 'package:task/controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint("🎨 SPLASH: initState called");
    Timer(const Duration(seconds: 3), () async {
      try {
        debugPrint("Splash screen: Starting navigation logic");
        final prefs = await SharedPreferences.getInstance();
        final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
        debugPrint("Splash screen: hasSeenOnboarding = $hasSeenOnboarding");

        if (!hasSeenOnboarding) {
          debugPrint("Splash screen: Navigating to onboarding");
          Get.offAllNamed('/onboarding');
        } else {
          // Check if user is already logged in
          final authController = Get.find<AuthController>();
          debugPrint("Splash screen: AuthController found, checking login status");
          
          // Wait a bit for Firebase auth to initialize
          await Future.delayed(const Duration(milliseconds: 500));
          
          debugPrint("Splash screen: currentUser = ${authController.currentUser?.uid}");
          debugPrint("Splash screen: isLoggedIn = ${authController.isLoggedIn}");
          debugPrint("Splash screen: Firebase auth currentUser = ${authController.auth.currentUser?.uid}");
          
          if (authController.isLoggedIn) {
            // User is logged in, navigate based on role
            debugPrint("Splash screen: User is already logged in, navigating based on role");
            authController.navigateBasedOnRole();
          } else {
            // User is not logged in, go to login screen
            debugPrint("Splash screen: User is not logged in, going to login screen");
            Get.offAllNamed('/login');
          }
        }
      } catch (e) {
        debugPrint("Splash screen navigation error: $e");
        // Fallback to login screen
        Get.offAllNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("🎨 SPLASH: build called");
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface,
                    Colors.grey.shade900,
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF08169D),
                    Color(0xFF08169D),
                  ],
                ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with rounded corners
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  AppIcons.logo,
                  width: 200.w,
                  height: 200.h,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your Home For News',
                style: textTheme.headlineSmall?.copyWith(
                  color: isDark ? Colors.white : Colors.white,
                  fontFamily: 'Raleway',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
