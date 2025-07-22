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
import 'package:isar/isar.dart';
import 'package:task/routes/global_bindings.dart';

class MyApp extends StatelessWidget {
  final Isar isar;
  const MyApp({Key? key, required this.isar}) : super(key: key);

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
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Assignment Logging App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentThemeMode,
            initialBinding: GlobalBindings(isar),
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
          );
        });
      },
    );
  }
}
