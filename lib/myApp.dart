// myApp.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/routes/app_routes.dart';
import 'package:task/routes/global_bindings.dart';
import 'package:task/utils/themes/app_theme.dart';
import 'package:task/controllers/settings_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Don't call Get.find here!
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Assignment Logging App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Use system by default, will update in Home
      initialBinding: GlobalBindings(),
      initialRoute: "/",
      getPages: AppRoutes.routes,
      builder: (context, child) {
        // Now it's safe to use Get.find, because bindings have been initialized
        final SettingsController settingsController =
            Get.find<SettingsController>();
        return Obx(() => MaterialApp(
              home: child,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: settingsController.isDarkMode.value
                  ? ThemeMode.dark
                  : ThemeMode.light,
              debugShowCheckedModeBanner: false,
            ));
      },
    );
  }
}
