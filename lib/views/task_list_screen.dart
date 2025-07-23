// views/task_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/widgets/user_nav_bar.dart';
import '../controllers/task_controller.dart';
import '../controllers/auth_controller.dart';
import 'package:intl/intl.dart';

class TaskListScreen extends StatelessWidget {
  final TaskController taskController = Get.find<TaskController>();
  final AuthController authController = Get.find<AuthController>();

  // Add these controllers and variable at the top of the class
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  DateTime? selectedDueDate;

  TaskListScreen({super.key, this.selectedDueDate});

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

        // CORRECT: Filter tasks for role using userId
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
            // Debug print for userNameCache and relevant UIDs
            debugPrint('userNameCache for createdById=${task.createdById}: ${taskController.userNameCache[task.createdById]}');
            debugPrint('userNameCache for assignedReporterId=${task.assignedReporterId}: ${taskController.userNameCache[task.assignedReporterId ?? "null"]}');
            debugPrint('userNameCache for assignedCameramanId=${task.assignedCameramanId}: ${taskController.userNameCache[task.assignedCameramanId ?? "null"]}');
            final creatorName = taskController.userNameCache[task.createdById] ?? 'Unknown';
            final assignedReporterName = task.assignedReporterId != null
                ? (taskController.userNameCache[task.assignedReporterId] ?? 'Unknown')
                : 'None';
            final assignedCameramanName = task.assignedCameramanId != null
                ? (taskController.userNameCache[task.assignedCameramanId] ?? 'Unknown')
                : 'None';
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                title: Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${'created_by'.tr}: $creatorName'),
                    Text('${'assigned_reporter'.tr}: $assignedReporterName'),
                    Text('${'assigned_cameraman'.tr}: $assignedCameramanName'),
                    Text('${'status'.tr}: ${task.status}'),
                    Text('${'due_date'.tr}: ${task.dueDate != null ? DateFormat('yyyy-MM-dd – kk:mm').format(task.dueDate!) : 'N/A'}'),
                    Text('${'category'.tr}: ${task.category ?? 'N/A'}'),
                    Text('${'tags'.tr}: ${task.tags.isNotEmpty ? task.tags.join(', ') : 'N/A'}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusIndicator(task.status),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showUpdateTaskDialog(context, task),
                    ),
                  ],
                ),
                onTap: () => _showUpdateTaskDialog(context, task),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const UserNavBar(currentIndex: 1),
    );
  }

  // Task Status Indicator
  Widget _buildStatusIndicator(String status) {
    Color statusColor = status == "Completed" ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Show dialog to update task
  void _showUpdateTaskDialog(BuildContext context, dynamic task) {
    final TextEditingController titleController =
        TextEditingController(text: task.title);
    final TextEditingController descriptionController =
        TextEditingController(text: task.description);
    String currentStatus = task.status;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Task'),
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
                DropdownButtonFormField<String>(
                  value: currentStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Pending', 'In Progress', 'Completed']
                      .map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      currentStatus = newValue;
                    }
                  },
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
                taskController.updateTask(
                  task.taskId,
                  titleController.text,
                  descriptionController.text,
                  currentStatus,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to add a new task
  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    // Use the above categoryController, tagsController, selectedDueDate

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                          child: Text(selectedDueDate == null
                              ? 'No due date selected'
                              : 'Due: ${selectedDueDate!.toString().split(' ')[0]}'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
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
                      category: categoryController.text.trim().isNotEmpty ? categoryController.text.trim() : null,
                      tags: tagsController.text.trim().isNotEmpty
                          ? tagsController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                          : [],
                      dueDate: selectedDueDate,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
