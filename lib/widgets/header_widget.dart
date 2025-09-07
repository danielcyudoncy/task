// widgets/header_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Added import
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

  // Validate if the URL is a valid HTTP/HTTPS URL
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

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
                Obx(() {
                  final profilePic = authController.profilePic.value;
                  final fullName = authController.fullName.value;
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 40.sp, // 2 * radius for consistent sizing
                        height: 40.sp,
                        child: profilePic.isNotEmpty && _isValidUrl(profilePic)
                            ? CachedNetworkImage(
                                imageUrl: profilePic,
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    _buildInitialsAvatar(
                                  context,
                                  fullName,
                                ),
                                imageBuilder: (context, imageProvider) =>
                                    CircleAvatar(
                                  radius: 20.sp,
                                  backgroundImage: imageProvider,
                                  backgroundColor: Colors.white,
                                ),
                              )
                            : _buildInitialsAvatar(context, fullName),
                      ),
                    ),
                  );
                }),
                // Notification Badge
                Positioned(
                  right: -4,
                  top: -4,
                  child: Obx(
                    () => notificationController.unreadCount.value > 0
                        ? Container(
                            padding: const EdgeInsets.all(4),
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
                        : const SizedBox(),
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
                "${'hello'.tr}, ${authController.fullName.value}!",
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
                  color: Theme.of(context).colorScheme.primary.withAlpha(153),
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

  // Helper for initials fallback
  Widget _buildInitialsAvatar(BuildContext context, String fullName) {
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 20.sp,
      backgroundColor: Colors.white,
      child: Text(
        initial,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
