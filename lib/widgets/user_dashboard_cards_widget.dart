// widgets/user_dashboard_cards_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task/utils/themes/app_theme.dart';

class UserDashboardCardsWidget extends StatelessWidget {
  final int assignedTasksToday;
  final int onlineUsersCount;
  final VoidCallback onAssignedTasksTap;
  final VoidCallback onOnlineUsersTap;

  const UserDashboardCardsWidget({
    super.key,
    required this.assignedTasksToday,
    required this.onlineUsersCount,
    required this.onAssignedTasksTap,
    required this.onOnlineUsersTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    // Define dark mode colors for cards
    const darkAccent = Color(0xFF4527A0);
    const darkSecondary = Color(0xFF2D3A5A);

    return Row(
      children: [
        _StatCard(
          title: 'Assigned Tasks',
          value: assignedTasksToday.toString(),
          icon: Icons.assignment_turned_in_outlined,
          onTap: onAssignedTasksTap,
          color: isDark ? darkAccent : appColors.accent1!,
        ),
        const SizedBox(width: 16),
        _StatCard(
          title: 'Online Now',
          value: onlineUsersCount.toString(),
          icon: Icons.wifi_tethering,
          onTap: onOnlineUsersTap,
          color: isDark ? darkSecondary : theme.colorScheme.secondary,
        ),
      ],
    );
  }
}

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
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
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