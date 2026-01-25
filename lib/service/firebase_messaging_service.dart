// service/firebase_messaging_service.dart
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // ✅ Request Notification Permissions
    _requestPermissions();

    // ✅ Initialize notification settings
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleForegroundNotificationTap(response);
      },
    );

    // ✅ Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Note: Background message handler is registered centrally in bootstrap.dart to avoid duplicate registration warnings
    // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // ✅ Handle foreground notification tap
  void _handleForegroundNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final type = data['type'];
        if (type == 'chat_message') {
          final conversationId = data['conversationId'];
          if (conversationId != null) {
            Get.toNamed('/user-chat-list',
                arguments: {'conversationId': conversationId});
          }
        } else if (type == 'task_assigned') {
          final taskId = data['taskId'];
          if (taskId != null) {
            Get.toNamed('/tasks', arguments: {'taskId': taskId});
          }
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  // ✅ Show Notification
  void _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? "New Notification",
      message.notification?.body ?? "You have a new message",
      details,
      payload: jsonEncode(message.data),
    );
  }

  // ✅ Request Permissions for Notifications
  void _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint("Notification Permission: ${settings.authorizationStatus}");
    }
  }
}

// ✅ Background Message Handler (Needs to be a top-level function)
// Removed duplicate background handler to avoid multiple registrations across the app. The single source of truth is in core/bootstrap.dart.
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // Initialize Firebase if it hasn't been initialized yet
//   if (!Firebase.apps.isNotEmpty) {
//     await Firebase.initializeApp();
//   }
//
//   if (kDebugMode) {
//     debugPrint("Handling background message: ${message.messageId}");
//   }
// }
