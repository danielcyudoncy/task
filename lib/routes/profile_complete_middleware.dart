// routes/profile_complete_middleware.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class ProfileCompleteMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();

    // Skip check for these routes
    final allowedRoutes = [
      '/profile-update',
      '/login',
      '/signup',
      '/forgot-password',
      '/onboarding',
      '/'
    ];

    if (allowedRoutes.contains(route)) {
      return null;
    }

    // If user is not logged in, allow access (AuthMiddleware will handle this)
    if (auth.auth.currentUser == null) {
      return null;
    }

    // If user role is not loaded yet, allow access temporarily
    if (auth.userRole.value.isEmpty) {
      return null;
    }

    // If profile complete status is not loaded yet, allow access temporarily
    if (auth.isProfileComplete.value == false && auth.userRole.value.isEmpty) {
      return null;
    }

    // If profile is not complete, redirect to profile update
    if (!auth.isProfileComplete.value) {
      return const RouteSettings(name: '/profile-update');
    }

    return null;
  }
}
