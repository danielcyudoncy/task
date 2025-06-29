// routes/middleware.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? priority = 0;

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    final args = Get.arguments as Map<String, dynamic>?;

    // skip redirect if logout
    if (args?['fromLogout'] == true) return null;

    // Public routes
    const publicRoutes = ['/', '/login', '/signup', '/forgot-password', '/onboarding'];
    if (publicRoutes.contains(route)) return null;

    // Not logged in
    if (auth.auth.currentUser == null) {
      return const RouteSettings(name: '/login');
    }

    // Still loading user role
    

    // Now role is loaded—allow normal routing
    return null;
  }
}
