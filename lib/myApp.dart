// myApp.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/routes/app_routes.dart';
import 'package:task/routes/global_bindings.dart';
import 'package:task/utils/themes/app_theme.dart';
import 'package:task/controllers/theme_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.put if not already initialized elsewhere to avoid "not found" error.
    final ThemeController themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController(), permanent: true);

    return Obx(() => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Assignment Logging App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          // Always start in light mode unless user toggles to dark
          themeMode: themeController.isDarkMode.value
              ? ThemeMode.dark
              : ThemeMode.light,
          initialBinding: GlobalBindings(),
          initialRoute: "/",
          getPages: AppRoutes.routes,
        ));
  }
}
