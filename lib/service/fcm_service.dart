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
      return;
    }

    // ✅ Securely retrieve Firebase Server Key
    final String? serverKey = dotenv.env['FIREBASE_SERVER_KEY'];
    if (serverKey == null || serverKey.isEmpty) {
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
  // ignore: empty_catches
  } catch (e) {
  }
}

/// Send notification when a task is approved or rejected
Future<void> sendTaskApprovalNotification(
    String taskCreatorId, String taskTitle, String approvalStatus, {String? reason}) async {
  try {
    // ✅ Fetch FCM Token from Firestore
    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
        .instance
        .collection("users")
        .doc(taskCreatorId)
        .get();

    final userData = userDoc.data();
    if (userData == null || !userData.containsKey('fcmToken')) {
      if (kDebugMode) {
        print("⚠️ No FCM Token found for user: $taskCreatorId");
      }
      return;
    }
    final String? fcmToken = userData['fcmToken'];

    if (fcmToken == null || fcmToken.isEmpty) {
      return;
    }

    // ✅ Securely retrieve Firebase Server Key
    final String? serverKey = dotenv.env['FIREBASE_SERVER_KEY'];
    if (serverKey == null || serverKey.isEmpty) {
      return;
    }

    // Determine notification content based on approval status
    String notificationTitle;
    String notificationBody;
    String notificationType;
    
    if (approvalStatus.toLowerCase() == 'approved') {
      notificationTitle = "Task Approved";
      notificationBody = "Your task '$taskTitle' has been approved";
      notificationType = "task_approved";
    } else {
      notificationTitle = "Task Rejected";
      notificationBody = "Your task '$taskTitle' has been rejected";
      notificationType = "task_rejected";
    }
    
    if (reason != null && reason.isNotEmpty) {
      notificationBody += ". Reason: $reason";
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
          "title": notificationTitle,
          "body": notificationBody,
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
        print("✅ Task approval notification sent successfully to $taskCreatorId");
      }
    } else {
      if (kDebugMode) {
        print(
          "❌ Failed to send task approval notification: ${response.statusCode} ${response.body}");
      }
    }

    // ✅ Store Notification in Firestore
    await FirebaseFirestore.instance
        .collection("users")
        .doc(taskCreatorId)
        .collection("notifications")
        .add({
      "title": notificationTitle,
      "message": notificationBody,
      "type": notificationType,
      "timestamp": FieldValue.serverTimestamp(),
      "isRead": false,
    });
  // ignore: empty_catches
  } catch (e) {
    if (kDebugMode) {
      print("❌ Error sending task approval notification: $e");
    }
  }
}
