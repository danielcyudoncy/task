// utils/devices/app_devices.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppDevices {
  AppDevices._();

  /// Hides the keyboard if open
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Detects if the app is in landscape orientation
  static bool isLandscapeOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Detects if the app is in portrait orientation
  static bool isPortraitOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Returns true if app is in dark theme
  static bool getAppTheme([BuildContext? context]) {
    final ctx = context ?? Get.context;
    if (ctx == null) return false;
    return Theme.of(ctx).brightness == Brightness.dark;
  }

  /// Returns status bar height
  static double getStatusBarHeight([BuildContext? context]) {
    final ctx = context ?? Get.context;
    if (ctx == null) return 0;
    return MediaQuery.of(ctx).padding.top;
  }

  /// Returns total screen height
  static double getScreenHeight([BuildContext? context]) {
    final ctx = context ?? Get.context;
    if (ctx == null) return 0;
    return MediaQuery.of(ctx).size.height;
  }

  /// Returns total screen width
  static double getScreenWidth([BuildContext? context]) {
    final ctx = context ?? Get.context;
    if (ctx == null) return 0;
    return MediaQuery.of(ctx).size.width;
  }

  /// Checks for internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  /// Returns true if the platform is iOS
  static bool isIOS() {
    return Platform.isIOS;
  }

  /// Returns true if the platform is Android
  static bool isAndroid() {
    return Platform.isAndroid;
  }

  /// Launches a URL in the browser
  static void launchUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  /// Detects if device is tablet or not
  static bool isTablet([BuildContext? context]) {
    final ctx = context ?? Get.context;
    if (ctx == null) return false;
    final data = MediaQuery.of(ctx);
    return data.size.shortestSide >= 600;
  }

  /// Gets safe area padding (for notch, etc.)
  static EdgeInsets getSafeAreaInsets([BuildContext? context]) {
    final ctx = context ?? Get.context;
    if (ctx == null) return EdgeInsets.zero;
    return MediaQuery.of(ctx).padding;
  }

  /// Copies a string to the clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar("Copied", "Text copied to clipboard",
        snackPosition: SnackPosition.BOTTOM);
  }
}
