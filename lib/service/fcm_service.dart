// service/fcm_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ Securely load environment variables

Future<void> sendTaskNotification(String assignedUserId, String taskTitle) async {
  try {
    // ✅ Fetch FCM Token from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(assignedUserId)
        .get();
    String? fcmToken = userDoc["fcmToken"];

    if (fcmToken == null) {
      print("⚠️ No FCM Token found for user: $assignedUserId");
      return;
    }

    // ✅ Securely retrieve Firebase Server Key
    String? serverKey = dotenv.env["FIREBASE_SERVER_KEY"];
    if (serverKey == null) {
      print("❌ Firebase Server Key not found! Set it in .env");
      return;
    }

    // ✅ Send Notification via FCM
    http.Response response = await http.post(
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
          "notification": {
            "sound": "default",
            "default_vibrate_timings": true,
          }
        },
        "apns": {
          "payload": {
            "aps": {"sound": "default"}
          }
        }
      }),
    );

    // ✅ Log Response
    if (response.statusCode == 200) {
      print("✅ Notification sent successfully to $assignedUserId");
    } else {
      print("❌ Failed to send notification: ${response.body}");
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
  } catch (e) {
    print("❌ Error sending notification: $e");
  }
}
