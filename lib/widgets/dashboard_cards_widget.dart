// widgets/dashboard_cards_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
      padding: EdgeInsets.all(16.0.w),
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
                  height: totalUsersHeight.h,
                  child: _DashboardGridCard(
                    icon: Icons.people_alt_outlined,
                    value: usersCount,
                    label: 'total_users'.tr,
                    onTap: onManageUsersTap,
                    color: cardColor,
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: 140.w,
                  height: pendingTasksHeight.h,
                  child: _DashboardGridCard(
                    icon: Icons.assignment_late_outlined,
                    value: tasksCount,
                    label: 'pending_tasks'.tr,
                    onTap: onTotalTasksTap,
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
                    value: newsCount,
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
        dimension: 120.w, // You can adjust this size as needed
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 36.sp),
              SizedBox(height: 10.h),
              Text(
                value.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
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
