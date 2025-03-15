// service/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initNotifications() async {
    // Request permissions
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      Get.snackbar("Error", "Notifications are disabled");
      return;
    }

    // Get the FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      if (kDebugMode) {
        print("FCM Token: $token");
      }
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Handle background and terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Get.toNamed("/taskListScreen");
    });
  }

  static void _showLocalNotification(RemoteMessage message) {
    var androidDetails = const AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      importance: Importance.high,
    );
    var platformDetails = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      message.messageId.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
    );
  }
}
