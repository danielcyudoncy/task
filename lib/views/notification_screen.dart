// views/notification_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/notification_controller.dart';


class NotificationScreen extends StatelessWidget {
  final NotificationController notificationController =
      Get.find<NotificationController>();

  NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Get colors from theme instead of hardcoding
    final backgroundColor = theme.colorScheme.background;
    final cardColor = theme.colorScheme.surfaceVariant;
    final titleColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurface.withOpacity(0.7);
    final timeColor = theme.colorScheme.onSurface.withOpacity(0.5);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications",
            style: TextStyle(fontFamily: 'raleway')),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.iconTheme?.color,
        elevation: 0,
        actions: [
          Obx(() {
            // Add safety check to ensure controller is registered
            if (!Get.isRegistered<NotificationController>()) {
              return const SizedBox();
            }
            
            return notificationController.unreadCount.value > 0
                ? IconButton(
                    icon: const Icon(Icons.mark_email_read),
                    tooltip: "Mark all as read",
                    onPressed: notificationController.markAllAsRead,
                  )
                : const SizedBox();
          }),
        ],
      ),
      backgroundColor: backgroundColor,
      body: Obx(() {
        // Add safety check to ensure controller is registered
        if (!Get.isRegistered<NotificationController>()) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (notificationController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notificationController.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 50, color: subtitleColor),
                SizedBox(height: 16.h),
                Text(
                  "No notifications yet",
                  style: TextStyle(color: subtitleColor, fontSize: 16.sp),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Notifications",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: titleColor,
                    ),
                  ),
                  Obx(() {
                    // Add safety check to ensure controller is registered
                    if (!Get.isRegistered<NotificationController>()) {
                      return Text(
                        "0 Unread",
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    
                    return Text(
                      "${notificationController.unreadCount.value} Unread",
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                itemCount: notificationController.notifications.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final n = notificationController.notifications[index];
                  final isRead = n['isRead'] as bool? ?? true;
                  final timestamp = n['timestamp'] as Timestamp?;
                  final timeText = timestamp != null
                      ? DateFormat('MMM dd, hh:mm a').format(timestamp.toDate())
                      : '';

                  return Dismissible(
                    key: Key(n['id'] ?? UniqueKey().toString()),
                    background: Container(
                      color: theme.colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20.w),
                      child:
                          Icon(Icons.delete, color: theme.colorScheme.onError),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        return await _showDeleteDialog(context, n['id']);
                      }
                      return false;
                    },
                    child: Card(
                      color: isRead ? cardColor : cardColor.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () {
                          if (!isRead) {
                            notificationController.markAsRead(n['id']);
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      n['title'] ?? 'No Title',
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        color: titleColor,
                                        fontWeight: isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isRead)
                                    Icon(Icons.circle,
                                        size: 12.r,
                                        color: theme.colorScheme.primary),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                n['message'] ?? 'No Message',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: subtitleColor,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    timeText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: timeColor,
                                    ),
                                  ),
                                  if (n['type'] != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: _getTypeColor(n['type'], isDark),
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      child: Text(
                                        n['type'].toString().toUpperCase(),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Color _getTypeColor(String? type, bool isDark) {
    switch (type?.toLowerCase()) {
      case 'alert':
        return Colors.redAccent;
      case 'reminder':
        return Colors.orange;
      case 'update':
        return Colors.blue;
      case 'success':
        return Colors.green;
      default:
        return isDark
            ? Theme.of(Get.context!).colorScheme.primary
            : Theme.of(Get.context!).colorScheme.secondary;
    }
  }

  Future<bool> _showDeleteDialog(BuildContext context, String id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Notification"),
        content:
            const Text("Are you sure you want to delete this notification?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              notificationController.deleteNotification(id);
              Navigator.of(ctx).pop(true);
            },
            child: Text(
              "Delete",
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
