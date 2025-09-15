// utils/snackbar_utils.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/core/bootstrap.dart';

class SnackbarUtils {
  static bool _isAppReady = false;

  /// Mark the app as ready for snackbars
  static void markAppAsReady() {
    _isAppReady = true;
    debugPrint("SnackbarUtils: App marked as ready for snackbars");
  }

  /// Safe snackbar method that checks if app is ready
  static void showSnackbar(String title, String message, {
    SnackPosition? snackPosition,
    Duration? duration,
  }) {
    // Additional safety checks
    if (!_isAppReady) {
      debugPrint("Snackbar skipped - app not ready: $title: $message");
      return;
    }
    
    if (!isBootstrapComplete) {
      debugPrint("Snackbar skipped - bootstrap incomplete: $title: $message");
      return;
    }
    
    if (Get.isSnackbarOpen) {
      debugPrint("Snackbar skipped - snackbar already open: $title: $message");
      return;
    }
    
    // Check if context is available
    if (Get.context == null) {
      debugPrint("Snackbar skipped - context not available: $title: $message");
      return;
    }
    
    // Check if we're in a build phase
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.detached) {
      debugPrint("Snackbar skipped - app detached: $title: $message");
      return;
    }
    
    try {
      Get.snackbar(
        title, 
        message,
        snackPosition: snackPosition ?? SnackPosition.BOTTOM,
        duration: duration ?? const Duration(seconds: 3),
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      debugPrint("Snackbar error: $e - $title: $message");
    }
  }

  /// Show success snackbar
  static void showSuccess(String message) {
    showSnackbar("Success", message);
  }

  /// Show error snackbar
  static void showError(String message) {
    showSnackbar("Error", message);
  }

  /// Show warning snackbar
  static void showWarning(String message) {
    showSnackbar("Warning", message);
  }

  /// Show info snackbar
  static void showInfo(String message) {
    showSnackbar("Info", message);
  }
}