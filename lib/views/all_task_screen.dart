// views/all_task_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/models/task_model.dart';
import 'package:task/widgets/app_bar.dart';
import 'package:task/widgets/app_drawer.dart';
import 'package:task/widgets/empty_state_widget.dart';
import 'package:task/widgets/error_state_widget.dart';
import 'package:task/widgets/task_card.dart';
import 'package:task/widgets/task_detail_sheet.dart';
import 'package:task/widgets/task_skeleton_list.dart';
import 'package:task/widgets/user_nav_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  final RxList<String> _selectedTasks = <String>[].obs;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RxList<Task> _filteredTasks = <Task>[].obs;
  

  @override
  void initState() {
    super.initState();
    debugPrint("AllTaskScreen: initState called");
    debugPrint("AllTaskScreen: TaskController registered: "+Get.isRegistered<TaskController>().toString());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      taskController.loadAllTasksForAllUsers();
    });
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
      _filterTasks();
    });
    
    // Listen to task changes and update filtered tasks
    ever(taskController.tasks, (_) {
      debugPrint("AllTaskScreen: tasks changed, calling _filterTasks");
      _filterTasks();
    });
  }

  void _filterTasks() {
    debugPrint("AllTaskScreen: _filterTasks called");
    debugPrint("AllTaskScreen: taskController.tasks.length = ${taskController.tasks.length}");
    debugPrint("AllTaskScreen: searchQuery = '${_searchQuery.value}'");
    debugPrint("AllTaskScreen: selectedFilter = '${_selectedFilter.value}'");
    
    final filteredTasks = taskController.tasks.where((task) {
      final matchesSearch =
          task.title.toLowerCase().contains(_searchQuery.value.toLowerCase()) ||
              task.description
                  .toLowerCase()
                  .contains(_searchQuery.value.toLowerCase());

      final matchesFilter = _selectedFilter.value == 'All' ||
          (_selectedFilter.value == 'Completed' &&
              task.status == 'Completed') ||
          (_selectedFilter.value == 'Pending' && task.status == 'Pending');
      

      return matchesSearch && matchesFilter;
    }).toList();

    debugPrint("AllTaskScreen: filteredTasks.length = ${filteredTasks.length}");
    _filteredTasks.assignAll(filteredTasks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLargeScreen = media.size.width > 600;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final basePadding = isLargeScreen ? 32.0.w : 16.0.w;

    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).canvasColor
              : Theme.of(context).colorScheme.primary,
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBarWidget(
                basePadding: basePadding,
                scaffoldKey: _scaffoldKey,
              ),
              // Search and Filter Row
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: basePadding, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
                          prefixIcon:
                              Icon(Icons.search, color: colorScheme.onSurface),
                          filled: true,
                          fillColor:
                              isDark ? Colors.grey[900] : Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(() => DropdownButton<String>(
                          value: _selectedFilter.value,
                          items:
                              ['All', 'Completed', 'Pending']
                                  .map((filter) => DropdownMenuItem(
                                        value: filter,
                                        child: Text(filter,
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ))
                                  .toList(),
                          onChanged: (value) {
                            _selectedFilter.value = value!;
                            _filterTasks();
                          },
                          dropdownColor:
                              isDark ? Colors.grey[900] : colorScheme.primary,
                          style: TextStyle(color: colorScheme.onSurface),
                        )),
                  ],
                ),
              ),
              // Batch Selection Indicator
              Obx(() => _selectedTasks.isNotEmpty
                  ? Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 8, horizontal: basePadding),
                      color: isDark ? Colors.blueGrey[900] : colorScheme.primary.withOpacity(0.1),
                      child: Row(
                        children: [
                          Text(
                            '${_selectedTasks.length} selected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close,
                                color:
                                    isDark ? Colors.white : colorScheme.primary),
                            onPressed: () {
                              Get.find<SettingsController>().triggerFeedback();
                              _selectedTasks.clear();
                            },
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink()),
              // Main Content
              Expanded(
                child: Obx(() {
                  // Add safety check to ensure controller is registered
                  if (!Get.isRegistered<TaskController>()) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (taskController.isLoading.value &&
                      _filteredTasks.isEmpty) {
                    return TaskSkeletonList(
                        isLargeScreen: isLargeScreen, textScale: textScale);
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
                      _selectedTasks.clear();
                      await taskController.loadAllTasksForAllUsers();
                      _filterTasks();
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                          horizontal: isLargeScreen ? 32.w : 8.w, vertical: 20),
                      itemCount: _filteredTasks.length +
                          (taskController.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => Divider(
                        color: dividerColor,
                        thickness: 1,
                        indent: 16.w,
                        endIndent: 16.w,
                      ),
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
                        return GestureDetector(
                          onLongPress: () {
                            if (_selectedTasks.contains(task.taskId)) {
                              _selectedTasks.remove(task.taskId);
                            } else {
                              _selectedTasks.add(task.taskId);
                            }
                          },
                          child: Container(
                            color: _selectedTasks.contains(task.taskId)
                                ? colorScheme.surfaceVariant
                                : Colors.transparent,
                            child: TaskCard(
                              data: task.toMapWithUserInfo(
                                  taskController.userNameCache,
                                  taskController.userAvatarCache),
                              isLargeScreen: isLargeScreen,
                              textScale: textScale,
                              onTap: () {
                                Get.find<SettingsController>()
                                    .triggerFeedback();
                                if (_selectedTasks.isNotEmpty) {
                                  if (_selectedTasks.contains(task.taskId)) {
                                    _selectedTasks.remove(task.taskId);
                                  } else {
                                    _selectedTasks.add(task.taskId);
                                  }
                                } else {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24)),
                                    ),
                                    builder: (_) => TaskDetailSheet(
                                      data: task.toMapWithUserInfo(
                                          taskController.userNameCache,
                                          taskController.userAvatarCache),
                                      textScale: textScale,
                                      isDark: isDark,
                                    ),
                                  );
                                }
                              },
                              onAction:
                                  (_) {}, // Empty function for view-only mode
                            ),
                          ),
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
}
