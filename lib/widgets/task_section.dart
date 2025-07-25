// widgets/task_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/task_controller.dart';
import 'package:task/models/task_model.dart';
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
          color: colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildTabBar(context),
          const SizedBox(height: 8),
          SizedBox(
            height: 400,
            child: _buildTabBarView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(top: 18, left: 16, right: 16, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => Get.toNamed('/create-task'),
            child: Container(
              width: 34.w,
              height: 34.h,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                color: colorScheme.onPrimary,
                size: 22,
              ),
            ),
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
      indicatorColor: isDark ? colorScheme.onPrimary : colorScheme.primary,
      indicatorWeight: 2.5,
      labelColor: isDark ? colorScheme.onPrimary : colorScheme.primary,
      unselectedLabelColor: isDark ? colorScheme.onPrimary.withOpacity(0.7) : Colors.black54,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 15,
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
          if (!Get.isRegistered<AuthController>() || !Get.isRegistered<TaskController>()) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final userId = authController.auth.currentUser?.uid ?? "";
          final tasks = taskController.tasks;
          debugPrint('TasksSection: userId = $userId');
          debugPrint('TasksSection: total tasks in controller = ${tasks.length}');
          final taskMap = {for (var task in tasks) task.taskId: task};
          final notCompletedTasks = taskMap.values.where((t) {
            final isRelevant = (t.createdById == userId ||
                t.assignedTo == userId ||
                t.assignedReporterId == userId ||
                t.assignedCameramanId == userId ||
                t.assignedDriverId == userId ||
                t.assignedLibrarianId == userId);
            final isNotCompleted = t.status != "Completed";
            debugPrint('TasksSection: task ${t.taskId} - createdById=${t.createdById}, assignedTo=${t.assignedTo}, assignedReporterId=${t.assignedReporterId}, assignedCameramanId=${t.assignedCameramanId}, assignedDriverId=${t.assignedDriverId}, assignedLibrarianId=${t.assignedLibrarianId}, status=${t.status}, isRelevant=$isRelevant, isNotCompleted=$isNotCompleted');
            return isNotCompleted && isRelevant;
          }).toList();
          debugPrint('TasksSection: notCompletedTasks count = ${notCompletedTasks.length}');

          return TaskListTab(
            isCompleted: false,
            isDark: isDark,
            tasks: List<Task>.from(notCompletedTasks),
          );
        }),
        Obx(() {
          if (!Get.isRegistered<AuthController>() || !Get.isRegistered<TaskController>()) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final userId = authController.auth.currentUser?.uid ?? "";
          final tasks = taskController.tasks;
          final taskMap = {for (var task in tasks) task.taskId: task};

          final completedTasks = taskMap.values
              .where((t) =>
                  t.status == "Completed" &&
                  (t.createdById == userId ||
                      t.assignedTo == userId ||
                      t.assignedReporterId == userId ||
                      t.assignedCameramanId == userId ||
                      t.assignedDriverId == userId ||
                      t.assignedLibrarianId == userId))
              .toList();

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
