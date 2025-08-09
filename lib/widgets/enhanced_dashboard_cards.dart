import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../controllers/performance_controller.dart';

class EnhancedDashboardCardsWidget extends StatelessWidget {
  final VoidCallback onManageUsersTap;
  final VoidCallback onTotalTasksTap;
  final VoidCallback onNewsFeedTap;
  final VoidCallback onOnlineUsersTap;

  const EnhancedDashboardCardsWidget({
    super.key,
    required this.onManageUsersTap,
    required this.onTotalTasksTap,
    required this.onNewsFeedTap,
    required this.onOnlineUsersTap,
  });

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminController>();
    final performanceController = Get.find<PerformanceController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      return Column(
        children: [
          // First row - Original dashboard cards
          Row(
            children: [
              Expanded(
                child: _buildDashboardCard(
                  context,
                  'Total Users',
                  adminController.totalUsers.value.toString(),
                  Icons.people,
                  const Color(0xFF6366F1), // Indigo color for better contrast
                  'Active users in system',
                  onManageUsersTap,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildDashboardCard(
                  context,
                  'Online Users',
                  adminController.onlineUsers.value.toString(),
                  Icons.circle,
                  Colors.green,
                  'Currently active',
                  onOnlineUsersTap,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // Second row - News and Tasks
          Row(
            children: [
              Expanded(
                child: _buildDashboardCard(
                  context,
                  'News Articles',
                  adminController.newsCount.value.toString(),
                  Icons.article,
                  colorScheme.secondary,
                  'Published articles',
                  onNewsFeedTap,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildDashboardCard(
                  context,
                  'Pending Tasks',
                  adminController.pendingTasks.value.toString(),
                  Icons.assignment_late_outlined,
                  Colors.orange,
                  'Awaiting completion',
                  onTotalTasksTap,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // Third row - Performance metrics
          Row(
            children: [
              Expanded(
                child: _buildDashboardCard(
                  context,
                  'Avg Performance',
                  performanceController.isLoading.value 
                      ? '--' 
                      : '${performanceController.averageCompletionRate.value.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  const Color(0xFF4CAF50),
                  'Overall completion rate',
                  null,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildDashboardCard(
                  context,
                  'Top Performers',
                  performanceController.isLoading.value 
                      ? '--' 
                      : performanceController.topPerformers.length.toString(),
                  Icons.star,
                  const Color(0xFFFFD700),
                  'High achievers',
                  null,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Performance distribution summary
          if (!performanceController.isLoading.value)
            _buildPerformanceDistributionSummary(context, performanceController),
        ],
      );
    });
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback? onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24.sp,
                ),
              ),
              const Spacer(),
              if (title == 'Online Users')
                Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black 
                  : Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.sp,
              color: (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black 
                  : Colors.white).withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ));
  }
  }

  Widget _buildPerformanceDistributionSummary(
    BuildContext context,
    PerformanceController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final distribution = controller.getPerformanceDistribution();
    
    // Calculate high performers (A+ and A grades)
    final highPerformers = (distribution['A+'] ?? 0) + (distribution['A'] ?? 0);
    final totalUsers = controller.totalUsers.value;
    final highPerformerPercentage = totalUsers > 0 ? (highPerformers / totalUsers) * 100 : 0.0;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.primaryContainer.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: colorScheme.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Performance Analytics',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.black 
                      : Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildQuickStat(
                  context,
                  'High Performers',
                  '$highPerformers users',
                  '${highPerformerPercentage.toStringAsFixed(1)}%',
                  const Color(0xFF4CAF50),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 1,
                child: _buildQuickStat(
                  context,
                  'Needs Improvement',
                  '${(distribution['C'] ?? 0) + (distribution['D'] ?? 0)} users',
                  'Grades C-D',
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Quick grade distribution
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: distribution.entries.map((entry) {
                final grade = entry.key;
                final count = entry.value;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: _buildGradeBadge(context, grade, count),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    BuildContext context,
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      constraints: BoxConstraints(maxWidth: 150.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black 
                  : Colors.white).withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.sp,
              color: (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black 
                  : Colors.white).withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBadge(BuildContext context, String grade, int count) {
    final color = _getGradeColor(grade);
    
    return Column(
      children: [
        Container(
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              grade,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: (Theme.of(context).brightness == Brightness.dark 
                ? Colors.black 
                : Colors.white).withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
        return const Color(0xFF4CAF50);
      case 'A':
        return const Color(0xFF8BC34A);
      case 'B+':
        return const Color(0xFF2196F3);
      case 'B':
        return const Color(0xFF03A9F4);
      case 'C+':
        return const Color(0xFFFF9800);
      case 'C':
        return const Color(0xFFFF5722);
      case 'D':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
