// views/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // ✅ Import intl package
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Ensure Firestore is imported
import '../controllers/notification_controller.dart';

class NotificationScreen extends StatelessWidget {
  final NotificationController controller = Get.put(NotificationController());

  NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return const Center(
            child: Text(
              "No notifications available",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            var notification = controller.notifications[index];

            // ✅ Fix: Ensure timestamp is properly converted
            Timestamp? timestampData = notification["timestamp"] as Timestamp?;
            DateTime timestamp = timestampData?.toDate() ?? DateTime.now();

            return Dismissible(
              key: Key(notification["id"]),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                controller.deleteNotification(notification["id"]);
              },
              child: ListTile(
                title: Text(notification["title"]),
                subtitle: Text(notification["message"]),
                trailing: Text(
                  DateFormat('dd/MM/yyyy hh:mm a').format(timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                tileColor:
                    (notification["isRead"] ?? false) ? Colors.grey[200] : Colors.white,
                onTap: () {
                  controller.markAsRead(notification["id"]);
                  Get.snackbar("Notification", "Marked as read",
                      snackPosition: SnackPosition.BOTTOM);
                },
              ),
            );
          },
        );
      }),
    );
  }
}
