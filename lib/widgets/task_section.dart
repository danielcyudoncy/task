// widgets/task_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/task_controller.dart';
import '../../utils/constants/app_strings.dart';
import '../../utils/constants/app_styles.dart';
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildTabBar(context),
          const SizedBox(height: 8),
          Expanded(child: _buildTabBarView()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                color: isDark
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: isDark
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: tabController,
      isScrollable: false,
      indicatorColor:
          isDark ? Colors.white : Theme.of(context).colorScheme.primary,
      indicatorWeight: 2.5,
      labelColor: isDark ? Colors.white : Theme.of(context).colorScheme.primary,
      unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
      labelStyle: AppStyles.tabSelectedStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      unselectedLabelStyle: AppStyles.tabUnselectedStyle,
      tabs: const [
        Tab(text: AppStrings.notCompleted),
        Tab(text: AppStrings.completed),
      ],
    );
  }

  Widget _buildTabBarView() {
    return Obx(() {
      if (!Get.isRegistered<AuthController>() || !Get.isRegistered<TaskController>()) {
        return const TabBarView(
          children: [
            Center(child: CircularProgressIndicator()),
            Center(child: CircularProgressIndicator()),
          ],
        );
      }
      
      final userId = authController.auth.currentUser?.uid ?? "";
      final tasks = taskController.tasks;
      final taskMap = {for (var task in tasks) task.taskId: task};

      final notCompletedTasks = taskMap.values.where((t) {
        return (t.status != "Completed") &&
            (t.createdById == userId ||
                t.assignedTo == userId ||
                t.assignedReporterId == userId ||
                t.assignedCameramanId == userId);
      }).toList();

      final completedTasks = taskMap.values
          .where((t) =>
              t.status == "Completed" &&
              (t.createdById == userId ||
                  t.assignedTo == userId ||
                  t.assignedReporterId == userId ||
                  t.assignedCameramanId == userId))
          .toList();

      return TabBarView(
        controller: tabController,
        children: [
          TaskListTab(
            isCompleted: false,
            isDark: isDark,
            tasks: notCompletedTasks,
          ),
          TaskListTab(
            isCompleted: true,
            isDark: isDark,
            tasks: completedTasks,
          ),
        ],
      );
    });
  }
}
