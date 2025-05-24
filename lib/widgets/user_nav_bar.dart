// widgets/user_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserNavBar extends StatelessWidget {
  final int currentIndex;

  const UserNavBar({super.key, this.currentIndex = 0});

  void _onTap(int index) {
    if (index == 0) {
      // Use offAllNamed to avoid stack/navigation issues
      Get.offAllNamed('/profile');
    } else if (index == 1) {
      Get.offAllNamed('/tasks');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: _onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'All Tasks',
        ),
      ],
    );
  }
}
