// routes/middleware.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 0;

  @override
  RouteSettings? redirect(String? route) {
    try {
      final auth = Get.find<AuthController>();
      final args = Get.arguments as Map<String, dynamic>?;

      // skip redirect if logout
      if (args?['fromLogout'] == true) return null;

      // Public routes - ensure login is always accessible
      const publicRoutes = [
        '/',
        '/login',
        '/signup',
        '/forgot-password',
        '/onboarding'
      ];
      if (publicRoutes.contains(route)) {
        return null;
      }

      // Not logged in - check both auth controller and Firebase auth
      if (auth.currentUser == null && auth.auth.currentUser == null) {
        debugPrint("AuthMiddleware: No user logged in, redirecting to login");
        return const RouteSettings(name: '/login');
      }

      // If user is logged in but role is not loaded yet, allow access temporarily
      if (auth.userRole.value.isEmpty && auth.auth.currentUser != null) {
        debugPrint("AuthMiddleware: User logged in but role not loaded yet");
        return null;
      }

      // Check user role and redirect accordingly
      final role = auth.userRole.value;
      debugPrint("AuthMiddleware: User role: $role for route: $route");

      // If trying to access admin dashboard but not an admin role, redirect to appropriate screen
      if (route == '/admin-dashboard') {
        if ([
          "Admin",
          "Assignment Editor",
          "Head of Department",
          "News Director",
          "Assistant News Director",
          "Head of Unit"
        ].contains(role)) {
          debugPrint("AuthMiddleware: Allowing access to admin dashboard");
          return null;
        }
        debugPrint("AuthMiddleware: Redirecting non-admin from admin dashboard");
        return const RouteSettings(name: '/home');
      }

      // Handle librarian dashboard access
      if (route == '/librarian-dashboard' && role != 'Librarian') {
        debugPrint(
            "AuthMiddleware: Redirecting non-librarian from librarian dashboard");
        return const RouteSettings(name: '/home');
      }

      // Now role is loaded—allow normal routing
      debugPrint("AuthMiddleware: Allowing normal routing");
      return null;
    } catch (e) {
      debugPrint("AuthMiddleware: Error in redirect logic: $e");
      // If there's an error in middleware, redirect to login as fallback
      return const RouteSettings(name: '/login');
    }
  }
}
