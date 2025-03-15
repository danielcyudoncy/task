// routes/app_routes.dart
import 'package:get/get.dart';
import 'package:task/views/profile_update_screen.dart';
import 'package:task/views/signup_screen.dart';
import 'package:task/views/task_assignment_screen.dart';

class AppRoutes {
  static final routes = [
    GetPage(name: "/signup", page: () => SignUpScreen()),
    GetPage(name: "/assignTask", page: () => TaskAssignmentScreen()),
    GetPage(name: "/profile-update", page: () => const ProfileUpdateScreen()),
  ];
}
