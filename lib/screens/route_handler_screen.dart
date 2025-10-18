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
    // Minimal delay to ensure services are ready
    await Future.delayed(const Duration(milliseconds: 50));

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

    // If user is logged in, let middleware handle the routing
    // This will go through AuthMiddleware and ProfileCompleteMiddleware
    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    // Invisible screen with primary color background to prevent flash
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: const SizedBox.shrink(),
    );
  }
}