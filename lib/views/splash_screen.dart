// views/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // ✅ Initialize the app, load user data, and navigate based on role
  Future<void> _initializeApp() async {
    try {
      // Display splash screen for at least 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      // Check if the user is logged in
      if (FirebaseAuth.instance.currentUser == null) {
        Get.offAllNamed("/login"); // Redirect to login screen
        return;
      }

      // Load user data and navigate based on role
      await authController.loadUserData();
      authController.navigateBasedOnRole();
    } catch (e) {
      print("Error during initialization: $e");
      Get.offAllNamed("/login"); // Fallback to login in case of error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace with your app's logo asset
            Image.asset("assets/png/logo.png", width: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
