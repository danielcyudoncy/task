// widgets/header_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';

class HeaderWidget extends StatelessWidget {
  final AuthController authController;
  final NotificationController notificationController;

  const HeaderWidget({
    super.key,
    required this.authController,
    required this.notificationController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Menu + Avatar with Notification Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.menu, color: Colors.white, size: 28.sp),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Avatar
                Obx(() => CircleAvatar(
                      radius: 20.sp,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          authController.profilePic.value.isNotEmpty
                              ? NetworkImage(authController.profilePic.value)
                              : null,
                      child: authController.profilePic.value.isEmpty
                          ? Text(
                              authController.fullName.value.isNotEmpty
                                  ? authController.fullName.value[0]
                                      .toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    )),

                // Notification Badge
                Positioned(
                  right: -4,
                  top: -4,
                  child: Obx(
                    () => notificationController.unreadCount.value > 0
                        ? Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 20.w,
                              minHeight: 20.h,
                            ),
                            child: Center(
                              child: Text(
                                notificationController.unreadCount.value > 9
                                    ? '9+'
                                    : '${notificationController.unreadCount.value}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : SizedBox(),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Greeting and Email
        Padding(
          padding: EdgeInsets.only(left: 16.w, top: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, ${authController.fullName.value}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Raleway',
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                authController.currentUser?.email ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14.sp,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
