// widgets/task_action_utility.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/models/report_completion_info.dart';
import 'package:task/widgets/report_completion_dialog.dart';
import 'package:task/utils/snackbar_utils.dart';

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
                initialValue: status,
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
          TextButton(style: TextButton.styleFrom(
            foregroundColor: Colors.red,),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel",),
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
              SnackbarUtils.showSuccess("Task updated successfully");
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
    SnackbarUtils.showSuccess("Task deleted");
  }

  static void completeTask(dynamic task) async {
    try {
      final taskController = Get.find<TaskController>();
      final authController = Get.find<AuthController>();
      final currentUserId = authController.auth.currentUser?.uid;
      final userRole = authController.userRole.value;
      
      if (currentUserId == null) {
        SnackbarUtils.showError("User not authenticated");
        return;
      }
      
      debugPrint('CompleteTask - User Role: $userRole, CurrentUserId: $currentUserId');
      debugPrint('Task AssignedReporterId: ${task.assignedReporterId}');
      
      // If user is a reporter, show completion dialog
      if (userRole == "Reporter" && task.assignedReporterId == currentUserId) {
        debugPrint('Showing ReportCompletionDialog for reporter');
        final result = await Get.dialog<ReportCompletionInfo>(
          ReportCompletionDialog(
            onComplete: (info) {
              debugPrint('ReportCompletionDialog - onComplete called with info: ${info.toMap()}');
              return Get.back(result: info);
            },
          ),
          barrierDismissible: false,
        );
        
        if (result != null) {
          debugPrint('Submitting task completion with reporter info');
          await taskController.markTaskCompletedByUser(
            task.taskId,
            currentUserId,
            reportCompletionInfo: result,
          );
          SnackbarUtils.showSuccess("Task marked as completed with report details");
        } else {
          debugPrint('User cancelled completion dialog');
        }
      } else {
        debugPrint('Marking task as completed for non-reporter user');
        await taskController.markTaskCompletedByUser(task.taskId, currentUserId);
        SnackbarUtils.showSuccess("Task marked as completed");
      }
    } catch (e, stackTrace) {
      debugPrint('Error completing task: $e');
      debugPrint('Stack trace: $stackTrace');
      SnackbarUtils.showError("Failed to complete task: ${e.toString()}");
    }
  }
}
