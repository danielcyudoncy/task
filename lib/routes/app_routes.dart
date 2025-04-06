import 'package:get/get.dart';
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
// Import the middleware

class AppRoutes {
  static final routes = [
    GetPage(name: "/", page: () => const SplashScreen()),
    GetPage(name: "/login", page: () => LoginScreen()),
    GetPage(name: "/signup", page: () => SignUpScreen()),
    
    // Protected routes with auth middleware
    GetPage(
      name: "/home", 
      page: () => HomeScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/profile-update", 
      page: () => const ProfileUpdateScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/task-creation", 
      page: () => TaskCreationScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/task-list", 
      page: () => TaskListScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/task-assignment",
      page: () => TaskAssignmentScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/notifications", 
      page: () => NotificationScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/admin-dashboard", 
      page: () => AdminDashboardScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/manage-users",
      page: () => ManageUsersScreen(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
