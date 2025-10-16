// screens/all_task_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/models/task.dart';
import 'package:task/widgets/app_bar.dart';
import 'package:task/widgets/app_drawer.dart';
import 'package:task/widgets/empty_state_widget.dart';
import 'package:task/widgets/error_state_widget.dart';
import 'package:task/widgets/minimal_task_card.dart';
import 'package:task/widgets/task_detail_modal.dart';
import 'package:task/widgets/task_skeleton_list.dart';
import 'package:task/widgets/user_nav_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task/utils/devices/app_devices.dart';

class AllTaskScreen extends StatefulWidget {
  const AllTaskScreen({super.key});

  @override
  State<AllTaskScreen> createState() => _AllTaskScreenState();
}

class _AllTaskScreenState extends State<AllTaskScreen> {
  final TaskController taskController = Get.find<TaskController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxString _selectedFilter = 'All'.obs;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RxList<Task> _filteredTasks = <Task>[].obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await taskController.loadAllTasksForAllUsers();
      // Debug print to verify creator names
      for (var task in taskController.tasks) {
        debugPrint(
            'Task ${task.title} - Creator: ${task.createdByName ?? task.createdBy} (ID: ${task.createdById})');
      }
    });
    _searchController
        .addListener(() => _searchQuery.value = _searchController.text);

    // Listen to task list changes
    ever(taskController.tasks, (_) {
      _filterTasks();
    });

    // Listen to search query changes for real-time filtering
    ever(_searchQuery, (_) {
      _filterTasks();
    });

    // Listen to filter changes
    ever(_selectedFilter, (_) {
      _filterTasks();
    });
  }

  void _filterTasks() {
    final filteredTasks = taskController.tasks.where((task) {
      final searchLower = _searchQuery.value.toLowerCase();
      final matchesSearch = _searchQuery.value.isEmpty ||
          task.title.toLowerCase().contains(searchLower) ||
          task.description.toLowerCase().contains(searchLower) ||
          task.createdBy.toLowerCase().contains(searchLower) ||
          task.status.toLowerCase().contains(searchLower) ||
          (task.assignedReporter?.toLowerCase().contains(searchLower) ??
              false) ||
          (task.assignedCameraman?.toLowerCase().contains(searchLower) ??
              false) ||
          (task.assignedDriver?.toLowerCase().contains(searchLower) ?? false) ||
          (task.assignedLibrarian?.toLowerCase().contains(searchLower) ??
              false) ||
          (task.category?.toLowerCase().contains(searchLower) ?? false) ||
          (task.priority?.toLowerCase().contains(searchLower) ?? false) ||
          task.tags.any((tag) => tag.toLowerCase().contains(searchLower)) ||
          task.comments
              .any((comment) => comment.toLowerCase().contains(searchLower));

      final matchesFilter = _selectedFilter.value == 'All' ||
          (_selectedFilter.value == 'Completed' &&
              task.status == 'Completed' &&
              task.isCompletedByAllAssignedUsers) ||
          (_selectedFilter.value == 'Pending' && task.status == 'Pending');

      return matchesSearch && matchesFilter;
    }).toList();

    _filteredTasks.assignAll(filteredTasks);
  }

  void _showTaskDetail(Task task) {
    Get.find<SettingsController>().triggerFeedback();
    showDialog(
      context: context,
      builder: (context) => TaskDetailModal(
        task: task,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = AppDevices.getScreenWidth(context);
    final isLargeScreen = screenWidth > 600;
    final basePadding = isLargeScreen ? 32.0.w : 16.0.w;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = AppDevices.isTablet(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Theme.of(context).canvasColor
              : Theme.of(context).colorScheme.primary,
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBarWidget(basePadding: basePadding, scaffoldKey: _scaffoldKey),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: basePadding, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: isTablet ? 3 : 1,
                      child: SizedBox(
                        width: isTablet ? screenWidth * 0.6 : screenWidth * 0.7,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search tasks...',
                            hintStyle: TextStyle(
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[600],
                            ),
                            prefixIcon: Icon(Icons.search,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                size: isTablet ? 24 : 20),
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey[900] : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(isTablet ? 16 : 12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: isTablet ? 16 : 12,
                              horizontal: isTablet ? 16 : 12,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    Obx(() => DropdownButton<String>(
                          value: _selectedFilter.value,
                          items: ['All', 'Completed', 'Pending']
                              .map((filter) => DropdownMenuItem(
                                    value: filter,
                                    child: Text(filter,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            _selectedFilter.value = value!;
                          },
                          dropdownColor: isDark
                              ? Colors.grey[900]
                              : Theme.of(context).colorScheme.primary,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface),
                        )),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (!Get.isRegistered<TaskController>()) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (taskController.isLoading.value &&
                      _filteredTasks.isEmpty) {
                    return TaskSkeletonList(
                        isLargeScreen: isLargeScreen,
                        textScale: MediaQuery.textScalerOf(context).scale(1.0));
                  }

                  if (taskController.errorMessage.isNotEmpty) {
                    return ErrorStateWidget(
                      message: taskController.errorMessage.value,
                      onRetry: () => taskController.loadAllTasksForAllUsers(),
                    );
                  }

                  if (_filteredTasks.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.list_alt_outlined,
                      title: "no_tasks_found".tr,
                      message: "try_adjusting_your_filters_or_search".tr,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await taskController.loadAllTasksForAllUsers();
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                          horizontal:
                              isTablet ? 24.w : (isLargeScreen ? 16.w : 8.w),
                          vertical: isTablet ? 20 : 16),
                      itemCount: _filteredTasks.length +
                          (taskController.hasMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index >= _filteredTasks.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final task = _filteredTasks[index];
                        return MinimalTaskCard(
                          key: ValueKey(task.taskId),
                          task: task,
                          isDark: isDark,
                          onTap: () => _showTaskDetail(task),
                          enableSwipeToDelete: false,
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
      bottomNavigationBar: UserNavBar(currentIndex: 1),
    );
  }
}
