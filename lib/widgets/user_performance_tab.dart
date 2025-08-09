// widgets/user_performance_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/performance_controller.dart';

class UserPerformanceTab extends StatelessWidget {
  const UserPerformanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final performanceController = Get.find<PerformanceController>();

    return Obx(() {
      if (performanceController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Overview Cards
            _buildPerformanceOverview(context, performanceController),
            SizedBox(height: 20.h),
            
            // Performance Distribution Chart
            _buildPerformanceDistribution(context, performanceController),
            SizedBox(height: 20.h),
            
            // Top Performers Section
            _buildTopPerformersSection(context, performanceController),
            SizedBox(height: 20.h),
            
            // All Users Performance List
            _buildAllUsersPerformance(context, performanceController),
          ],
        ),
      );
    });
  }

  Widget _buildPerformanceOverview(BuildContext context, PerformanceController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Overview',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                context,
                'Total Users',
                controller.totalUsers.value.toString(),
                Icons.people,
                colorScheme.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildOverviewCard(
                context,
                'Avg Completion Rate',
                '${controller.averageCompletionRate.value.toStringAsFixed(1)}%',
                Icons.trending_up,
                colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDistribution(BuildContext context, PerformanceController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final distribution = controller.getPerformanceDistribution();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Distribution',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: distribution.entries.map((entry) {
              final grade = entry.key;
              final count = entry.value;
              final percentage = controller.totalUsers.value > 0 
                  ? (count / controller.totalUsers.value) * 100 
                  : 0.0;
              
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        color: _getGradeColor(grade).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Center(
                        child: Text(
                          grade,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: _getGradeColor(grade),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$count users',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(_getGradeColor(grade)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformersSection(BuildContext context, PerformanceController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Performers',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        ...controller.topPerformers.take(5).map((user) => 
          _buildUserPerformanceCard(context, user, isTopPerformer: true)
        ),
      ],
    );
  }

  Widget _buildAllUsersPerformance(BuildContext context, PerformanceController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All Users Performance',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            IconButton(
              onPressed: () => controller.refreshData(),
              icon: Icon(
                Icons.refresh,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ...controller.userPerformanceData.map((user) => 
          _buildUserPerformanceCard(context, user)
        ),
      ],
    );
  }

  Widget _buildUserPerformanceCard(BuildContext context, Map<String, dynamic> user, {bool isTopPerformer = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final completionRate = user['completionRate'] as double;
    final grade = user['performanceGrade'] as String;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isTopPerformer 
            ? colorScheme.primary.withValues(alpha: 0.05)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: isTopPerformer 
            ? Border.all(color: colorScheme.primary.withValues(alpha: 0.3))
            : Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: _getGradeColor(grade).withValues(alpha: 0.2),
                child: Text(
                  user['userName'][0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: _getGradeColor(grade),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['userName'],
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: _getGradeColor(grade).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            grade,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: _getGradeColor(grade),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      user['userRole'],
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Completed',
                  '${user['completedTasks']}/${user['totalAssignedTasks']}',
                  Icons.task_alt,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Success Rate',
                  '${completionRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Recent Activity',
                  '${user['recentActivity']}',
                  Icons.schedule,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: completionRate / 100,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(_getGradeColor(grade)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: colorScheme.primary,
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
        return const Color(0xFF4CAF50); // Green
      case 'A':
        return const Color(0xFF8BC34A); // Light Green
      case 'B+':
        return const Color(0xFF2196F3); // Blue
      case 'B':
        return const Color(0xFF03A9F4); // Light Blue
      case 'C+':
        return const Color(0xFFFF9800); // Orange
      case 'C':
        return const Color(0xFFFF5722); // Deep Orange
      case 'D':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}