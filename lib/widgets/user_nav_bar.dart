// widgets/user_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/utils/constants/app_colors.dart';

class UserNavBar extends StatelessWidget {
  // --- MODIFIED: Changed from 'int' to 'int?' to allow null ---
  final int? currentIndex;

  const UserNavBar({super.key, this.currentIndex});

  void _onTap(int index) {
    final settingsController = Get.find<SettingsController>();
    settingsController.triggerFeedback();

    // Prevent navigating to the same page if an index is active
    if (index == currentIndex) return;

    if (index == 0) {
      // Smart Home Navigation
      final AuthController authController = Get.find<AuthController>();
      if (authController.userRole.value == 'Admin') {
        Get.offAllNamed('/admin-dashboard');
      } else {
        Get.offAllNamed('/home');
      }
    } else if (index == 1) {
      Get.offAllNamed('/all-tasks');
    } else if (index == 2) {
      Get.offAllNamed('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return ConvexAppBar(
      style: TabStyle.react,
      backgroundColor: isLightMode ? Colors.white : Colors.black,
      activeColor: AppColors.primaryColor,
      color: Colors.grey,
      elevation: 12,
      // --- This now correctly handles a null value ---
      initialActiveIndex: currentIndex,
      onTap: _onTap,
      items: const [
        TabItem(icon: Icons.home_rounded, title: 'Home'),
        TabItem(icon: Icons.list_alt_rounded, title: 'All Tasks'),
        TabItem(icon: Icons.person_rounded, title: 'Profile'),
      ],
    );
  }
}
