// widgets/user_dashboard_cards_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    // Card heights
    const double assignedTaskHeight = 160;
    const double newsFeedHeight = 160;
    const double onlineNowHeight = 120;
    const double taskCreatedHeight = 120;
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
                  height: assignedTaskHeight,
                  child: _DashboardGridCard(
                    icon: Icons.assignment_turned_in,
                    value: assignedTasksToday,
                    label: 'Assigned Task',
                    onTap: onAssignedTasksTap,
                    color: cardColor,
                  ),
                ),
                SizedBox(height: 14),
                SizedBox(
                  width: 140,
                  height: taskCreatedHeight,
                  child: _DashboardGridCard(
                    icon: Icons.create,
                    value: tasksCreatedCount,
                    label: 'Task Created',
                    onTap: onTasksCreatedTap,
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
        dimension: 120.w, // Adjust as needed for your design
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