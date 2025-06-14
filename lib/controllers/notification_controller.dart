// controllers/notification_controller.dart
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationController extends GetxController {
  var notifications = <Map<String, dynamic>>[].obs;
  var unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  // ✅ Fetch notifications in real-time
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
          final data = doc.data(); // <-- SAFELY get the map
          return {
            "id": doc.id,
            "title": data["title"] ?? "No Title",
            "message": data["message"] ?? "No Message",
            "timestamp": data["timestamp"],
            "isRead": data["isRead"] ?? false,
          };
        }).toList();
      }),
    );

    notifications.listen((_) => updateUnreadCount());
  }

  // ... rest of your controller unchanged ...
  void updateUnreadCount() {
    unreadCount.value =
        notifications.where((n) => !(n["isRead"] ?? true)).length;
  }

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

      fetchNotifications();
    } catch (e) {
      Get.snackbar("Error", "Failed to mark as read: ${e.toString()}");
    }
  }

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

      fetchNotifications();
      Get.snackbar("Success", "Notification deleted");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete: ${e.toString()}");
    }
  }

  Future<void> saveTaskNotification({
    required String userId,
    required String taskTitle,
    required String taskDescription,
    required DateTime taskDateTime,
  }) async {
    final formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(taskDateTime);
    final message = 'Description: $taskDescription\nDue: $formattedDate';

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("notifications")
          .add({
        "title": taskTitle,
        "message": message,
        "timestamp": FieldValue.serverTimestamp(),
        "isRead": false,
      });

      fetchNotifications();
    } catch (e) {
      Get.snackbar("Error", "Failed to save notification.");
    }
  }
}
