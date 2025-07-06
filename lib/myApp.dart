// myApp.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task/routes/app_routes.dart';
import 'package:task/service/presence_service.dart';
import 'package:task/utils/themes/app_theme.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/utils/snackbar_utils.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Finding the controller is fine, as it's already put by bootstrap.
  final ThemeController themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    debugPrint("📱 MYAPP: initState called");
    WidgetsBinding.instance.addObserver(this);
    debugPrint("📱 MYAPP: WidgetsBinding observer added");
    
    // Mark the app as ready for snackbars immediately
    SnackbarUtils.markAppAsReady();
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().markAppAsReady();
    }
    debugPrint("📱 MYAPP: App marked as ready for snackbars");
    
    // Also mark as ready after first frame for extra safety
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SnackbarUtils.markAppAsReady();
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().markAppAsReady();
      }
      debugPrint("📱 MYAPP: App marked as ready for snackbars (post-frame)");
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // REMOVED: _cleanupPresence() can also be removed for simplicity,
    // as AppLifecycleState handles going offline.
    super.dispose();
  }

  // REMOVED: The _initializePresence and _cleanupPresence methods are no longer needed.

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // This part is for handling when the app goes to the background/foreground,
    // so it should stay.
    if (!Get.isRegistered<AuthController>() ||
        !Get.isRegistered<PresenceService>()) {
      return;
    }

    final auth = Get.find<AuthController>();
    final presence = Get.find<PresenceService>();

    if (!auth.isLoggedIn) return;

    switch (state) {
      case AppLifecycleState.resumed:
        presence.setOnline();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        presence.setOffline();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("📱 MYAPP: build called");
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        debugPrint("📱 MYAPP: ScreenUtilInit builder called");
        return Obx(() {
          final currentThemeMode = themeController.isDarkMode.value
              ? ThemeMode.dark
              : ThemeMode.light;
          debugPrint("📱 MYAPP: Current theme mode: ${currentThemeMode.name}");
          
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Assignment Logging App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentThemeMode,
            // REMOVED: initialBinding and onInit are no longer needed.
            initialRoute: "/",
            getPages: AppRoutes.routes,
          );
        });
      },
    );
  }
}
