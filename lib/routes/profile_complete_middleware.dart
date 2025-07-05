// routes/profile_complete_middleware.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileCompleteMiddleware extends GetMiddleware {
  @override
  int? priority = 1;

  @override
  RouteSettings? redirect(String? route) {
    // TEMPORARY FIX: Disable all profile checks due to Firebase payment issues
    // TODO: Restore the original checks after fixing Firebase payment integration

    debugPrint("ProfileCompleteMiddleware: Checking route: $route (disabled)");
    return null; // Allow all access for now

    /* RESTORE THIS AFTER FIXING FIREBASE PAYMENT:
    final auth = Get.find<AuthController>();

    // Skip check for these routes
    final allowedRoutes = [
      '/profile-update',
      '/login',
      '/signup',
      '/forgot-password',
      '/onboarding'
    ];

    if (allowedRoutes.contains(route)) {
      return null;
    }

    if (auth.auth.currentUser != null && auth.userRole.value.isEmpty) {
      auth.loadUserData();
      return null; // Don't redirect while loading
    }

    if (auth.auth.currentUser != null && !auth.isProfileComplete.value) {
      return const RouteSettings(name: '/profile-update');
    }

    return null;
    */
  }
}
