// widgets/task_action_utility.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/models/report_completion_info.dart';
import 'package:task/widgets/report_completion_dialog.dart';
import 'package:task/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';

class TaskActions {
  static void editTask(BuildContext context, dynamic task) {
    final authController = Get.find<AuthController>();
    final userRole = authController.userRole.value.toLowerCase();
    final isAdmin = userRole == 'admin' ||
        userRole == 'administrator' ||
        userRole == 'superadmin';
    final currentUserId = authController.auth.currentUser?.uid;
    // Only allow edit if user is admin or creator
    if (!isAdmin && task.createdById != currentUserId) {
      SnackbarUtils.showError("You do not have permission to edit this task.");
      return;
    }
    final TextEditingController titleController =
        TextEditingController(text: task.title);
    final TextEditingController descriptionController =
        TextEditingController(text: task.description);
    final TextEditingController categoryController =
        TextEditingController(text: task.category ?? '');
    final TextEditingController tagsController =
        TextEditingController(text: task.tags.join(', '));
    final TextEditingController priorityController =
        TextEditingController(text: task.priority ?? '');
    DateTime? dueDate = task.dueDate;
    String status = task.status ?? "Pending";
    String assignedReporter = task.assignedReporter ?? '';
    String assignedCameraman = task.assignedCameraman ?? '';
    String assignedDriver = task.assignedDriver ?? '';
    String assignedLibrarian = task.assignedLibrarian ?? '';
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
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: "Category"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsController,
                decoration:
                    const InputDecoration(labelText: "Tags (comma separated)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priorityController,
                decoration: const InputDecoration(labelText: "Priority"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(dueDate == null
                        ? 'No due date selected'
                        : 'Due: ${DateFormat('MMM dd, yyyy – HH:mm').format(dueDate!)}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final theme = Theme.of(context);

                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          final dialogBg =
                              Theme.of(context).colorScheme.surface;
                          return Theme(
                            data: theme.copyWith(
                              dialogTheme: DialogThemeData(
                                backgroundColor: dialogBg,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        dueDate = picked;
                        (ctx as Element).markNeedsBuild();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Build status options defensively. Some tasks may have statuses
              // (e.g. 'archived') that are not part of the standard list. To
              // avoid DropdownButton assertions we ensure the current status is
              // included in the items and remove duplicates.
              Builder(builder: (context) {
                final List<String> statusOptions = [
                  'Pending',
                  'In Progress',
                  'Completed',
                ];

                // If the task has a status not in the canonical list (for
                // example 'archived'), include it so the dropdown can show
                // the existing value without asserting.
                if (status.isNotEmpty && !statusOptions.contains(status)) {
                  statusOptions.insert(0, status);
                }

                // Deduplicate while preserving order
                final uniqueStatusOptions = statusOptions.toSet().toList();

                return DropdownButtonFormField<String>(
                  initialValue:
                      uniqueStatusOptions.contains(status) ? status : null,
                  decoration: const InputDecoration(labelText: "Status"),
                  items: uniqueStatusOptions
                      .map((String value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) status = newValue;
                  },
                );
              }),
              const SizedBox(height: 12),
              if (isAdmin) ...[
                TextField(
                  decoration:
                      const InputDecoration(labelText: "Assigned Reporter"),
                  controller: TextEditingController(text: assignedReporter),
                  onChanged: (val) => assignedReporter = val,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration:
                      const InputDecoration(labelText: "Assigned Cameraman"),
                  controller: TextEditingController(text: assignedCameraman),
                  onChanged: (val) => assignedCameraman = val,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration:
                      const InputDecoration(labelText: "Assigned Driver"),
                  controller: TextEditingController(text: assignedDriver),
                  onChanged: (val) => assignedDriver = val,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration:
                      const InputDecoration(labelText: "Assigned Librarian"),
                  controller: TextEditingController(text: assignedLibrarian),
                  onChanged: (val) => assignedLibrarian = val,
                ),
              ],
              // Attachments and comments can be added here as needed
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.onSurface,
            ),
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
                // Add more fields to updateTask if needed
              );
              // You may need to call a more complete update method to save all fields
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

  static Future<void> deleteTask(dynamic task) async {
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

      debugPrint(
          'CompleteTask - User Role: $userRole, CurrentUserId: $currentUserId');
      debugPrint('Task AssignedReporterId: ${task.assignedReporterId}');

      // If user is a reporter, show completion dialog
      if (userRole == "Reporter" && task.assignedReporterId == currentUserId) {
        debugPrint('Showing ReportCompletionDialog for reporter');
        final result = await Get.dialog<ReportCompletionInfo>(
          ReportCompletionDialog(
            onComplete: (info) {
              debugPrint(
                  'ReportCompletionDialog - onComplete called with info: ${info.toMap()}');
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
          SnackbarUtils.showSuccess(
              "Task marked as completed with report details");
        } else {
          debugPrint('User cancelled completion dialog');
        }
      } else {
        debugPrint('Marking task as completed for non-reporter user');
        await taskController.markTaskCompletedByUser(
            task.taskId, currentUserId);
        SnackbarUtils.showSuccess("Task marked as completed");
      }
    } catch (e, stackTrace) {
      debugPrint('Error completing task: $e');
      debugPrint('Stack trace: $stackTrace');
      SnackbarUtils.showError("Failed to complete task: ${e.toString()}");
    }
  }
}
