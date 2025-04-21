// routes/profile_complete_middleware.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/auth_controller.dart';

class ProfileCompleteMiddleware extends GetMiddleware {
  @override
  int? priority = 1; // Higher priority than AuthMiddleware

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();

    // Skip check for these routes
    if (route == '/profile-update' || route == '/login' || route == '/signup') {
      return null;
    }

    // Only check if user is authenticated
    if (auth.auth.currentUser != null &&
        auth.userRole.value.isNotEmpty &&
        !auth.isProfileComplete.value) {
      debugPrint("ProfileCompleteMiddleware: Redirecting to profile-update");
      return const RouteSettings(name: '/profile-update');
    }

    return null;
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    debugPrint("ProfileCompleteMiddleware: Entering ${page?.name}");
    return super.onPageCalled(page);
  }
}
