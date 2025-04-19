// routes/profile_complete_middleware.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/auth_controller.dart';

class ProfileCompleteMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();

    // Skip check for these routes
    if (route == '/profile-update' || route == '/login' || route == '/signup') {
      return null;
    }

    // Check if profile is complete
    if (auth.auth.currentUser != null &&
        auth.userRole.value.isNotEmpty &&
        !auth.isProfileComplete.value) {
      return const RouteSettings(name: '/profile-update');
    }

    return null;
  }
}
