// widgets/user_dashboard_cards_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left column
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: 140.w,
                  height: assignedTaskHeight.h,
                  child: _DashboardGridCard(
                    icon: Icons.assignment_turned_in,
                    value: assignedTasksToday,
                    label: 'assigned_task'.tr,
                    onTap: onAssignedTasksTap,
                    color: cardColor,
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: 140.w,
                  height: taskCreatedHeight.h,
                  child: _DashboardGridCard(
                    icon: Icons.create,
                    value: tasksCreatedCount,
                    label: 'task_created'.tr,
                    onTap: onTasksCreatedTap,
                    color: cardColor,
                  ),
                ),
              ],
            ),
            SizedBox(width: 14.w),
            // Right column
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: 140.w,
                  height: onlineNowHeight.h,
                  child: _DashboardGridCard(
                    icon: Icons.wifi_tethering,
                    value: onlineUsersCount,
                    label: 'online_users_count'.tr,
                    onTap: onOnlineUsersTap,
                    color: cardColor,
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: 140.w,
                  height: newsFeedHeight.h,
                  child: _DashboardGridCard(
                    icon: Icons.rss_feed,
                    value: newsFeedCount,
                    label: 'news_feed'.tr,
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
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 