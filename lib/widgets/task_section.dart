// widgets/task_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/utils/constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/task_controller.dart';
import 'package:task/models/task.dart';
import './task_list_tab.dart';

class TasksSection extends StatelessWidget {
  final TabController tabController;
  final AuthController authController;
  final TaskController taskController;
  final bool isDark;

  const TasksSection({
    super.key,
    required this.tabController,
    required this.authController,
    required this.taskController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 18.h),
          _buildTabBar(context),
          const SizedBox(height: 8),
          Expanded(
            child: _buildTabBarView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TabBar(
      controller: tabController,
      isScrollable: false,
      indicator: BoxDecoration(
        color: isDark ? colorScheme.onPrimary : colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      labelColor: isDark ? colorScheme.surface : AppColors.white,
      unselectedLabelColor: isDark
          ? colorScheme.onPrimary.withValues(alpha: 0.7)
          : AppColors.black,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15.sp,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 15.sp,
      ),
      tabs: [
        Tab(text: 'not_completed'.tr),
        Tab(text: 'completed'.tr),
      ],
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: tabController,
      children: [
        Obx(() {
          if (!Get.isRegistered<AuthController>() ||
              !Get.isRegistered<TaskController>()) {
            return const Center(child: CircularProgressIndicator());
          }

          final userId = authController.auth.currentUser?.uid ?? "";
          final tasks = taskController.tasks;
          debugPrint('TasksSection: userId = $userId');
          debugPrint(
              'TasksSection: total tasks in controller = ${tasks.length}');
          final taskMap = {for (var task in tasks) task.taskId: task};
          final notCompletedTasks = taskMap.values.where((t) {
            // Check relevance
            final isCreator = t.createdById == userId;
            final isAssignee = t.allAssignedUserIds.contains(userId);

            if (!isCreator && !isAssignee) return false;

            // If global status is completed, it's definitely not "Not Completed"
            if (t.status.toLowerCase() == "completed") return false;

            // If I am an assignee, check if I have personally completed it
            if (isAssignee) {
              if (t.completedByUserIds.contains(userId)) return false;
            }

            // Otherwise, it is pending/in-progress
            return true;
          }).toList();
          debugPrint(
              'TasksSection: notCompletedTasks count = ${notCompletedTasks.length}');

          return TaskListTab(
            isCompleted: false,
            isDark: isDark,
            tasks: List<Task>.from(notCompletedTasks),
          );
        }),
        Obx(() {
          if (!Get.isRegistered<AuthController>() ||
              !Get.isRegistered<TaskController>()) {
            return const Center(child: CircularProgressIndicator());
          }

          final userId = authController.auth.currentUser?.uid ?? "";
          final tasks = taskController.tasks;
          final taskMap = {for (var task in tasks) task.taskId: task};

          final completedTasks = taskMap.values.where((t) {
            // Check relevance
            final isCreator = t.createdById == userId;
            final isAssignee = t.allAssignedUserIds.contains(userId);

            if (!isCreator && !isAssignee) return false;

            // 1. If I am an assignee and I have completed it
            if (isAssignee && t.completedByUserIds.contains(userId)) {
              return true;
            }

            // 2. If the task is globally completed (for creators or legacy tasks)
            if (t.status.toLowerCase() == "completed") {
              return true;
            }

            return false;
          }).toList();

          return TaskListTab(
            isCompleted: true,
            isDark: isDark,
            tasks: List<Task>.from(completedTasks),
          );
        }),
      ],
    );
  }
}
