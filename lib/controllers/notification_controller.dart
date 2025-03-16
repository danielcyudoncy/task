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

  void fetchNotifications() {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .listen((snapshot) {
      notifications.value = snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "title": doc["title"],
          "message": doc["message"],
          "timestamp": doc["timestamp"],
          "isRead": doc["isRead"],
        };
      }).toList();

      // Count unread notifications
      unreadCount.value = notifications.where((n) => !n["isRead"]).length;
    });
  }

  void markAsRead(String notificationId) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .doc(notificationId)
        .update({"isRead": true});
  }

  void deleteNotification(String notificationId) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .doc(notificationId)
        .delete();
  }
}
