// widgets/dashboard_cards_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/utils/devices/app_devices.dart';

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
    
    // Get screen dimensions for responsive design using AppDevices
    final screenWidth = AppDevices.getScreenWidth(context);
    final screenHeight = AppDevices.getScreenHeight(context);
    final isTablet = AppDevices.isTablet(context);
    final isSmallScreen = screenWidth < 360;
    final isShortScreen = screenHeight < 600;
    
    // Responsive card dimensions
    
    final cardSpacing = isTablet ? 20.0 : isSmallScreen ? 8.0 : 14.0;
    final padding = isTablet ? 24.0 : isSmallScreen ? 12.0 : 16.0;
    
    // Responsive card heights based on screen size and height
    final baseHeightMultiplier = isShortScreen ? 0.8 : 1.0;
    final totalUsersHeight = (isTablet ? 180.0 : isSmallScreen ? 140.0 : 160.0) * baseHeightMultiplier;
    final pendingTasksHeight = (isTablet ? 140.0 : isSmallScreen ? 100.0 : 120.0) * baseHeightMultiplier;
    final onlineNowHeight = (isTablet ? 140.0 : isSmallScreen ? 100.0 : 120.0) * baseHeightMultiplier;
    final newsFeedHeight = (isTablet ? 180.0 : isSmallScreen ? 140.0 : 160.0) * baseHeightMultiplier;
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left column
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        height: totalUsersHeight,
                        child: _DashboardGridCard(
                          icon: Icons.people_alt_outlined,
                          value: usersCount,
                          label: 'total_users'.tr,
                          onTap: onManageUsersTap,
                          color: cardColor,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      SizedBox(height: cardSpacing),
                      Container(
                        height: pendingTasksHeight,
                        child: _DashboardGridCard(
                          icon: Icons.assignment_late_outlined,
                          value: tasksCount,
                          label: 'pending_tasks'.tr,
                          onTap: onTotalTasksTap,
                          color: cardColor,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: cardSpacing),
                // Right column
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        height: onlineNowHeight,
                        child: _DashboardGridCard(
                          icon: Icons.wifi_tethering,
                          value: onlineUsersCount,
                          label: 'online_users_count'.tr,
                          onTap: onOnlineUsersTap,
                          color: cardColor,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      SizedBox(height: cardSpacing),
                      Container(
                        height: newsFeedHeight,
                        child: _DashboardGridCard(
                          icon: Icons.rss_feed,
                          value: newsCount,
                          label: 'news_feed'.tr,
                          onTap: onNewsFeedTap,
                          color: cardColor,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
  final bool isSmallScreen;

  const _DashboardGridCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    required this.color,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive sizing based on screen size
    final iconSize = isSmallScreen ? 24.0 : 36.0;
    final valueSize = isSmallScreen ? 20.0 : 28.0;
    final labelSize = isSmallScreen ? 12.0 : 16.0;
    final borderRadius = isSmallScreen ? 16.0 : 24.0;
    final verticalSpacing = isSmallScreen ? 6.0 : 10.0;
    final smallSpacing = isSmallScreen ? 2.0 : 4.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                color: Colors.white, 
                size: iconSize,
              ),
              SizedBox(height: verticalSpacing),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: smallSpacing),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: labelSize,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
