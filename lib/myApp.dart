// myApp.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/routes/app_routes.dart';
import 'package:task/routes/global_bindings.dart';
import 'package:task/utils/themes/app_theme.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController(), permanent: true);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => Obx(() => GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Assignment Logging App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.isDarkMode.value
                ? ThemeMode.dark
                : ThemeMode.light,
            initialBinding: GlobalBindings(),
            initialRoute: "/",
            getPages: AppRoutes.routes,
            // REMOVE the builder here!
          )),
    );
  }
}
