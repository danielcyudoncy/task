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
    const cardColor = Color(0xFF003080);
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = AppDevices.getScreenWidth(context);
    AppDevices.isTablet(context);

    // Responsive card heights based on orientation and screen size
    final baseHeight = orientation == Orientation.portrait
        ? 120.0 // Simplified height for portrait
        : screenWidth < 600
            ? 140.0
            : 140.0; // Smaller height for small landscape

    final assignedTaskHeight = baseHeight;
    final newsFeedHeight = baseHeight;
    final onlineNowHeight = baseHeight * 0.75; // 75% of base height
    final taskCreatedHeight = baseHeight * 0.75; // 75% of base height

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 12.h),
      child: orientation == Orientation.portrait
          ? _buildPortraitLayout(context, assignedTaskHeight, taskCreatedHeight,
              onlineNowHeight, newsFeedHeight, cardColor)
          : _buildLandscapeLayout(assignedTaskHeight, taskCreatedHeight,
              onlineNowHeight, newsFeedHeight, cardColor),
    );
  }

  Widget _buildPortraitLayout(
      BuildContext context,
      double assignedTaskHeight,
      double taskCreatedHeight,
      double onlineNowHeight,
      double newsFeedHeight,
      Color cardColor) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 10.w) / 2;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column
          Column(
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
              SizedBox(height: 10.h),
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
          SizedBox(width: 10.w),
          // Right column
          Column(
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
              SizedBox(height: 10.h),
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
      );
    });
  }

  Widget _buildLandscapeLayout(
      double assignedTaskHeight,
      double taskCreatedHeight,
      double onlineNowHeight,
      double newsFeedHeight,
      Color cardColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: SizedBox(
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
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: SizedBox(
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
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: SizedBox(
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
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: SizedBox(
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
        ),
      ],
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
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.white, 0.2)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Icon(icon, color: Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}