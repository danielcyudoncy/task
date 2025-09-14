// views/task_list_screen.dart
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

  final TextEditingController categoryController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  DateTime? selectedDueDate;

  @override
  Widget build(BuildContext context) {

    
    return Scaffold(
      appBar: AppBar(title: Text('all_tasks'.tr)),
      body: Obx(() {
        if (taskController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (taskController.tasks.isEmpty) {
          return Center(
            child: Text(
              'no_tasks_available'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        String userRole = authController.userRole.value;
        String userId = authController.auth.currentUser?.uid ?? "";

        var filteredTasks = taskController.tasks.where((task) {
          if (userRole == "Reporter") {
            return task.assignedReporterId == userId ||
                task.createdById == userId;
          } else if (userRole == "Cameraman") {
            return task.assignedCameramanId == userId ||
                task.createdById == userId;
          } else if (userRole == "Driver") {
            return task.assignedDriverId == userId ||
                task.createdById == userId;
          } else if (userRole == "Librarian") {
            return task.assignedLibrarianId == userId ||
                task.createdById == userId;
          }
          return true;
        }).toList();

        if (filteredTasks.isEmpty) {
          return Center(
            child: Text(
              'no_tasks_for_role'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            var task = filteredTasks[index];

            return TaskCardWidget(
              task: task,
              isCompleted: task.status == 'Completed',
              isDark: false,
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar:  UserNavBar(currentIndex: 1),
    );
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
                                  colorScheme: Theme.of(context).colorScheme.copyWith(
                                    primary: Theme.of(context).colorScheme.primary,
                                    onPrimary: Theme.of(context).colorScheme.onPrimary,
                                    surface: Theme.of(context).colorScheme.surface,
                                    onSurface: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.primary,
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
