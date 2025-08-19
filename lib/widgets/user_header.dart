// widgets/user_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';

class UserHeader extends StatelessWidget {
  final bool isDark;
  final GlobalKey<ScaffoldState> scaffoldKey;

  UserHeader({super.key, required this.isDark, required this.scaffoldKey});

  final AuthController authController = Get.find<AuthController>();
  final NotificationController notificationController =
      Get.find<NotificationController>();

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w, 
        vertical: isPortrait ? 16.h : 8.h,
      ),
      child: Column(
        children: [
          /// Top Row: Menu + Avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.menu, 
                  color: Colors.white, 
                  size: isPortrait ? 28.sp : 24.sp,
                ),
                onPressed: () {
                  if (scaffoldKey.currentState != null) {
                    scaffoldKey.currentState!.openDrawer();
                  }
                },
              ),
              GestureDetector(
                onTap: () {
                  Get.find<SettingsController>().triggerFeedback();
                  Get.toNamed('/notifications');
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Obx(() {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: isPortrait ? 20.sp : 16.sp,
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: isPortrait ? 20.sp : 16.sp,
                                      fontFamily: 'Raleway',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Obx(() {
                          final count =
                              notificationController.unreadCount.value;
                          return count > 0
                              ? Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 20.w,
                                    minHeight: 20.h,
                                  ),
                                  child: Center(
                                    child: Text(
                                      count > 9 ? '9+' : '$count',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox();
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          /// Greeting Row
          Padding(
            padding: EdgeInsets.only(
              left: 8.w, 
              top: isPortrait ? 8.h : 4.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Center(
                  child: Text(
                        "${'hello'.tr}, ${authController.fullName.value}!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isPortrait ? 22.sp : 18.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Raleway',
                        ),
                      ),
                )),
                SizedBox(height: isPortrait ? 4.h : 2.h),
                Obx(() => Center(
                  child: Text(
                        authController.currentUser?.email ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isPortrait ? 16.sp : 14.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
