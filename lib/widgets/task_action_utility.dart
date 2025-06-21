// widgets/task_action_utility.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';

class TaskActions {
  static void editTask(BuildContext context, dynamic task) {
    final TextEditingController titleController =
        TextEditingController(text: task.title);
    final TextEditingController descriptionController =
        TextEditingController(text: task.description);
    String status = task.status ?? "Pending";
    final taskController = Get.find<TaskController>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Task"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: "Status"),
                items: ['Pending', 'In Progress', 'Completed']
                    .map((String value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) status = newValue;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await taskController.updateTask(
                task.taskId,
                titleController.text,
                descriptionController.text,
                status,
              );
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              Get.snackbar("Success", "Task updated successfully",
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  static void deleteTask(dynamic task) async {
    final taskController = Get.find<TaskController>();
    await taskController.deleteTask(task.taskId);
    Get.snackbar("Success: Success", "Task deleted",
        snackPosition: SnackPosition.BOTTOM);
  }

  static void completeTask(dynamic task) async {
    final taskController = Get.find<TaskController>();
    await taskController.updateTaskStatus(task.taskId, "Completed");
    Get.snackbar("Success", "Task marked as completed",
        snackPosition: SnackPosition.BOTTOM);
  }
}
