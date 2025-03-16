// service/fcm_service.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

Future<void> sendTaskNotification(
    String assignedUserId, String taskTitle) async {
  DocumentSnapshot userDoc = await FirebaseFirestore.instance
      .collection("users")
      .doc(assignedUserId)
      .get();
  String? fcmToken = userDoc["fcmToken"];

  if (fcmToken != null) {
    String serverKey =
        "YOUR_FIREBASE_SERVER_KEY"; // Replace with your server key

    await http.post(
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
          "sound": "default", // 🔊 Enable notification sound
        },
        "android": {
          "notification": {
            "sound": "default",
            "default_vibrate_timings": true, // 📳 Enable vibration
          }
        },
        "apns": {
          "payload": {
            "aps": {"sound": "default"}
          }
        }
      }),
    );
  }

  // Store notification in Firestore
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
}
