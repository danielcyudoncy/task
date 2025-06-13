// widgets/user_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class UserNavBar extends StatelessWidget {
  final int currentIndex;

  const UserNavBar({super.key, this.currentIndex = 0});

  void _onTap(int index) {
    if (index == 0) {
      Get.offAllNamed('/profile');
    } else if (index == 1) {
      Get.offAllNamed('/all-tasks');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return ConvexAppBar(
      style: TabStyle.react,
      backgroundColor: isLightMode ? Colors.white : Colors.black,
      activeColor: Colors.blue,
      color: Colors.grey,
      elevation: 12,
      initialActiveIndex: currentIndex,
      onTap: _onTap,
      items: const [
        TabItem(icon: Icons.person, title: 'Profile'),
        TabItem(icon: Icons.list, title: 'All Tasks'),
      ],
    );
  }
}
