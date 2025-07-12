// widgets/user_dashboard_cards_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task/utils/themes/app_theme.dart';

class UserDashboardCardsWidget extends StatelessWidget {
  final int assignedTasksToday;
  final int onlineUsersCount;
  final int tasksCreatedCount;
  final int newsFeedCount;
  final VoidCallback onAssignedTasksTap;
  final VoidCallback onOnlineUsersTap;
  final VoidCallback onTasksCreatedTap;
  final VoidCallback onNewsFeedTap;

  const UserDashboardCardsWidget({
    super.key,
    required this.assignedTasksToday,
    required this.onlineUsersCount,
    required this.tasksCreatedCount,
    required this.newsFeedCount,
    required this.onAssignedTasksTap,
    required this.onOnlineUsersTap,
    required this.onTasksCreatedTap,
    required this.onNewsFeedTap,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF357088);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DashboardGridCard(
                  icon: Icons.assignment_turned_in,
                  value: assignedTasksToday,
                  label: 'Assigned Tasks',
                  onTap: onAssignedTasksTap,
                  color: cardColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DashboardGridCard(
                  icon: Icons.wifi_tethering,
                  value: onlineUsersCount,
                  label: 'Online Now',
                  onTap: onOnlineUsersTap,
                  color: cardColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DashboardGridCard(
                  icon: Icons.create,
                  value: tasksCreatedCount,
                  label: 'Task Created',
                  onTap: onTasksCreatedTap,
                  color: cardColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DashboardGridCard(
                  icon: Icons.rss_feed,
                  value: newsFeedCount,
                  label: 'News Feed',
                  onTap: onNewsFeedTap,
                  color: cardColor,
                ),
              ),
            ],
          ),
        ],
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
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
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
    );
  }
} 