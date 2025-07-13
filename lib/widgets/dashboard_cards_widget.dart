// widgets/dashboard_cards_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task/utils/themes/app_theme.dart'; // Import your AppColors extension

class DashboardCardsWidget extends StatelessWidget {
  final int usersCount;
  final int tasksCount;
  final int onlineUsersCount;
  final int newsCount;

  final VoidCallback onManageUsersTap;
  final VoidCallback onTotalTasksTap;
  final VoidCallback onNewsFeedTap;
  final VoidCallback onOnlineUsersTap;

  const DashboardCardsWidget({
    super.key,
    required this.usersCount,
    required this.tasksCount,
    required this.onlineUsersCount,
    required this.newsCount,
    required this.onManageUsersTap,
    required this.onTotalTasksTap,
    required this.onNewsFeedTap,
    required this.onOnlineUsersTap,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF357088);
    // Card heights
    const double totalUsersHeight = 160;
    const double pendingTasksHeight = 120;
    const double onlineNowHeight = 120;
    const double newsFeedHeight = 160;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left column
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: 140,
                  height: totalUsersHeight,
                  child: _DashboardGridCard(
                    icon: Icons.people_alt_outlined,
                    value: usersCount,
                    label: 'Total Users',
                    onTap: onManageUsersTap,
                    color: cardColor,
                  ),
                ),
                SizedBox(height: 14),
                SizedBox(
                  width: 140,
                  height: pendingTasksHeight,
                  child: _DashboardGridCard(
                    icon: Icons.assignment_late_outlined,
                    value: tasksCount,
                    label: 'Pending Tasks',
                    onTap: onTotalTasksTap,
                    color: cardColor,
                  ),
                ),
              ],
            ),
            SizedBox(width: 14),
            // Right column
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: 140,
                  height: onlineNowHeight,
                  child: _DashboardGridCard(
                    icon: Icons.wifi_tethering,
                    value: onlineUsersCount,
                    label: 'Online Now',
                    onTap: onOnlineUsersTap,
                    color: cardColor,
                  ),
                ),
                SizedBox(height: 14),
                SizedBox(
                  width: 140,
                  height: newsFeedHeight,
                  child: _DashboardGridCard(
                    icon: Icons.rss_feed,
                    value: newsCount,
                    label: 'News Feed',
                    onTap: onNewsFeedTap,
                    color: cardColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardGridCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _DashboardGridCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox.square(
        dimension: 120.w, // You can adjust this size as needed
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 36),
              const SizedBox(height: 10),
              Text(
                value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
