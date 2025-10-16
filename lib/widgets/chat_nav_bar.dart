// widgets/chat_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:task/utils/constants/app_colors.dart';

class ChatNavBar extends StatelessWidget {
  final int currentIndex;

  const ChatNavBar({super.key, this.currentIndex = 0});

  void _onTap(int index) {
    if (index == 0) {
      Get.offAllNamed('/all-users-chat');
    } else if (index == 1) {
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
      initialActiveIndex: currentIndex,
      onTap: _onTap,
      items: const [
        TabItem(icon: Icons.chat, title: 'Chats'),
        TabItem(icon: Icons.person, title: 'Profile'),
      ],
    );
  }
}
