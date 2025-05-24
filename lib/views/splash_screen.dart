import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/utils/constants/app_icons.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Get.offAllNamed('/onboarding'); // Use offAllNamed to clear the stack
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
              width: 100, // Adjust size as needed
              height: 100,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your home for news',
              style: TextStyle(
                color: Colors.white, // Slightly transparent white
                fontSize: 18,
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