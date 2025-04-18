// myApp.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/routes/app_routes.dart';
import 'package:task/routes/global_bindings.dart';
import 'package:task/utils/themes/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Assignment Logging App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Auto-switch based on system theme
      initialBinding: GlobalBindings(), // ✅ Apply GlobalBindings here
      initialRoute: "/", // Define the initial route
      getPages: AppRoutes.routes, // Define all routes
    );
  }
}
