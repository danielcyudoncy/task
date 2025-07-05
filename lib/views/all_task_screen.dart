// views/all_task_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/widgets/app_bar.dart';
import 'package:task/widgets/app_drawer.dart';
import 'package:task/widgets/empty_state_widget.dart';
import 'package:task/widgets/error_state_widget.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxString _selectedFilter = 'All'.obs;
  final RxList<String> _selectedTasks = <String>[].obs;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  

  @override
  void initState() {
    super.initState();
    taskController.loadInitialTasks();
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
      _filterTasks();
    });
  }

  void _filterTasks() {
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

    taskController.tasks.assignAll(filteredTasks);
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
    final basePadding = isLargeScreen ? 32.0 : 16.0;

    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181B2A) : colorScheme.primary,
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
                                            style: const TextStyle(
                                                color: Colors.white)),
                                      ))
                                  .toList(),
                          onChanged: (value) {
                            _selectedFilter.value = value!;
                            _filterTasks();
                          },
                          dropdownColor:
                              isDark ? Colors.grey[900] : Colors.blue,
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
                      color: isDark ? Colors.blueGrey[900] : Colors.blue[100],
                      child: Row(
                        children: [
                          Text(
                            '${_selectedTasks.length} selected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.blue[900],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close,
                                color:
                                    isDark ? Colors.white : Colors.blue[900]),
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
                  return RefreshIndicator(
                    onRefresh: () async {
                      _selectedTasks.clear();
                      await taskController.loadInitialTasks();
                      _filterTasks();
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
                                ? (isDark
                                    ? Colors.blueGrey[800]
                                    : Colors.blue[50])
                                : Colors.transparent,
                            child: TaskCard(
                              data: task.toMapWithUserInfo(
                                  taskController.userNameCache),
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
                                          taskController.userNameCache),
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
