// my_app.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task/routes/app_routes.dart';
import 'package:task/utils/themes/app_theme.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/controllers/app_lock_controller.dart';
import 'package:task/views/app_lock_screen.dart';
import 'utils/localization/app_localizations.dart';
import 'utils/localization/translations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Removed Isar import - using SQLite now
import 'package:task/routes/global_bindings.dart';
import 'package:task/views/email_link_signin_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('App lifecycle state changed: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed - preserving state');
        // App is back in foreground, preserve all states
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused - saving state');
        // App is going to background, save state
        break;
      case AppLifecycleState.inactive:
        debugPrint('App inactive - maintaining state');
        // App is temporarily inactive
        break;
      case AppLifecycleState.detached:
        debugPrint('App detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('App hidden - maintaining state');
        break;
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Exit'),
          ),
        ],
      ),
      barrierDismissible: false,
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final ThemeController themeController = Get.find<ThemeController>();
        return Obx(() {
          final currentThemeMode = themeController.isDarkMode.value
              ? ThemeMode.dark
              : ThemeMode.light;
          
          // Check if app is locked
          final AppLockController appLockController = Get.find<AppLockController>();
          if (appLockController.isAppLocked.value) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentThemeMode,
              home: const AppLockScreen(),
            );
          }
          
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              print('PopScope onPopInvoked called: didPop=$didPop');
              if (didPop) return;
              
              // Show confirmation dialog before minimizing/closing
              final shouldExit = await _showExitConfirmationDialog();
              print('Exit confirmation result: $shouldExit');
              if (shouldExit) {
                // On Android, minimize the app instead of closing
                if (Platform.isAndroid) {
                  print('Calling SystemNavigator.pop() on Android');
                  SystemNavigator.pop();
                } else {
                  // On other platforms, close the app
                  print('Calling SystemNavigator.pop() on other platform');
                  SystemNavigator.pop();
                }
              }
            },
            child: GetMaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Assignment Logging App',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentThemeMode,
              initialBinding: GlobalBindings(),
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
              // Handle incoming deep links for email authentication
              unknownRoute: GetPage(
                name: '/unknown',
                page: () => _handleDeepLink(),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _handleDeepLink() {
    final uri = Uri.base;
    final currentUrl = uri.toString();
    
    // Check if this is an email authentication link
    if (currentUrl.contains('__/auth/links') || 
        currentUrl.contains('firebaseapp.com') && currentUrl.contains('link')) {
      
      // Extract the link and navigate to email link signin screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/email-link-signin', arguments: currentUrl);
      });
      
      return const EmailLinkSignInScreen();
    }
    
    // For other unknown routes, redirect to splash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed('/');
    });
    
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
