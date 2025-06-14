// views/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../utils/constants/app_colors.dart';
import '../utils/constants/app_styles.dart';

class NotificationScreen extends StatelessWidget {
  final NotificationController notificationController =
      Get.find<NotificationController>();

  NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final cardColor = isDark ? const Color(0xFF24243e) : const  Color(0xFF007AFF);
    final titleColor = isDark ? Colors.white : Colors.white;
    final subtitleColor = isDark ? Colors.white70 : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor:
            isDark ? AppColors.primaryColor : AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: backgroundColor,
      body: Obx(() {
        final notifications = notificationController.notifications;
        if (notifications.isEmpty) {
          return Center(
            child: Text(
              "No notifications.",
              style: TextStyle(color: subtitleColor),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final n = notifications[index];
            return Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 7),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                leading: Icon(
                  n['isRead']
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: n['isRead']
                      ? (isDark ? Colors.white54 : Colors.grey)
                      : (isDark
                          ? AppColors.primaryColor
                          : AppColors.primaryColor),
                  size: 28,
                ),
                title: Text(
                  n['title'] ?? '',
                  style: AppStyles.cardTitleStyle.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  n['message'] ?? '',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 14.sp,
                  ),
                ),
                trailing: !n['isRead']
                    ? IconButton(
                        icon: Icon(Icons.mark_email_read,
                            color: isDark ? Colors.greenAccent : Colors.green),
                        tooltip: "Mark as read",
                        onPressed: () =>
                            notificationController.markAsRead(n['id']),
                      )
                    : null,
                onLongPress: () => _showDeleteDialog(context, n['id']),
              ),
            );
          },
        );
      }),
    );
  }

  void _showDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Notification"),
        content:
            const Text("Are you sure you want to delete this notification?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              notificationController.deleteNotification(id);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
