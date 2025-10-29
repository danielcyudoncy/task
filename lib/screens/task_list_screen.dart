// screens/task_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/task_controller.dart';
import '../controllers/auth_controller.dart';
import '../service/user_cache_service.dart';
import '../widgets/task_card_widget.dart';
import '../widgets/user_nav_bar.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskController taskController = Get.find<TaskController>();
  final AuthController authController = Get.find<AuthController>();
  final UserCacheService userCacheService = Get.find<UserCacheService>();

  // Search and filter controllers
  final TextEditingController searchController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final TextEditingController assignedToController = TextEditingController();
  
  DateTime? selectedDueDate;
  String selectedStatusFilter = 'All';
  
  // Filter options
  final List<String> statusOptions = ['All', 'Pending', 'In Progress', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('all_tasks'.tr),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'search_tasks'.tr,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild for real-time search
              },
            ),
          ),
          
          // Quick Filters Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: Text(selectedStatusFilter),
                    selected: selectedStatusFilter != 'All',
                    onSelected: (selected) {
                      setState(() {
                        selectedStatusFilter = selected ? selectedStatusFilter : 'All';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: _clearAllFilters,
                ),
              ],
            ),
          ),
          
          // Tasks List
          Expanded(
            child: Obx(() {
              if (taskController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Show all tasks for all users - no role filtering
              var filteredTasks = _applySearchAndFilters();

              if (filteredTasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        searchController.text.isNotEmpty || 
                        selectedStatusFilter != 'All'
                            ? 'no_tasks_match_filters'.tr
                            : 'no_tasks_available'.tr,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        searchController.text.isNotEmpty || 
                        selectedStatusFilter != 'All'
                            ? 'try_adjusting_your_filters'.tr
                            : '',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Refresh tasks
                  await taskController.fetchRelevantTasksForUser();
                },
                child: ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    var task = filteredTasks[index];

                    return TaskCardWidget(
                      task: task,
                      isCompleted: task.status == 'Completed',
                      isDark: false,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: UserNavBar(currentIndex: 1),
    );
  }

  // Apply search and filter logic
  List _applySearchAndFilters() {
    var tasks = taskController.tasks.toList(); // Convert RxList to List

    // Apply search filter
    if (searchController.text.isNotEmpty) {
      final searchQuery = searchController.text.toLowerCase();
      tasks = tasks.where((task) {
        return task.title.toLowerCase().contains(searchQuery) ||
            task.description.toLowerCase().contains(searchQuery) ||
            (task.category ?? '').toLowerCase().contains(searchQuery) ||
            (task.tags).any((tag) => tag.toLowerCase().contains(searchQuery));
      }).toList();
    }

    // Apply status filter
    if (selectedStatusFilter != 'All') {
      tasks = tasks.where((task) => 
          task.status.toLowerCase() == selectedStatusFilter.toLowerCase()
      ).toList();
    }

    return tasks;
  }

  void _clearAllFilters() {
    setState(() {
      searchController.clear();
      selectedStatusFilter = 'All';
    });
  }

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma separated)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDueDate == null
                              ? 'No due date selected'
                              : 'Due: ${selectedDueDate!.toString().split(' ')[0]}',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme:
                                      Theme.of(context).colorScheme.copyWith(
                                            primary: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            onPrimary: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            surface: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            onSurface: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDueDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty ||
                      descriptionController.text.trim().isEmpty) {
                    Get.snackbar("Error", "Please fill in all fields.");
                    return;
                  }

                  taskController.createTask(
                    titleController.text.trim(),
                    descriptionController.text.trim(),
                    category: categoryController.text.trim().isNotEmpty
                        ? categoryController.text.trim()
                        : null,
                    tags: tagsController.text.trim().isNotEmpty
                        ? tagsController.text
                            .trim()
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList()
                        : [],
                    dueDate: selectedDueDate,
                  );

                  Navigator.of(context).pop();
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }
}
