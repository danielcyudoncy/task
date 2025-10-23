// my_app.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:task/routes/app_routes.dart';
import 'package:task/utils/themes/app_theme.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/controllers/app_lock_controller.dart';
import 'package:task/screens/app_lock_screen.dart';
import 'utils/localization/app_localizations.dart';
import 'utils/localization/translations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Removed Isar import - using SQLite now
import 'package:task/routes/global_bindings.dart';
import 'package:task/widgets/error_boundary.dart';

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
    _setOrientation();
    
    // Remove splash screen after initialization
    FlutterNativeSplash.remove();
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
    return await showDialog(
          context: Get.context!,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get current orientation to set appropriate design size
        final orientation = MediaQuery.of(context).orientation;
        final designSize = orientation == Orientation.portrait
            ? const Size(375, 812) // Portrait design size
            : const Size(812, 375); // Landscape design size

        return ScreenUtilInit(
          designSize: designSize,
          minTextAdapt: true,
          splitScreenMode: true,
          useInheritedMediaQuery: true,
          ensureScreenSize: true,
          builder: (context, child) {
            return ErrorBoundary(
              onError: () {
                debugPrint(
                    'Error boundary triggered - reporting to Crashlytics');
              },
              child: Builder(
                builder: (context) {
                  final ThemeController themeController =
                      Get.find<ThemeController>();

                  return Obx(() {
                    try {
                      final currentThemeMode = themeController.isDarkMode.value
                          ? ThemeMode.dark
                          : ThemeMode.light;

                      final AppLockController appLockController =
                          Get.find<AppLockController>();

                      return PopScope(
                        canPop: false,
                        onPopInvokedWithResult: (didPop, result) async {
                          if (didPop) return;
                          final shouldExit =
                              await _showExitConfirmationDialog();
                          if (shouldExit) {
                            SystemNavigator.pop();
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
                          home: appLockController.isAppLocked.value
                              ? const AppLockScreen()
                              : null,
                          builder: (context, widget) {
                            return widget!;
                          },
                        ),
                      );
                    } catch (e, stack) {
                      debugPrint('Error in app initialization: $e');
                      debugPrint('Stack trace: $stack');

                      // Error already handled by ErrorWidget.builder in ErrorBoundary

                      return MaterialApp(
                        home: Scaffold(
                          body: Center(
                            child: Text('Error initializing app: $e'),
                          ),
                        ),
                      );
                    }
                  });
                },
              ),
            );
          },
        );
      },
    );
  }
}
