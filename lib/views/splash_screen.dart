// views/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task/utils/constants/app_icons.dart';
import 'package:task/utils/constants/app_sizes.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      if (!hasSeenOnboarding) {
        Get.offAllNamed('/onboarding');
      } else {
        Get.offAllNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E3BB5), // Using the specified blue color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppIcons.logo, // Using the logo from your AppIcons class
              width: 200.w, // Adjust size as needed
              height: 200.h,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your home for news',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Raleway',
                fontSize: AppSizes.fontVeryLarge, // Use the size from your AppSizes class
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ), // Add a loading indicator
          ],
        ),
      ),
    );
  }
}