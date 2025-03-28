// routes/app_routes.dart
import 'package:get/get.dart';
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
import 'package:task/views/manage_users_screen.dart'; // ✅ Added Manage Users Screen

class AppRoutes {
  static final routes = [
    GetPage(name: "/", page: () => const SplashScreen()), // ✅ Default route
    GetPage(name: "/home", page: () => HomeScreen()),
    GetPage(name: "/login", page: () => LoginScreen()),
    GetPage(name: "/signup", page: () => SignUpScreen()),
    GetPage(name: "/profile-update", page: () => const ProfileUpdateScreen()),
    GetPage(name: "/task-creation", page: () => TaskCreationScreen()),
    GetPage(name: "/task-list", page: () => TaskListScreen()),
    GetPage(
        name: "/task-assignment",
        page: () => TaskAssignmentScreen()), // ✅ Fixed route name
    GetPage(name: "/notifications", page: () => NotificationScreen()),
    GetPage(name: "/admin-dashboard", page: () => AdminDashboardScreen()),
    GetPage(
        name: "/manage-users",
        page: () => ManageUsersScreen()), // ✅ Added Manage Users Screen
  ];
}
