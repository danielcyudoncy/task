// widgets/user_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/utils/constants/app_colors.dart';


class UserNavBar extends StatelessWidget {
  final int currentIndex;
  final AuthController _authController = Get.find<AuthController>();

  UserNavBar({super.key, this.currentIndex = 0});

  void _onTap(int index) {
    // Adjust index based on available tabs
    final availableTabs = _getAvailableTabs();
    if (index < availableTabs.length) {
      final route = availableTabs[index]['route'];
      Get.toNamed(route);
    }
  }

  List<Map<String, dynamic>> _getAvailableTabs() {
    final role = _authController.userRole.value.toString().trim();
    
    final tabs = [
      {'icon': Icons.person, 'title': 'Profile', 'route': '/profile'},
      {'icon': Icons.list, 'title': 'Tasks', 'route': '/all-tasks'},
    ];

    // Add Performance tab only for specific roles
    final allowedRoles = [
      'Admin',
      'Assignment Editor',
      'Head of Department',
      'Head of Unit',
      'News Director',
      'Assistant News Director'
    ];
    final shouldShowPerformanceTab = allowedRoles.contains(role);

    if (shouldShowPerformanceTab) {
      tabs.add({
        'icon': Icons.assessment,
        'title': 'Performance',
        'route': '/performance'
      });
    }

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final availableTabs = _getAvailableTabs();

    // Adjust the current index based on available tabs
    final adjustedIndex =
        currentIndex < availableTabs.length ? currentIndex : 0;

    return ConvexAppBar(
      style: TabStyle.react,
      backgroundColor: isLightMode ? AppColors.white : AppColors.black,
      activeColor: AppColors.primaryColor,
      color: Theme.of(context).brightness == Brightness.dark
          ? [Colors.white, Colors.grey[800]!].reduce((value, element) => value)
          : Theme.of(context).colorScheme.primary,
      elevation: 12,
      initialActiveIndex: adjustedIndex,
      onTap: _onTap,
      items: availableTabs.map((tab) {
        final icon = tab['icon'] as IconData;
        final title = tab['title'] as String;
        
        return TabItem(icon: icon, title: title);
      }).toList(),
    );
  }
}
