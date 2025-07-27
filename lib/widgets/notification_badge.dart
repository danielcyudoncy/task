// widgets/notification_badge.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController notificationController = Get.find<NotificationController>();
    return Obx(() {
      final unreadCount = notificationController.validUnreadCount.value;
      final hasUnread = unreadCount > 0;
      return Stack(
        children: [
          const Icon(Icons.notifications),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 16.w,
                height: 16.h,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
