// myApp.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task/routes/app_routes.dart';
import 'package:task/routes/global_bindings.dart';
import 'package:task/service/presence_service.dart';
import 'package:task/utils/themes/app_theme.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/controllers/auth_controller.dart';


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ThemeController themeController = Get.isRegistered<ThemeController>()
      ? Get.find<ThemeController>()
      : Get.put(ThemeController(), permanent: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePresence();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupPresence();
    super.dispose();
  }

  Future<void> _initializePresence() async {
    try {
      if (Get.isRegistered<AuthController>() &&
          Get.isRegistered<PresenceService>()) {
        final auth = Get.find<AuthController>();
        final presence = Get.find<PresenceService>();

        if (auth.isLoggedIn) {
          await presence.setOnline();
        }
      }
    } catch (e) {
      Get.log('Presence initialization error: $e', isError: true);
    }
  }

  Future<void> _cleanupPresence() async {
    try {
      if (Get.isRegistered<PresenceService>()) {
        await Get.find<PresenceService>().setOffline();
      }
    } catch (e) {
      Get.log('Presence cleanup error: $e', isError: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
      case AppLifecycleState.hidden: // New state in Flutter 3.13+
      case AppLifecycleState.detached:
        presence.setOffline();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onInit: () async {
              if (Get.isRegistered<AuthController>()) {
                final auth = Get.find<AuthController>();
                if (auth.isLoggedIn && Get.isRegistered<PresenceService>()) {
                  await Get.find<PresenceService>().setOnline();
                }
              }
            },
          )),
    );
  }
}
