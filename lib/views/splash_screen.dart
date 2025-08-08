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
    Timer(const Duration(seconds: 3), () async {
      try {
        
        // Wait for bootstrap to complete
        while (!isBootstrapComplete) {
          
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
        
        final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
        
        if (!hasSeenOnboarding) {
          Get.offAllNamed('/onboarding');
        } else {
          // Check if user is already logged in
          if (!Get.isRegistered<AuthController>()) {
            Get.offAllNamed('/login');
            return;
          }
          
          final authController = Get.find<AuthController>();
          
          // Wait a bit for Firebase auth to initialize
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (authController.isLoggedIn) {
            // User is logged in, navigate based on role
            authController.navigateBasedOnRole();

          } else {
            // User is not logged in, go to login screen
            Get.offAllNamed('/login');
          }
        }
      } catch (e) {
        // Fallback to login screen
        Get.offAllNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                borderRadius: BorderRadius.circular(16.r),
                child: Image.asset(
                  AppIcons.logo,
                  width: 200.w,
                  height: 200.h,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'your_friendly_companion'.tr,
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontFamily: 'Raleway',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 16.h),
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
