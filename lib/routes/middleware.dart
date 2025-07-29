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

    debugPrint("AuthMiddleware: Checking route: $route");
    debugPrint("AuthMiddleware: auth.currentUser: ${auth.currentUser?.uid}");
    debugPrint("AuthMiddleware: auth.auth.currentUser: ${auth.auth.currentUser?.uid}");
    debugPrint("AuthMiddleware: auth.userRole.value: ${auth.userRole.value}");
    debugPrint("AuthMiddleware: auth.isProfileComplete.value: ${auth.isProfileComplete.value}");

    // skip redirect if logout
    if (args?['fromLogout'] == true) return null;

    // Public routes - ensure login is always accessible
    const publicRoutes = ['/', '/login', '/signup', '/forgot-password', '/onboarding'];
    if (publicRoutes.contains(route)) {
      debugPrint("AuthMiddleware: Allowing access to public route: $route");
      return null;
    }

    // Not logged in - check both auth controller and Firebase auth
    if (auth.currentUser == null && auth.auth.currentUser == null) {
      debugPrint("AuthMiddleware: Redirecting to login - both users are null");
      return const RouteSettings(name: '/login');
    }

    // If user is logged in but role is not loaded yet, allow access temporarily
    if (auth.userRole.value.isEmpty && auth.auth.currentUser != null) {
      debugPrint("AuthMiddleware: User logged in but role not loaded, allowing access temporarily");
      return null;
    }

    // Check user role and redirect accordingly
    final role = auth.userRole.value;
    debugPrint("AuthMiddleware: User role: $role");

    // If trying to access admin dashboard but not an admin role, redirect to appropriate screen
    if (route == '/admin-dashboard') {
      if (["Admin", "Assignment Editor", "Head of Department"].contains(role)) {
        debugPrint("AuthMiddleware: Allowing access to admin dashboard");
        return null;
      }
      debugPrint("AuthMiddleware: Redirecting non-admin from admin dashboard");
      return const RouteSettings(name: '/home');
    }

    // Handle librarian dashboard access
    if (route == '/librarian-dashboard' && role != 'Librarian') {
      debugPrint("AuthMiddleware: Redirecting non-librarian from librarian dashboard");
      return const RouteSettings(name: '/home');
    }

    // Now role is loaded—allow normal routing
    debugPrint("AuthMiddleware: Allowing normal routing");
    return null;
  }
}
