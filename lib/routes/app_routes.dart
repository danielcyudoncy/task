// routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/routes/global_bindings.dart';
import 'package:task/routes/middleware.dart';
import 'package:task/views/admin_dashboard_screen.dart';
import 'package:task/views/home_screen.dart';
import 'package:task/views/login_screen.dart';
import 'package:task/views/manage_users_screen.dart';
import 'package:task/views/notification_screen.dart';
import 'package:task/views/profile_update_screen.dart';
import 'package:task/views/signup_screen.dart';
import 'package:task/views/splash_screen.dart';
import 'package:task/views/task_assignment_screen.dart';
import 'package:task/views/task_creation_screen.dart';
import 'package:task/views/task_list_screen.dart';

class AppRoutes {
  static final routes = [
    // Public routes (unchanged)
    GetPage(
        name: "/", page: () => const SplashScreen(), binding: GlobalBindings()),
    GetPage(
        name: "/login", page: () => LoginScreen(), binding: GlobalBindings()),
    GetPage(
        name: "/signup", page: () => SignUpScreen(), binding: GlobalBindings()),

    // Start converting protected routes to the new system
    ..._protectedRoutes,


  ];

  static final _protectedRoutes = [
    "/home",
    "/profile-update",
    "/task-creation",
    "/task-list",
    "/task-assignment",
    "/notifications",
    "/admin-dashboard",
    "/manage-users",
  ]
      .map((route) => GetPage(
            name: route,
            page: () => _getPageForRoute(route),
            middlewares: [AuthMiddleware()],
            binding: GlobalBindings(),
          ))
      .toList();

  static Widget _getPageForRoute(String route) {
    switch (route) {
      case "/home":
        return HomeScreen();
      case "/profile-update":
        return const ProfileUpdateScreen();
      case "/task-creation":
        return TaskCreationScreen();
      case "/task-list":
        return TaskListScreen();
      case "/task-assignment":
        return TaskAssignmentScreen();
      case "/notifications":
        return NotificationScreen();
      case "/admin-dashboard":
        return AdminDashboardScreen();
      case "/manage-users":
        return ManageUsersScreen();
      default:
        throw Exception("Route not found");
    }
  }
}
