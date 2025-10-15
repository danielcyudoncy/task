// service/fcm_helper.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Helper service for Firebase Cloud Messaging operations
class FCMHelper {
  /// Get FCM token with proper error handling and permissions
  static Future<String?> getFCMToken() async {
    if (kIsWeb) {
      return null; // FCM not available on web
    }

    try {
      // Request permissions first
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await FirebaseMessaging.instance.getToken();
        if (kDebugMode && token != null) {
          debugPrint("✅ FCM Token obtained: ${token.substring(0, 10)}***");
        }
        return token;
      } else {
        if (kDebugMode) {
          debugPrint(
              "⚠️ Notification permissions not granted: ${settings.authorizationStatus}");
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Error getting FCM Token: $e");
      }
      return null;
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;

    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Error checking notification settings: $e");
      }
      return false;
    }
  }

  /// Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    if (kIsWeb) return false;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (kDebugMode) {
        debugPrint(isAuthorized
            ? "✅ Notification permissions granted"
            : "⚠️ Notification permissions not granted: ${settings.authorizationStatus}");
      }

      return isAuthorized;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Error requesting notification permissions: $e");
      }
      return false;
    }
  }
}
