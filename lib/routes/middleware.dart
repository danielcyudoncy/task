// routes/middleware.dart
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'package:flutter/material.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();

    // Allow these routes without auth
    if (route == '/' || route == '/login' || route == '/signup') {
      return null;
    }

    // Check both auth state and loaded role
    if (auth.userRole.value.isEmpty) {
      return const RouteSettings(name: '/login');
    }

    if (auth.auth.currentUser == null || auth.userRole.value.isEmpty) {
      debugPrint("Redirecting to login - Auth state invalid");
      return const RouteSettings(name: '/login');
    }

    return null;
  }
}
