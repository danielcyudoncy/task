// routes/middleware.dart
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'package:flutter/material.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? priority = 0;

 @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    final arguments = Get.arguments as Map<String, dynamic>?;

    // Bypass checks if coming from logout
    if (arguments?['fromLogout'] == true) {
      return null;
    }

    // Public routes
    final publicRoutes = [
      '/',
      '/login',
      '/signup',
      '/forgot-password',
      '/onboarding'
    ];
    if (publicRoutes.contains(route)) {
      return null;
    }

    // Special case for profile-update
    if (route == '/profile-update') {
      return auth.auth.currentUser == null
          ? const RouteSettings(name: '/login')
          : null;
    }

    // Main auth check
    if (auth.auth.currentUser == null) {
      return const RouteSettings(name: '/login');
    }

    // Role loading state
    if (auth.userRole.value.isEmpty) {
      debugPrint("Waiting for user role to load...");
      return null;
    }

    return null;
  }
}
