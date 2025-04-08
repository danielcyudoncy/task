// views/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task/controllers/auth_controller.dart';

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
    _navigateBasedOnAuth();
  }

  // ✅ Check if user is logged in and navigate accordingly
  Future<void> _navigateBasedOnAuth() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate splash delay

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // ✅ Delayed loading of user data after splash screen
        await Future.delayed(const Duration(
            milliseconds:
                500)); // Optional small delay before loading user data
        await authController
            .loadUserData(); // ✅ Load user data after splash screen delay

        // ✅ Navigate based on role
        if (authController.userRole.value == "Reporter" ||
            authController.userRole.value == "Cameraman") {
          Get.offAllNamed("/home");
        } else if (authController.userRole.value == "Admin" ||
            authController.userRole.value == "Assignment Editor" ||
            authController.userRole.value == "Head of Department") {
          Get.offAllNamed("/admin-dashboard");
        } else {
          Get.offAllNamed("/login"); // Fallback
        }
      } else {
        Get.offAllNamed(
            "/login"); // ✅ Always go to Sign In if no user is logged in
      }
    } catch (e) {
      // Handle error if any occurs
      print("Error: $e");
      Get.offAllNamed("/login"); // Fallback in case of an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/logo.png",
                width: 150), // ✅ Replace with your logo
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
