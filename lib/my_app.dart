// my_app.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task/routes/app_routes.dart';
import 'package:task/service/presence_service.dart';
import 'package:task/utils/themes/app_theme.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/utils/snackbar_utils.dart';
import 'utils/localization/app_localizations.dart';
import 'utils/localization/translations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Finding the controller is fine, as it's already put by bootstrap.
  final ThemeController themeController = Get.find<ThemeController>();
  
  // For double-tap back button to exit
  DateTime? _lastBackPressTime;

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

  // Handle back button press
  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null || 
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      
      // Show snackbar asking user to press back again
      Get.snackbar(
        'Press back again to exit',
        'Tap the back button once more to close the app',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(8),
        borderRadius: 8,
        icon: const Icon(Icons.info_outline, color: Colors.white),
      );
      
      return false; // Don't exit
    }
    
    return true; // Exit the app
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
          debugPrint("📱 MYAPP: Current theme mode:  [1m");
          
          return PopScope(
            canPop: true,
            onPopInvoked: (didPop) async {
              if (!didPop) {
                final now = DateTime.now();
                if (_lastBackPressTime == null ||
                    now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
                  _lastBackPressTime = now;
                  // Show snackbar asking user to press back again
                  Get.snackbar(
                    'Press back again to exit',
                    'Tap the back button once more to close the app',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.black87,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(8),
                    borderRadius: 8,
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                  );
                  // Prevent pop
                  return;
                }
                // Allow pop
                Navigator.of(context).maybePop();
              }
            },
            child: GetMaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Assignment Logging App',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentThemeMode,
              initialRoute: "/",
              getPages: AppRoutes.routes,
              translations: AppTranslations(),
              locale: AppLocalizations.instance.currentLocale,
              fallbackLocale: AppLocalizations.defaultLocale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
          );
        });
      },
    );
  }
}
