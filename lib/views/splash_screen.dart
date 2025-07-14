// views/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task/utils/constants/app_icons.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/core/bootstrap.dart';

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
        
        // Wait for bootstrap to complete
        while (!isBootstrapComplete) {
          debugPrint("Splash screen: Waiting for bootstrap to complete...");
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // Add a small delay to ensure all controllers are ready
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Mark app as ready for snackbars before navigation
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().markAppAsReady();
        }
        
        final prefs = await SharedPreferences.getInstance();
        
        // TEMPORARY: Reset onboarding for testing (remove this after testing)
        await prefs.remove('hasSeenOnboarding');
        debugPrint("Splash screen: TEMPORARILY RESET onboarding state for testing");
        
        final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
        debugPrint("Splash screen: hasSeenOnboarding = $hasSeenOnboarding");
        debugPrint("Splash screen: All SharedPreferences keys: ${prefs.getKeys()}");

        if (!hasSeenOnboarding) {
          debugPrint("Splash screen: Navigating to onboarding");
          Get.offAllNamed('/onboarding');
        } else {
          // Check if user is already logged in
          if (!Get.isRegistered<AuthController>()) {
            debugPrint("Splash screen: AuthController not registered, going to login");
            Get.offAllNamed('/login');
            return;
          }
          
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
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).canvasColor
              : Theme.of(context).colorScheme.primary,
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
                'your_home_for_news'.tr,
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontFamily: 'Raleway',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
