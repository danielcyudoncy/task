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

    debugPrint("ProfileCompleteMiddleware: Checking route: $route");
    debugPrint("ProfileCompleteMiddleware: isProfileComplete=${auth.isProfileComplete.value}, userRole=${auth.userRole.value}, currentRoute=${Get.currentRoute}");

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
      debugPrint("ProfileCompleteMiddleware: Allowing access to allowed route: $route");
      return null;
    }

    // If user is not logged in, allow access (AuthMiddleware will handle this)
    if (auth.auth.currentUser == null) {
      debugPrint("ProfileCompleteMiddleware: No user logged in, allowing access");
      return null;
    }

    // If user role is not loaded yet, allow access temporarily
    if (auth.userRole.value.isEmpty) {
      debugPrint("ProfileCompleteMiddleware: User role not loaded, allowing access");
      return null;
    }

    // If profile complete status is not loaded yet, allow access temporarily
    if (auth.isProfileComplete.value == false && auth.userRole.value.isEmpty) {
      debugPrint("ProfileCompleteMiddleware: Profile complete status not loaded, allowing access");
      return null;
    }

    // If profile is not complete, redirect to profile update
    if (!auth.isProfileComplete.value) {
      debugPrint("ProfileCompleteMiddleware: Profile not complete, redirecting to profile-update");
      return const RouteSettings(name: '/profile-update');
    }

    debugPrint("ProfileCompleteMiddleware: Profile complete, allowing access");
    return null;
  }
}
