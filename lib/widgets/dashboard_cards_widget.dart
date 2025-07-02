// widgets/dashboard_cards_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task/utils/themes/app_theme.dart'; // Import your AppColors extension

class DashboardCardsWidget extends StatelessWidget {
  final int usersCount;
  final int tasksCount;
  final int onlineUsersCount;
  final int conversationsCount;

  final VoidCallback onManageUsersTap;
  final VoidCallback onTotalTasksTap;

  const DashboardCardsWidget({
    super.key,
    required this.usersCount,
    required this.tasksCount,
    required this.onlineUsersCount,
    required this.conversationsCount,
    required this.onManageUsersTap,
    required this.onTotalTasksTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get the full theme and your custom colors
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;

    return Column(
      children: [
        // --- FIRST ROW (Using your theme's primary and secondary colors) ---
        Row(
          children: [
            _StatCard(
              title: 'Total Users',
              value: usersCount.toString(),
              icon: Icons.people_alt_outlined,
              onTap: onManageUsersTap,
              color: theme.colorScheme.primary, // Using _primaryBlue
            ),
            const SizedBox(width: 16),
            _StatCard(
              title: 'Pending Tasks',
              value: tasksCount.toString(),
              icon: Icons.assignment_late_outlined,
              onTap: onTotalTasksTap,
              color: theme.colorScheme.secondary, // Using _secondaryBlue
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- SECOND ROW (Using your new custom theme colors) ---
        Row(
          children: [
            _StatCard(
              title: 'Online Now',
              value: onlineUsersCount.toString(),
              icon: Icons.wifi_tethering,
              onTap: onManageUsersTap,
              color: appColors.success!, // Using your new green color
            ),
            const SizedBox(width: 16),
            _StatCard(
              title: 'Total Chats',
              value: conversationsCount.toString(),
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () {},
              color: appColors.accent1!, // Using your new purple color
            ),
          ],
        ),
      ],
    );
  }
}

// Helper widget for a single card. No changes needed here,
// as it just accepts and displays whatever color it's given.
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
