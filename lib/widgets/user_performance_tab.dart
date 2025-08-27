// widgets/user_performance_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/performance_controller.dart';
import '../utils/themes/app_theme.dart';

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
    final appColors = Theme.of(context).extension<AppColors>();
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: colorScheme.onPrimary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Performance Overview',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    context,
                    'Total Users',
                    controller.totalUsers.value.toString(),
                    Icons.people_outline,
                    appColors?.accent1 ?? colorScheme.secondary,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildOverviewCard(
                    context,
                    'Avg Completion Rate',
                    '${controller.averageCompletionRate.value.toStringAsFixed(1)}%',
                    Icons.trending_up_outlined,
                    appColors?.success ?? colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDistribution(BuildContext context, PerformanceController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final distribution = controller.getPerformanceDistribution();
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
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
                  color: colorScheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.bar_chart_outlined,
                  color: colorScheme.secondary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Performance Distribution',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: distribution.entries.map((entry) {
                final grade = entry.key;
                final count = entry.value;
                final total = distribution.values.fold(0, (sum, value) => sum + value);
                final percentage = total > 0 ? (count / total * 100) : 0.0;
                
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      Container(
                        width: 45.w,
                        height: 35.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getGradeColor(grade).withValues(alpha: 0.3),
                              _getGradeColor(grade).withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: _getGradeColor(grade).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            grade,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: _getGradeColor(grade, context),
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
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              height: 6.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3.r),
                                color: colorScheme.outline.withValues(alpha: 0.15),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3.r),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation(_getGradeColor(grade, context)),
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildTopPerformersSection(BuildContext context, PerformanceController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (appColors?.success ?? colorScheme.secondary).withValues(alpha: 0.1),
                (appColors?.success ?? colorScheme.secondary).withValues(alpha: 0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: (appColors?.success ?? colorScheme.secondary).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: appColors?.success ?? colorScheme.secondary,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Top Performers',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
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
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.group_outlined,
                    color: colorScheme.primary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'All Users Performance',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: IconButton(
                  onPressed: () => controller.refreshData(),
                  icon: Icon(
                    Icons.refresh_outlined,
                    color: colorScheme.primary,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        ...controller.userPerformanceData.map((user) => 
          _buildUserPerformanceCard(context, user)
        ),
      ],
    );
  }

  Widget _buildUserPerformanceCard(BuildContext context, Map<String, dynamic> user, {bool isTopPerformer = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    final completionRate = user['completionRate'] as double;
    final grade = user['performanceGrade'] as String;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTopPerformer 
              ? [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.85),
                ]
              : [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.9),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isTopPerformer 
              ? (appColors?.success ?? colorScheme.primary).withValues(alpha: 0.4)
              : colorScheme.primary.withValues(alpha: 0.3),
          width: isTopPerformer ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTopPerformer 
                ? (appColors?.success ?? colorScheme.primary).withValues(alpha: 0.15)
                : colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: isTopPerformer ? 8 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.onPrimary.withValues(alpha: 0.2),
                      border: Border.all(
                        color: isTopPerformer 
                            ? (appColors?.success ?? const Color(0xFFFFD700)) // Gold border for top performers
                            : colorScheme.onPrimary.withValues(alpha: 0.4),
                        width: isTopPerformer ? 3 : 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22.r,
                      backgroundColor: Colors.transparent,
                      backgroundImage: (user['photoUrl'] != null && 
                          user['photoUrl'].toString().isNotEmpty && 
                          user['photoUrl'] != 'null') 
                          ? NetworkImage(user['photoUrl']) 
                          : null,
                      child: (user['photoUrl'] == null || 
                              user['photoUrl'].toString().isEmpty || 
                              user['photoUrl'] == 'null')
                          ? Text(
                              user['userName']?.toString().isNotEmpty == true
                                  ? user['userName'][0].toUpperCase()
                                  : user['userEmail']?[0].toUpperCase() ?? '?',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (isTopPerformer && _shouldShowTrophy(user))
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD700), // Gold color
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: colorScheme.primary, // Use theme primary blue color
                          size: 12.sp,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            user['userName']?.toString().isNotEmpty == true
                                ? user['userName']
                                : user['userEmail'] ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: _getGradeColor(grade, context).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: _getGradeColor(grade, context).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            grade,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: _getGradeColor(grade, context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${completionRate.toStringAsFixed(1)}% completion rate',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                context,
                'Completed',
                user['completedTasks'].toString(),
                Icons.check_circle_outline,
                isOnPrimary: true,
              ),
              _buildMetricItem(
                context,
                'In Progress',
                user['inProgressTasks'].toString(),
                Icons.schedule_outlined,
                isOnPrimary: true,
              ),
              _buildMetricItem(
                context,
                'Overdue',
                user['overdueTasks'].toString(),
                Icons.warning_amber_outlined,
                isOnPrimary: true,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            height: 8.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              color: colorScheme.onPrimary.withValues(alpha: 0.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: completionRate / 100,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(
                  _getGradeColor(grade, context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value, IconData icon, {bool isOnPrimary = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isOnPrimary 
                  ? colorScheme.onPrimary.withValues(alpha: 0.15)
                  : colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isOnPrimary 
                    ? colorScheme.onPrimary.withValues(alpha: 0.2)
                    : colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 18.sp,
              color: isOnPrimary 
                  ? colorScheme.onPrimary
                  : (Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey
                      : colorScheme.primary),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: isOnPrimary ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: isOnPrimary 
                  ? colorScheme.onPrimary.withValues(alpha: 0.8)
                  : colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Determines if a user should show the trophy based on their performance
  bool _shouldShowTrophy(Map<String, dynamic> user) {
    final completedTasks = user['completedTasks'] as int? ?? 0;
    final completionRate = user['completionRate'] as double? ?? 0.0;
    final grade = user['performanceGrade'] as String? ?? 'F';
    
    // Show trophy only if:
    // 1. User has completed at least 1 task
    // 2. Has a completion rate of at least 60%
    // 3. Has a grade of A+, A, B+, or B
    return completedTasks > 0 && 
           completionRate >= 60.0 && 
           (grade.toUpperCase().startsWith('A') || grade.toUpperCase().startsWith('B'));
  }

  Color _getGradeColor(String grade, [BuildContext? context]) {
    final isDark = context != null ? Theme.of(context).brightness == Brightness.dark : false;
    
    switch (grade.toUpperCase()) {
      case 'A':
        return isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50); // Green - lighter in dark mode
      case 'B':
        return isDark ? const Color(0xFF9CCC65) : const Color(0xFF8BC34A); // Light Green - lighter in dark mode
      case 'C':
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800); // Orange - lighter in dark mode
      case 'D':
        return isDark ? const Color(0xFFFF8A65) : const Color(0xFFFF5722); // Deep Orange - lighter in dark mode
      case 'F':
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFF44336); // Red - lighter in dark mode
      default:
        return isDark ? const Color(0xFFBDBDBD) : const Color(0xFF9E9E9E); // Grey - lighter in dark mode
    }
  }
}