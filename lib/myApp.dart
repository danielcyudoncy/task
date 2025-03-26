// myApp.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/routes/app_routes.dart';
import 'package:task/views/splash_screen.dart';
import 'package:task/views/home_screen.dart';
import 'package:task/views/task_list_screen.dart';
import 'package:task/views/task_assignment_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Assignment Logging App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system, // ✅ Auto-switch based on system theme
      initialRoute: "/",
      getPages: AppRoutes.routes,
      home: _getInitialScreen(),
    );
  }

  // ✅ Determines the first screen based on user role
  Widget _getInitialScreen() {
    final AuthController authController = Get.find<AuthController>();

    if (authController.auth.currentUser == null) {
      return const SplashScreen(); // ✅ Not logged in
    }

    String role = authController.userRole.value;

    if (role == "Reporter" || role == "Cameraman") {
      return  TaskListScreen(); // ✅ Redirect to their tasks
    } else if (role == "Admin" || role == "Assignment Editor" || role == "Head of Department") {
      return  TaskAssignmentScreen(); // ✅ Redirect to task management
    }

    return  HomeScreen(); // ✅ Default fallback
  }}
