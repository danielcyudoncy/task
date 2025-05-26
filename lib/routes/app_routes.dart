// routes/app_routes.dart
import 'package:get/get.dart';
import 'package:task/routes/global_bindings.dart';
import 'package:task/routes/middleware.dart';
import 'package:task/routes/profile_complete_middleware.dart';
import 'package:task/views/admin_dashboard_screen.dart';
import 'package:task/views/all_task_screen.dart';
import 'package:task/views/home_screen.dart';
import 'package:task/views/login_screen.dart';
import 'package:task/views/manage_users_screen.dart';
import 'package:task/views/notification_screen.dart';
import 'package:task/views/profile_screen.dart';
import 'package:task/views/profile_update_screen.dart';
import 'package:task/views/settings_screen.dart';
import 'package:task/views/signup_screen.dart';
import 'package:task/views/splash_screen.dart';
import 'package:task/views/task_assignment_screen.dart';
import 'package:task/views/task_creation_screen.dart';
import 'package:task/views/task_list_screen.dart';
import 'package:task/views/onboarding_screen.dart';

class AppRoutes {
  static final routes = [
    // Public routes
    GetPage(
      name: "/",
      page: () => const SplashScreen(),
      binding: GlobalBindings(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: "/onboarding",
      page: () => const OnboardingScreen(),
      binding: GlobalBindings(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: "/login",
      page: () => LoginScreen(),
      binding: GlobalBindings(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: "/signup",
      page: () => SignUpScreen(),
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    // Protected routes
    GetPage(
      name: "/home",
      page: () => HomeScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: "/profile-update",
      page: () => ProfileUpdateScreen(),
      middlewares: [AuthMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: "/admin-dashboard",
      page: () => const AdminDashboardScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: "/profile",
      page: () => ProfileScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: "/settings",
      page: () => SettingsScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: "/all-tasks",
      page: () => AllTaskScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: "/manage-users",
      page: () => ManageUsersScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: "/tasks",
      page: () => TaskListScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: "/task-assignment",
      page: () => TaskAssignmentScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: "/create-task",
      page: () => TaskCreationScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: "/notifications",
      page: () => NotificationScreen(),
      middlewares: [AuthMiddleware(), ProfileCompleteMiddleware()],
      binding: GlobalBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
    ),
  ];
}
