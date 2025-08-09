// views/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/utils/constants/app_fonts_family.dart';
import 'package:task/utils/devices/app_devices.dart';
import 'package:task/widgets/app_drawer.dart';
import '../controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final AuthController authController = Get.find<AuthController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: colorScheme.primary,
      body: SafeArea(
        child: Obx(() {
          final fullName = authController.fullName.value;
          final profilePicUrl = authController.profilePic.value;
          final phone = authController.phoneNumber.value;
          final email = authController.currentUser?.email ?? '';

          if (authController.currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Top Row: Menu Icon (left) and Settings Icon (right)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Menu Icon (replaced home icon)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.menu,
                            color: colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            // Trigger sound/vibration feedback
                            Get.find<SettingsController>().triggerFeedback();
                            
                            // Open the drawer
                            if (_scaffoldKey.currentState != null) {
                              _scaffoldKey.currentState!.openDrawer();
                            }
                          },
                        ),

                      ),
                      // Settings Icon
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            Get.find<SettingsController>().triggerFeedback();
                            Get.toNamed('/settings');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onPrimary
                          : Colors.white,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: profilePicUrl.isNotEmpty
                        ? Image.network(
                            profilePicUrl,
                            width: 140.w,
                            height: 140.h,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey[300],
                              width: 140.w,
                              height: 140.h,
                              child: Icon(Icons.person,
                                  size: 72, color: Colors.grey[600]),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            width: 140.w,
                            height: 140.h,
                            child: Icon(Icons.person,
                                size: 72, color: Colors.grey[600]),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fullName,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppFontsStyles.raleway,
                    color: colorScheme.onPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 24.h),
                // Card with Info and Profile Actions
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 18.w),
                  padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(28.r),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 24,
                        offset: Offset(0, 9),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact Information
                      Text(
                        'contact_information'.tr,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          AppDevices.copyToClipboard(phone);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Phone number copied to clipboard')),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 19,
                              color: colorScheme.onSurface,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              phone,
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  color: colorScheme.onSurface),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.copy,
                              size: 16,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          AppDevices.copyToClipboard(email);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Email copied to clipboard')),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 19,
                              color: colorScheme.onSurface,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              email,
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  color: colorScheme.onSurface),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.copy,
                              size: 16,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Profile Section
                      Text(
                        'profile'.tr,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface,
                          letterSpacing: 0.2,
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.notifications_none,
                          color: colorScheme.onSurface,
                        ),
                        title: Text("push_notifications".tr,
                            style: TextStyle(
                                color: colorScheme.onSurface)),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurface,
                        ),
                        onTap: () {
                          Get.find<SettingsController>().triggerFeedback();
                          Get.toNamed('/push-notification-settings');
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.person_outline,
                          color: colorScheme.onSurface,
                        ),
                        title: Text("update_profile".tr,
                            style: TextStyle(
                                color: colorScheme.onSurface)),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurface,
                        ),
                        onTap: () {
                          Get.find<SettingsController>().triggerFeedback();
                          Get.toNamed('/profile-update');
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                            shadowColor: Colors.black26,
                          ),
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: Text("log_out".tr,
                              style: const TextStyle(fontSize: 18, color: Colors.white)),
                          onPressed: () {
                            Get.find<SettingsController>().triggerFeedback();
                            authController.logout();
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                            shadowColor: Colors.black26,
                          ),
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.white),
                          label: Text("delete_account".tr,
                              style: const TextStyle(fontSize: 18, color: Colors.white)),
                          onPressed: () async {
                            Get.find<SettingsController>().triggerFeedback();
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('delete_account'.tr),
                                content: Text(
                                    'are_you_sure_you_want_to_delete_your_account'.tr),
                                actions: [
                                  TextButton(
                                    onPressed: () {Get.find<SettingsController>().triggerFeedback();
                                        Navigator.of(context).pop(false);},
                                    child: Text('cancel'.tr),
                                  ),
                                  TextButton(
                                    onPressed: () {Get.find<SettingsController>().triggerFeedback();
                                        Navigator.of(context).pop(true);},
                                    child: Text('delete'.tr,
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              authController.deleteAccount();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }
}
