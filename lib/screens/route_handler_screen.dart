// screens/route_handler_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/auth_controller.dart';

class RouteHandlerScreen extends StatefulWidget {
  const RouteHandlerScreen({super.key});

  @override
  State<RouteHandlerScreen> createState() => _RouteHandlerScreenState();
}

class _RouteHandlerScreenState extends State<RouteHandlerScreen> {
  @override
  void initState() {
    super.initState();
    _handleRouting();
  }

  Future<void> _handleRouting() async {
    // Minimal delay for faster routing
    await Future.delayed(const Duration(milliseconds: 10));

    if (!Get.isRegistered<AuthController>()) {
      Get.offAllNamed('/login');
      return;
    }

    final authController = Get.find<AuthController>();

    // Quick check - if no user is logged in, go straight to login
    if (authController.currentUser == null && authController.auth.currentUser == null) {
      Get.offAllNamed('/login');
      return;
    }

    // Wait for role to be loaded if needed
    int attempts = 0;
    while (authController.userRole.value.isEmpty && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }

    // Navigate based on user role
    final role = authController.userRole.value;
    if (role == "Admin" ||
        role == "Assignment Editor" ||
        role == "Head of Department" ||
        role == "News Director" ||
        role == "Assistant News Director" ||
        role == "Head of Unit") {
      Get.offAllNamed('/admin-dashboard');
    } else if (role == "Librarian") {
      Get.offAllNamed('/librarian-dashboard');
    } else if (role == "Reporter" ||
        role == "Cameraman" ||
        role == "Driver" ||
        role == "Producer" ||
        role == "Anchor" ||
        role == "Business Reporter" ||
        role == "Political Reporter" ||
        role == "Digital Reporter" ||
        role == "Web Producer") {
      Get.offAllNamed('/home');
    } else {
      // Fallback to login if role is not recognized
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Completely transparent screen to prevent any flash
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(),
    );
  }
}