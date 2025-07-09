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
    // Get the full theme and your custom colors
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    // Define dark mode colors for cards
    const darkSecondary = Color(0xFF2D3A5A);
    const darkSuccess = Color(0xFF388E3C);
    const darkWarning = Color(0xFFB26A00);
    const darkAccent = Color(0xFF4527A0);

    return Column(
      children: [
        // --- FIRST ROW ---
        Row(
          children: [
            _StatCard(
              title: 'Total Users',
              value: usersCount.toString(),
              icon: Icons.people_alt_outlined,
              onTap: onManageUsersTap,
              color: isDark ? darkSecondary : theme.colorScheme.secondary,
            ),
            const SizedBox(width: 16),
            _StatCard(
              title: 'Pending Tasks',
              value: tasksCount.toString(),
              icon: Icons.assignment_late_outlined,
              onTap: onTotalTasksTap,
              color: isDark ? darkAccent : theme.colorScheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // --- SECOND ROW ---
        Row(
          children: [
            _StatCard(
              title: 'Online Now',
              value: onlineUsersCount.toString(),
              icon: Icons.wifi_tethering,
              onTap: onOnlineUsersTap,
              color: isDark ? darkSuccess : appColors.success!,
            ),
            const SizedBox(width: 16),
            _StatCard(
              title: 'News Feed',
              value: newsCount == 0 ? '' : newsCount.toString(),
              icon: Icons.rss_feed,
              onTap: onNewsFeedTap,
              color: isDark ? darkWarning : appColors.warning!,
            ),
          ],
        ),
      ],
    );
  }
}

// Helper widget for a single card. 
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: color,
          elevation: 4,
          shadowColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
