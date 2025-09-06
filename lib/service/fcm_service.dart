// service/fcm_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart';

/// Get OAuth2 access token for FCM HTTP v1 API
Future<String?> _getAccessToken() async {
  try {
    // Load service account JSON from assets
    final serviceAccountJson = await rootBundle.loadString('assets/service-account.json');
    final serviceAccount = auth.ServiceAccountCredentials.fromJson(json.decode(serviceAccountJson));
    
    // Define FCM scope
    const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    
    // Get access token
    final client = await auth.clientViaServiceAccount(serviceAccount, scopes);
    final accessToken = client.credentials.accessToken.data;
    client.close();
    
    return accessToken;
} catch (e) {
    if (kDebugMode) {
      print('❌ Error getting access token: $e');
    }
    return null;
  }
}

/// Get Firebase project ID from environment
String? _getProjectId() {
  return dotenv.env['FIREBASE_PROJECT_ID'];
}

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

    // ✅ Get OAuth2 access token and project ID
    final String? accessToken = await _getAccessToken();
    final String? projectId = _getProjectId();
    
if (accessToken == null || projectId == null) {
      if (kDebugMode) {
        print("❌ Missing access token or project ID");
      }
      return;
    }

    // ✅ Send Notification via FCM HTTP v1 API
    final http.Response response = await http.post(
      Uri.parse("https://fcm.googleapis.com/v1/projects/$projectId/messages:send"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "message": {
          "token": fcmToken,
          "notification": {
            "title": "New Task Assigned",
            "body": "You have been assigned a new task: $taskTitle",
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
        }
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

/// Send notification to admin users when a reporter submits completion info
Future<void> sendReportCompletionNotification(
    String taskId, String taskTitle, String reporterName, String additionalComments) async {
  try {
    // Get all admin users
    final adminUsersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', whereIn: ['Admin', 'Assignment Editor', 'Head of Department', 'Head of Unit'])
        .get();

    for (final adminDoc in adminUsersSnapshot.docs) {
      final adminData = adminDoc.data();
      final adminId = adminDoc.id;
      final fcmToken = adminData['fcmToken'] as String?;

if (fcmToken == null || fcmToken.isEmpty) {
        if (kDebugMode) {
          print("⚠️ No FCM Token found for admin user: $adminId");
        }
        continue;
      }

      // Get OAuth2 access token and project ID
      final String? accessToken = await _getAccessToken();
      final String? projectId = _getProjectId();
      
if (accessToken == null || projectId == null) {
        if (kDebugMode) {
          print("❌ Missing access token or project ID");
        }
        continue;
      }

      final notificationTitle = "Task Completion Report";
      final notificationBody = "$reporterName has submitted completion details for '$taskTitle'";
      
      // Send Notification via FCM HTTP v1 API
      final http.Response response = await http.post(
        Uri.parse("https://fcm.googleapis.com/v1/projects/$projectId/messages:send"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode({
          "message": {
            "token": fcmToken,
            "notification": {
              "title": notificationTitle,
              "body": notificationBody,
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
          }
        }),
      );

      // Log the Response
if (response.statusCode == 200) {
          if (kDebugMode) {
            print("✅ Report completion notification sent successfully to admin $adminId");
          }
        } else {
          if (kDebugMode) {
            print(
                "❌ Failed to send report completion notification to admin $adminId: ${response.statusCode} ${response.body}");
          }
        }

      // Store Notification in Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(adminId)
          .collection("notifications")
          .add({
        "title": notificationTitle,
        "message": notificationBody,
        "type": "report_completion",
        "taskId": taskId,
        "reporterName": reporterName,
        "comments": additionalComments,
        "timestamp": FieldValue.serverTimestamp(),
        "isRead": false,
      });
    }
} catch (e) {
    if (kDebugMode) {
      print("❌ Error sending report completion notification: $e");
    }
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

    // ✅ Get OAuth2 access token and project ID
    final String? accessToken = await _getAccessToken();
    final String? projectId = _getProjectId();
    
if (accessToken == null || projectId == null) {
      if (kDebugMode) {
        print("❌ Missing access token or project ID");
      }
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

    // ✅ Send Notification via FCM HTTP v1 API
    final http.Response response = await http.post(
      Uri.parse("https://fcm.googleapis.com/v1/projects/$projectId/messages:send"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "message": {
          "token": fcmToken,
          "notification": {
            "title": notificationTitle,
            "body": notificationBody,
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
        }
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
