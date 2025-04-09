// myApp.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/admin_controller.dart';
import 'package:task/routes/app_routes.dart';
import 'package:task/views/splash_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    // ✅ Register the AdminController lazily
    Get.lazyPut(() => AdminController());
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Assignment Logging App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system, // Auto-switch based on system theme
      initialRoute: "/",
      getPages: AppRoutes.routes,
      home: const SplashScreen(), // SplashScreen is the initial screen
    );
  }
}
