// widgets/user_dashboard_cards_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/utils/devices/app_devices.dart';

class UserDashboardCardsWidget extends StatelessWidget {
  final RxInt assignedTasksCount;
  final Stream<int> onlineUsersStream;
  final Stream<int> tasksCreatedStream;
  final Stream<int> newsFeedStream;
  final VoidCallback onAssignedTasksTap;
  final VoidCallback onOnlineUsersTap;
  final VoidCallback onTasksCreatedTap;
  final VoidCallback onNewsFeedTap;

  const UserDashboardCardsWidget({
    super.key,
    required this.assignedTasksCount,
    required this.onlineUsersStream,
    required this.tasksCreatedStream,
    required this.newsFeedStream,
    required this.onAssignedTasksTap,
    required this.onOnlineUsersTap,
    required this.onTasksCreatedTap,
    required this.onNewsFeedTap,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF357088);
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = AppDevices.getScreenWidth(context);
    AppDevices.isTablet(context);
    
    // Responsive card dimensions based on orientation
    final cardWidth = orientation == Orientation.portrait 
        ? (screenWidth - 48) / 2.2  // Portrait: smaller cards
        : (screenWidth - 48) / 4.5; // Landscape: even smaller cards
    
    final assignedTaskHeight = orientation == Orientation.portrait ? 160.0 : 120.0;
    final newsFeedHeight = orientation == Orientation.portrait ? 160.0 : 120.0;
    final onlineNowHeight = orientation == Orientation.portrait ? 120.0 : 100.0;
    final taskCreatedHeight = orientation == Orientation.portrait ? 120.0 : 100.0;
    
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: orientation == Orientation.portrait
          ? _buildPortraitLayout(cardWidth, assignedTaskHeight, taskCreatedHeight, onlineNowHeight, newsFeedHeight, cardColor)
          : _buildLandscapeLayout(cardWidth, assignedTaskHeight, taskCreatedHeight, onlineNowHeight, newsFeedHeight, cardColor),
    );
  }
  
  Widget _buildPortraitLayout(double cardWidth, double assignedTaskHeight, double taskCreatedHeight, double onlineNowHeight, double newsFeedHeight, Color cardColor) {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left column
          Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                width: cardWidth,
                height: assignedTaskHeight,
                child: Obx(() {
                  final count = assignedTasksCount.value;
                  return _DashboardGridCard(
                    icon: Icons.assignment_turned_in,
                    value: count,
                    label: 'assigned_task'.tr,
                    onTap: onAssignedTasksTap,
                    color: cardColor,
                  );
                }),
              ),
              SizedBox(height: 14.h),
              SizedBox(
                width: cardWidth,
                height: taskCreatedHeight,
                child: StreamBuilder<int>(
                  stream: tasksCreatedStream,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _DashboardGridCard(
                      icon: Icons.create,
                      value: count,
                      label: 'task_created'.tr,
                      onTap: onTasksCreatedTap,
                      color: cardColor,
                    );
                  },
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
                width: cardWidth,
                height: onlineNowHeight,
                child: StreamBuilder<int>(
                  stream: onlineUsersStream,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _DashboardGridCard(
                      icon: Icons.wifi_tethering,
                      value: count,
                      label: 'online_users_count'.tr,
                      onTap: onOnlineUsersTap,
                      color: cardColor,
                    );
                  },
                ),
              ),
              SizedBox(height: 14.h),
              SizedBox(
                width: cardWidth,
                height: newsFeedHeight,
                child: StreamBuilder<int>(
                  stream: newsFeedStream,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _DashboardGridCard(
                      icon: Icons.rss_feed,
                      value: count,
                      label: 'news_feed'.tr,
                      onTap: onNewsFeedTap,
                      color: cardColor,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLandscapeLayout(double cardWidth, double assignedTaskHeight, double taskCreatedHeight, double onlineNowHeight, double newsFeedHeight, Color cardColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            width: cardWidth,
            height: assignedTaskHeight,
            child: Obx(() {
              final count = assignedTasksCount.value;
              return _DashboardGridCard(
                icon: Icons.assignment_turned_in,
                value: count,
                label: 'assigned_task'.tr,
                onTap: onAssignedTasksTap,
                color: cardColor,
              );
            }),
          ),
          SizedBox(width: 14.w),
          SizedBox(
            width: cardWidth,
            height: onlineNowHeight,
            child: StreamBuilder<int>(
              stream: onlineUsersStream,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return _DashboardGridCard(
                  icon: Icons.wifi_tethering,
                  value: count,
                  label: 'online_users_count'.tr,
                  onTap: onOnlineUsersTap,
                  color: cardColor,
                );
              },
            ),
          ),
          SizedBox(width: 14.w),
          SizedBox(
            width: cardWidth,
            height: taskCreatedHeight,
            child: StreamBuilder<int>(
              stream: tasksCreatedStream,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return _DashboardGridCard(
                  icon: Icons.create,
                  value: count,
                  label: 'task_created'.tr,
                  onTap: onTasksCreatedTap,
                  color: cardColor,
                );
              },
            ),
          ),
          SizedBox(width: 14.w),
          SizedBox(
            width: cardWidth,
            height: newsFeedHeight,
            child: StreamBuilder<int>(
              stream: newsFeedStream,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return _DashboardGridCard(
                  icon: Icons.rss_feed,
                  value: count,
                  label: 'news_feed'.tr,
                  onTap: onNewsFeedTap,
                  color: cardColor,
                );
              },
            ),
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
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}