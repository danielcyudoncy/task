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
    final backgroundColor = theme.colorScheme.surface;
    final cardColor = theme.colorScheme.surfaceContainerHighest;
    final subtitleColor = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title:
            Text("notifications".tr, style: TextStyle(fontFamily: 'raleway')),
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
                    tooltip: "mark_all_as_read".tr,
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

        return Obx(
          () {
            final allNotifications = notificationController.notifications;

            // Debug information
            debugPrint(
                'NotificationScreen: Total notifications: ${allNotifications.length}');
            debugPrint(
                'NotificationScreen: Total unread count: ${notificationController.unreadCount.value}');

            if (allNotifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off,
                        size: 50,
                        color: isDark ? Colors.white70 : Colors.grey.shade600),
                    SizedBox(height: 16.h),
                    Text(
                      "no_notifications_yet".tr,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16.sp),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "total".tr,
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                          fontSize: 12.sp),
                    ),
                    if (allNotifications.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        "first_notification_type".tr,
                        style: TextStyle(color: subtitleColor, fontSize: 12.sp),
                      ),
                    ],
                  ],
                ),
              );
            }
            return Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "recent_notifications".tr,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Obx(() {
                          if (!Get.isRegistered<NotificationController>()) {
                            return Text(
                              "0 unread".tr,
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          return Text(
                            "${notificationController.unreadCount.value} unread"
                                .tr,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    itemCount: allNotifications.length,
                    separatorBuilder: (context, index) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final n = allNotifications[index];
                      final isRead = n['isRead'] as bool? ?? true;
                      final timestamp = n['timestamp'] as Timestamp?;
                      final timeText = timestamp != null
                          ? DateFormat('MMM dd, hh:mm a')
                              .format(timestamp.toDate())
                          : '';

                      return Dismissible(
                        key: Key(n['id'] ?? UniqueKey().toString()),
                        background: Container(
                          color: theme.colorScheme.error,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20.w),
                          child: Icon(Icons.delete,
                              color: theme.colorScheme.onError),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            return await _showDeleteDialog(context, n['id']);
                          }
                          return false;
                        },
                        child: Card(
                          color: isRead
                              ? cardColor
                              : cardColor.withValues(alpha: 0.8),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n['title'] ?? 'No Title',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: 16.sp,
                                            fontWeight: isRead
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!isRead)
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 8.w),
                                              child: Icon(Icons.circle,
                                                  size: 12.r,
                                                  color: theme
                                                      .colorScheme.primary),
                                            ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              size: 16.r,
                                              color: isDark
                                                  ? Colors.red.shade300
                                                  : Colors.red.shade600,
                                            ),
                                            onPressed: () async {
                                              final shouldDelete =
                                                  await _showDeleteDialog(
                                                      context, n['id']);
                                              if (shouldDelete) {
                                                notificationController
                                                    .deleteNotification(
                                                        n['id']);
                                              }
                                            },
                                            tooltip: "delete_notification".tr,
                                            padding: EdgeInsets.all(2.w),
                                            constraints: BoxConstraints(
                                              minWidth: 20.w,
                                              minHeight: 20.h,
                                              maxWidth: 28.w,
                                              maxHeight: 28.h,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    n['message'] ?? 'No Message',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey.shade600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          timeText,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.grey.shade500,
                                            fontSize: 12.sp,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (n['type'] != null) ...[
                                        SizedBox(width: 8.w),
                                        Flexible(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8.w, vertical: 4.h),
                                            decoration: BoxDecoration(
                                              color: _getTypeColor(
                                                  n['type'], isDark),
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                            ),
                                            child: Text(
                                              n['type']
                                                  .toString()
                                                  .toUpperCase(),
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
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
          },
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: Theme.of(ctx).colorScheme.error,
              size: 24.r,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                "delete_notification".tr,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete this notification? This action cannot be undone.",
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              "cancel".tr,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              "delete".tr,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
    );
    return result ?? false;
  }
}
