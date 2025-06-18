// views/all_task_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/widgets/app_bar.dart';
import 'package:task/widgets/empty_state_widget.dart';
import 'package:task/widgets/error_state_widget.dart';
import 'package:task/widgets/filter_bar.dart';
import 'package:task/widgets/task_card.dart';
import 'package:task/widgets/task_detail_sheet.dart';
import 'package:task/widgets/task_skeleton_list.dart';
import 'package:task/widgets/user_nav_bar.dart';

class AllTaskScreen extends StatefulWidget {
  const AllTaskScreen({super.key});

  @override
  State<AllTaskScreen> createState() => _AllTaskScreenState();
}

class _AllTaskScreenState extends State<AllTaskScreen> {
  final TaskController taskController = Get.find<TaskController>();

  @override
  void initState() {
    super.initState();
    taskController.loadInitialTasks();
  }

  void _onSearch(String val) {
    taskController.loadInitialTasks(search: val.trim());
  }

  void _onFilter(String? val) {
    if (val != null) {
      taskController.loadInitialTasks(filter: val);
    }
  }

  void _onSort(String? val) {
    if (val != null) {
      taskController.loadInitialTasks(sort: val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLargeScreen = media.size.width > 600;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final basePadding = isLargeScreen ? 32.0 : 16.0;

    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black : colorScheme.primary,
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBarWidget(basePadding: basePadding),
              FilterBarWidget(
                basePadding: basePadding,
                textScale: textScale,
                filterStatus: taskController.filterStatus,
                sortBy: taskController.sortBy,
                onSearch: _onSearch,
                onFilter: _onFilter,
                onSort: _onSort,
              ),
              Expanded(
                child: Obx(() {
                  if (taskController.isLoading.value &&
                      taskController.tasks.isEmpty) {
                    return TaskSkeletonList(
                        isLargeScreen: isLargeScreen, textScale: textScale);
                  }
                  if (taskController.errorMessage.isNotEmpty) {
                    return ErrorStateWidget(
                      message: taskController.errorMessage.value,
                      onRetry: () => taskController.loadInitialTasks(),
                    );
                  }
                  if (taskController.tasks.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.list_alt_outlined,
                      title: "No tasks found",
                      message: "Try adjusting your filters or search.",
                    );
                  }
                  return NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (!taskController.isLoading.value &&
                          taskController.hasMore &&
                          scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent - 100) {
                        taskController.loadMoreTasks();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                          horizontal: isLargeScreen ? 32 : 8, vertical: 20),
                      itemCount: taskController.tasks.length +
                          (taskController.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => Divider(
                        color: dividerColor,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        if (index >= taskController.tasks.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final task = taskController.tasks[index];
                        return TaskCard(
                          data: task
                              .toMapWithUserInfo(taskController.userNameCache),
                          isLargeScreen: isLargeScreen,
                          textScale: textScale,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24)),
                            ),
                            builder: (_) => TaskDetailSheet(
                              data: task.toMapWithUserInfo(
                                  taskController.userNameCache),
                              textScale: textScale,
                              isDark: isDark,
                            ),
                          ),
                          onAction: (choice) =>
                              _handleTaskAction(choice, task, context),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const UserNavBar(currentIndex: 1),
    );
  }

  Future<void> _handleTaskAction(
      String choice, dynamic task, BuildContext context) async {
    if (choice == 'Edit') {
      Get.toNamed('/edit_task', arguments: task);
    } else if (choice == 'Delete') {
      bool? confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete Task"),
          content: const Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete")),
          ],
        ),
      );
      if (confirm == true) {
        await taskController.deleteTask(task.taskId);
      }
    } else if (choice == 'Mark as Completed') {
      await taskController.updateTaskStatus(task.taskId, "Completed");
    }
  }
}
