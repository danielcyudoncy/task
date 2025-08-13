// widgets/task_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/settings_controller.dart';
import './task_action_utility.dart';
import 'package:task/models/task_model.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/task_controller.dart';


class TaskCardWidget extends StatelessWidget {
  final Task task;
  final bool isCompleted;
  final bool isDark;

  const TaskCardWidget({
    super.key,
    required this.task,
    required this.isCompleted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = Get.find<AuthController>().auth.currentUser?.uid;
    final isTaskOwner = task.createdById == currentUserId;
    final isAssignedUser =
        task.assignedReporterId == currentUserId ||
        task.assignedCameramanId == currentUserId ||
        task.assignedDriverId == currentUserId ||
        task.assignedLibrarianId == currentUserId ||
        task.assignedTo == currentUserId;
    
    // Use the same color scheme as admin dashboard
    final Color cardColor = isDark 
        ? const Color(0xFF292B3A) 
        : Theme.of(context).primaryColor;
    const Color textColor = Colors.white;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey[600]!;
    final Color borderColor = colorScheme.outline.withAlpha((0.3 * 255).toInt());

    // Debug prints for diagnosis
    debugPrint(
      'TaskCardWidget: taskId= [32m${task.taskId} [0m, '
      'dueDate= [32m${task.dueDate} [0m, '
      'category= [32m${task.category} [0m, '
      'tags= [32m${task.tags} [0m'
    );

    return Dismissible(
      key: ValueKey(task.taskId),
      background: !isCompleted ? _buildCompleteBackground() : Container(),
      secondaryBackground: _buildDeleteBackground(),
      confirmDismiss: (direction) => _handleDismiss(context, direction),
      onDismissed: (direction) => _handleDismissed(direction),
      child: GestureDetector(
        onTap: () => _showTaskDetails(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 7.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withAlpha((0.38 * 255).round()) : const Color(0x22000000),
                  blurRadius: 8,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title, 
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  task.description,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                // Creator info
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: subTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Created by: ${_getCreatorName()}',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Assigned Reporter
                Text(
                  'Assigned Reporter: ${_getAssignedReporterName()}',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                // Assigned Cameraman
                Text(
                  'Assigned Cameraman: ${_getAssignedCameramanName()}',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                // Assigned Driver
                Text(
                  'Assigned Driver: ${_getAssignedDriverName()}',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                // Status
                Text(
                  'Status: ${task.status}',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                // Tags
                if (task.tags.isNotEmpty)
                  Text(
                    'Tags: ${task.tags.join(', ')}',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                const SizedBox(height: 4),
                // Priority
                if (task.priority != null)
                  Text(
                    'Priority: ${task.priority}',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                const SizedBox(height: 4),
                // Due Date
                if (task.dueDate != null)
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy – HH:mm').format(task.dueDate!)}',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                const SizedBox(height: 8),
                // Comments count
                Row(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 14,
                      color: subTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Comments: ${task.comments.length}',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Action buttons
                if (isTaskOwner || isAssignedUser)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isCompleted)
                        ElevatedButton(
                          onPressed: () {
                            Get.find<SettingsController>().triggerFeedback();
                            _markAsCompleted();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 8.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Complete',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            color: Colors.red[400], size: 22.sp),
                        onPressed: () {
                          Get.find<SettingsController>().triggerFeedback();
                          if (isTaskOwner) {
                            TaskActions.deleteTask(task);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.edit_note_rounded,
                            color: textColor, size: 22.sp),
                        onPressed: () {
                          Get.find<SettingsController>().triggerFeedback();
                          TaskActions.editTask(context, task);
                        },
                        tooltip: "Edit Task",
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(task.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Description: ${task.description}'),
                const SizedBox(height: 8),
                Text('Status: ${task.status}'),
                const SizedBox(height: 8),
                Text('Category: ${task.category ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Due Date: ${task.dueDate != null ? DateFormat('yyyy-MM-dd – kk:mm').format(task.dueDate!) : 'N/A'}'),
                const SizedBox(height: 8),
                Text('Tags: ${task.tags.isNotEmpty ? task.tags.join(', ') : 'None'}'),
                const SizedBox(height: 8),
                Text('Creator: ${_getCreatorName()}'),
                const SizedBox(height: 8),
                Text('Reporter: ${_getAssignedReporterName()}'),
                const SizedBox(height: 8),
                Text('Cameraman: ${_getAssignedCameramanName()}'),
                const SizedBox(height: 8),
                Text('Driver: ${_getAssignedDriverName()}'),
                const SizedBox(height: 16),
                if (task.comments.isNotEmpty) ...[
                  const Text('Comments:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...task.comments.map((comment) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $comment'),
                  )),
                ] else
                  const Text('No comments available.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompleteBackground() {
    return Container(
      color: Colors.green[600],
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      child: const Row(
        children: [
          Icon(Icons.check, color: Colors.white, size: 30),
          SizedBox(width: 10),
          Text(
            'Complete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      color: Colors.red[600],
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 10),
          Icon(Icons.delete, color: Colors.white, size: 30),
        ],
      ),
    );
  }

  Future<bool?> _handleDismiss(BuildContext context, DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd && !isCompleted) {
      return await _showCompleteConfirmation(context);
    } else if (direction == DismissDirection.endToStart) {
      return await _showDeleteConfirmation(context);
    }
    return false;
  }

  void _handleDismissed(DismissDirection direction) {
    if (direction == DismissDirection.startToEnd && !isCompleted) {
      _markAsCompleted();
    } else if (direction == DismissDirection.endToStart) {
      TaskActions.deleteTask(task);
    }
  }

  Future<bool?> _showCompleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Mark as Completed"),
        content: Text("Are you sure you want to mark '${task.title}' as completed?"),
        actions: [
          TextButton(
            onPressed: () {
              Get.find<SettingsController>().triggerFeedback();
              Navigator.of(ctx).pop(false);
            },
            child: Text(
              "Cancel", 
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.find<SettingsController>().triggerFeedback();
              Navigator.of(ctx).pop(true);
            },
            child: Text(
              "Complete", 
              style: TextStyle(
                      color: isDark ? Colors.green[300] : Colors.green[700]
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Task"),
        content: Text("Are you sure you want to delete '${task.title}'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () {
              Get.find<SettingsController>().triggerFeedback();
              Navigator.of(ctx).pop(false);
            },
            child: Text(
              "Cancel", 
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.find<SettingsController>().triggerFeedback();
              Navigator.of(ctx).pop(true);
            },
            child: Text(
              "Delete", 
              style: TextStyle(
                      color: isDark ? Colors.red[300] : Colors.red[600]
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCreatorName() {
    try {
      final taskController = Get.find<TaskController>();
      
      // Check if we have a cached name
      if (task.createdById.isNotEmpty &&
          taskController.userNameCache.containsKey(task.createdById)) {
        return taskController.userNameCache[task.createdById]!;
      }
      
      // Fallback to createdBy field
      if (task.createdBy.isNotEmpty) {
        return task.createdBy;
      }
      
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getAssignedReporterName() {
    try {
      if (task.assignedReporterId == null) return 'Not Assigned';
      final taskController = Get.find<TaskController>();
      
      // Check cache first
      if (taskController.userNameCache.containsKey(task.assignedReporterId!)) {
        return taskController.userNameCache[task.assignedReporterId!]!;
      }
      
      // Fallback to task field
      if (task.assignedReporter != null && task.assignedReporter!.isNotEmpty) {
        return task.assignedReporter!;
      }
      
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getAssignedCameramanName() {
    try {
      if (task.assignedCameramanId == null) return 'Not Assigned';
      final taskController = Get.find<TaskController>();
      
      // Check cache first
      if (taskController.userNameCache.containsKey(task.assignedCameramanId!)) {
        return taskController.userNameCache[task.assignedCameramanId!]!;
      }
      
      // Fallback to task field
      if (task.assignedCameraman != null && task.assignedCameraman!.isNotEmpty) {
        return task.assignedCameraman!;
      }
      
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getAssignedDriverName() {
    try {
      if (task.assignedDriverId == null) return 'Not Assigned';
      final taskController = Get.find<TaskController>();
      
      // Check cache first
      if (taskController.userNameCache.containsKey(task.assignedDriverId!)) {
        return taskController.userNameCache[task.assignedDriverId!]!;
      }
      
      // Fallback to task field
      if (task.assignedDriver != null && task.assignedDriver!.isNotEmpty) {
        return task.assignedDriver!;
      }
      
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _markAsCompleted() {
    final taskController = Get.find<TaskController>();
    taskController.updateTaskStatus(task.taskId, 'Completed');
  }
}
