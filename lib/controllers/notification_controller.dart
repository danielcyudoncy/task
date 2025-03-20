// controllers/notification_controller.dart
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationController extends GetxController {
  var notifications = <Map<String, dynamic>>[].obs;
  var unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  // Fetch notifications in real-time using Firestore stream
  void fetchNotifications() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    notifications.bindStream(
      FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .orderBy("timestamp", descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return {
            "id": doc.id,
            "title": doc["title"] ?? "No Title",
            "message": doc["message"] ?? "No Message",
            "timestamp": doc["timestamp"],
            "isRead": doc["isRead"] ?? false,
          };
        }).toList();
      }),
    );

    updateUnreadCount();
  }

  // Update unread notification count
  void updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !(n["isRead"] ?? true)).length;
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .doc(notificationId)
          .update({"isRead": true});

      updateUnreadCount();
    } catch (e) {
      Get.snackbar("Error", "Failed to mark as read: ${e.toString()}");
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .doc(notificationId)
          .delete();

      Get.snackbar("Success", "Notification deleted");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete: ${e.toString()}");
    }
  }
}
