// views/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import 'package:intl/intl.dart';


class NotificationScreen extends StatelessWidget {
  final NotificationController controller = Get.find();

   NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return const Center(child: Text("No notifications available"));
        }

        return ListView.builder(
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            var notification = controller.notifications[index];
            return ListTile(
              title: Text(notification["title"]),
              subtitle: Text(notification["message"]),
              trailing: Text(
                notification["timestamp"] != null
                    ? DateFormat('dd/MM/yyyy hh:mm a')
                        .format(notification["timestamp"].toDate())
                    : "",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              tileColor:
                  notification["isRead"] ? Colors.grey[200] : Colors.white,
              onTap: () {
                controller.markAsRead(notification["id"]);
                Get.snackbar("Notification", "Marked as read",
                    snackPosition: SnackPosition.BOTTOM);
              },
              onLongPress: () {
                controller.deleteNotification(notification["id"]);
              },
            );
          },
        );
      }),
    );
  }
}
