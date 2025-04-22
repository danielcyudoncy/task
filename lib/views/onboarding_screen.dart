// views/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _handleGetStarted() {
    Get.toNamed("/signup");
  }

  void _handleMyAccount() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is authenticated
      Get.offAllNamed("/home"); // or navigate to their specific role-based page
    } else {
      // Not logged in
      Get.toNamed("/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const FlutterLogo(size: 100), // Or custom branding
            const SizedBox(height: 40),
            Text(
              "Welcome to Assignment Logger",
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: _handleGetStarted,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50)),
              child: const Text("Get Started"),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _handleMyAccount,
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50)),
              child: const Text("My Account"),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
