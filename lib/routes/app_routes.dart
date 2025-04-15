// routes/app_routes.dart
import 'package:get/get.dart';
import 'package:task/routes/global_bindings.dart';
import 'package:task/routes/middleware.dart';
import 'package:task/views/admin_dashboard_screen.dart';
import 'package:task/views/home_screen.dart';
import 'package:task/views/login_screen.dart';
import 'package:task/views/notification_screen.dart';
import 'package:task/views/profile_update_screen.dart';
import 'package:task/views/signup_screen.dart';
import 'package:task/views/task_assignment_screen.dart';
import 'package:task/views/task_creation_screen.dart';
import 'package:task/views/task_list_screen.dart';
import 'package:task/views/splash_screen.dart';
import 'package:task/views/manage_users_screen.dart';

class AppRoutes {
  static final routes = [
    GetPage(
      name: "/",
      page: () => const SplashScreen(),
      binding: GlobalBindings(),
    ),
    GetPage(
      name: "/login",
      page: () => LoginScreen(),
      binding: GlobalBindings(),
    ),
    GetPage(
      name: "/signup",
      page: () => SignUpScreen(),
      binding: GlobalBindings(),
    ),
    GetPage(
      name: "/home",
      page: () => HomeScreen(),
      middlewares: [AuthMiddleware()],
      binding: GlobalBindings(),
    ),
    GetPage(
      name: "/profile-update",
      page: () => const ProfileUpdateScreen(),
      middlewares: [AuthMiddleware()],
      binding: GlobalBindings(),
    ),
    GetPage(
      name: "/task-creation",
      page: () => TaskCreationScreen(),
      middlewares: [AuthMiddleware()],
      binding: GlobalBindings(),
    ),
    GetPage(
      name: "/task-list",
      page: () => TaskListScreen(),
      middlewares: [AuthMiddleware()],
      binding: GlobalBindings(),
    ),
    GetPage(
      name: "/task-assignment",
      page: () => TaskAssignmentScreen(),
      middlewares: [AuthMiddleware()],
      binding: GlobalBindings(),
    ),
    GetPage(
      name: "/notifications",
      page: () => NotificationScreen(),
      middlewares: [AuthMiddleware()],
      binding: GlobalBindings(),
    ),
    GetPage(
      name: "/admin-dashboard",
      page: () => AdminDashboardScreen(),
      middlewares: [AuthMiddleware()],
      binding: GlobalBindings(),
    ),
    GetPage(
      name: "/manage-users",
      page: () => ManageUsersScreen(),
      middlewares: [AuthMiddleware()],
      binding: GlobalBindings(),
    ),
  ];
}
