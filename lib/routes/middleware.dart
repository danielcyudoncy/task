// routes/middleware.dart
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'package:flutter/material.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? priority = 0; // Lower priority than ProfileCompleteMiddleware

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();

    // Always allow these routes
    if (route == '/' ||
        route == '/login' ||
        route == '/signup' ||
        route == '/profile-update') {
      return null;
    }

    // Check auth state
    if (auth.auth.currentUser == null) {
      debugPrint("AuthMiddleware: Redirecting to login - No user");
      return const RouteSettings(name: '/login');
    }

    // Check if user role is loaded
    if (auth.userRole.value.isEmpty) {
      debugPrint("AuthMiddleware: Redirecting to login - No role");
      return const RouteSettings(name: '/login');
    }

    return null;
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    debugPrint("AuthMiddleware: Entering ${page?.name}");
    return super.onPageCalled(page);
  }
}
