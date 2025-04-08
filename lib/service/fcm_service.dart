// service/fcm_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ For environment variables

Future<void> sendTaskNotification(
    String assignedUserId, String taskTitle) async {
  try {
    // ✅ Fetch FCM Token from Firestore
    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
        .instance
        .collection("users")
        .doc(assignedUserId)
        .get();

    final userData = userDoc.data();
    if (userData == null || !userData.containsKey('fcmToken')) {
      if (kDebugMode) {
        print("⚠️ No FCM Token found for user: $assignedUserId");
      }
      return;
    }
    final String? fcmToken = userData['fcmToken'];

    if (fcmToken == null || fcmToken.isEmpty) {
      print("⚠️ FCM Token is null or empty for user: $assignedUserId");
      return;
    }

    // ✅ Securely retrieve Firebase Server Key
    final String? serverKey = dotenv.env['FIREBASE_SERVER_KEY'];
    if (serverKey == null || serverKey.isEmpty) {
      print(
          "❌ Firebase Server Key not found! Please set FIREBASE_SERVER_KEY in .env file");
      return;
    }

    // ✅ Send Notification via FCM
    final http.Response response = await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "key=$serverKey",
      },
      body: jsonEncode({
        "to": fcmToken,
        "notification": {
          "title": "New Task Assigned",
          "body": "You have been assigned a new task: $taskTitle",
          "sound": "default",
        },
        "android": {
          "priority": "high",
          "notification": {
            "sound": "default",
          },
        },
        "apns": {
          "payload": {
            "aps": {
              "sound": "default",
            },
          },
        },
      }),
    );

    // ✅ Log the Response
    if (response.statusCode == 200) {
      if (kDebugMode) {
        print("✅ Notification sent successfully to $assignedUserId");
      }
    } else {
      if (kDebugMode) {
        print(
          "❌ Failed to send notification: ${response.statusCode} ${response.body}");
      }
    }

    // ✅ Store Notification in Firestore
    await FirebaseFirestore.instance
        .collection("users")
        .doc(assignedUserId)
        .collection("notifications")
        .add({
      "title": "New Task Assigned",
      "message": "You have been assigned a new task: $taskTitle",
      "timestamp": FieldValue.serverTimestamp(),
      "isRead": false,
    });
  } catch (e, stackTrace) {
    print("❌ Error sending notification: $e");
    print(stackTrace);
  }
}
