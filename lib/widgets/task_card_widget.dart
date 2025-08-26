// widgets/task_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/settings_controller.dart';
import '../widgets/task_review_dialog.dart';
import './task_action_utility.dart';
import 'package:task/models/task_model.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/task_controller.dart';


class TaskCardWidget extends StatefulWidget {
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
  State<TaskCardWidget> createState() => _TaskCardWidgetState();
}

class _TaskCardWidgetState extends State<TaskCardWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = Get.find<AuthController>().auth.currentUser?.uid;
    final isTaskOwner = widget.task.createdById == currentUserId;
    final isAssignedUser =
        widget.task.assignedReporterId == currentUserId ||
        widget.task.assignedCameramanId == currentUserId ||
        widget.task.assignedDriverId == currentUserId ||
        widget.task.assignedLibrarianId == currentUserId ||
        widget.task.assignedTo == currentUserId;

    // Determine card colors based on dark mode
    final Color cardColor = widget.isDark
        ? const Color(0xFF1E1E1E)
        : colorScheme.primary;
    final Color textColor = widget.isDark ? Colors.white : Colors.white;
    final Color subTextColor = widget.isDark ? Colors.white70 : Colors.white.withValues(alpha: 0.9);

    // For debugging task details
    colorScheme.outline.withAlpha((0.3 * 255).toInt());

    // Debug prints for diagnosis
    debugPrint(
      'TaskCardWidget: taskId= [32m${widget.task.taskId} [0m, '
      'dueDate= [32m${widget.task.dueDate} [0m, '
      'category= [32m${widget.task.category} [0m, '
      'tags= [32m${widget.task.tags} [0m'
    );

    return Dismissible(
      key: ValueKey(widget.task.taskId),
      background: !widget.isCompleted ? _buildCompleteBackground() : Container(),
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
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: widget.isDark ? Colors.black.withAlpha((0.25 * 255).round()) : Colors.black12,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.title, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.task.description,
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
                  'Status: ${widget.task.status}',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                // Tags
                if (widget.task.tags.isNotEmpty)
                  Text(
                    'Tags: ${widget.task.tags.join(', ')}',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                const SizedBox(height: 4),
                // Priority
                if (widget.task.priority != null)
                  Text(
                    'Priority: ${widget.task.priority}',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                const SizedBox(height: 4),
                // Due Date
                if (widget.task.dueDate != null)
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy – HH:mm').format(widget.task.dueDate!)}',
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
                      'Comments: ${widget.task.comments.length}',
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
                      if (!widget.isCompleted)
                        ElevatedButton(
                          onPressed: () {
                            Get.find<SettingsController>().triggerFeedback();
                            _markAsCompleted();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 10.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Complete',
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            color: Colors.red[400], size: 22.sp),
                        onPressed: () {
                          Get.find<SettingsController>().triggerFeedback();
                          if (isTaskOwner) {
                            TaskActions.deleteTask(widget.task);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.edit_note_rounded,
                            color: widget.isDark ? textColor : Colors.white, size: 22.sp),
                        onPressed: () {
                          Get.find<SettingsController>().triggerFeedback();
                          TaskActions.editTask(context, widget.task);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(widget.task.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Description: ${widget.task.description}'),
                const SizedBox(height: 8),
                Text('Status: ${widget.task.status}'),
                const SizedBox(height: 8),
                Text('Category: ${widget.task.category ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Due Date: ${widget.task.dueDate != null ? DateFormat('yyyy-MM-dd – kk:mm').format(widget.task.dueDate!) : 'N/A'}'),
                const SizedBox(height: 8),
                Text('Tags: ${widget.task.tags.isNotEmpty ? widget.task.tags.join(', ') : 'None'}'),
                const SizedBox(height: 8),
                Text('Creator: ${_getCreatorName()}'),
                const SizedBox(height: 8),
                Text('Reporter: ${_getAssignedReporterName()}'),
                const SizedBox(height: 8),
                Text('Cameraman: ${_getAssignedCameramanName()}'),
                const SizedBox(height: 8),
                Text('Driver: ${_getAssignedDriverName()}'),
                const SizedBox(height: 16),
                if (widget.task.comments.isNotEmpty) ...[
                  const Text('Comments:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...widget.task.comments.map((comment) => Padding(
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
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
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
    if (direction == DismissDirection.startToEnd && !widget.isCompleted) {
      return await _showCompleteConfirmation(context);
    } else if (direction == DismissDirection.endToStart) {
      return await _showDeleteConfirmation(context);
    }
    return false;
  }

  void _handleDismissed(DismissDirection direction) {
    if (direction == DismissDirection.startToEnd && !widget.isCompleted) {
      _markAsCompleted();
    } else if (direction == DismissDirection.endToStart) {
      TaskActions.deleteTask(widget.task);
    }
  }

  Future<bool?> _showCompleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Mark as Completed"),
        content: Text("Are you sure you want to mark '${widget.task.title}' as completed?"),
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
                      color: widget.isDark ? Colors.green[300] : Colors.green[700]
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
        content: Text("Are you sure you want to delete '${widget.task.title}'? This action cannot be undone."),
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
                      color: widget.isDark ? Colors.red[300] : Colors.red[600]
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
      if (widget.task.createdById.isNotEmpty &&
          taskController.userNameCache.containsKey(widget.task.createdById)) {
        return taskController.userNameCache[widget.task.createdById]!;
      }
      
      // Fallback to createdBy field
      if (widget.task.createdBy.isNotEmpty) {
        return widget.task.createdBy;
      }
      
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getAssignedReporterName() {
    try {
      if (widget.task.assignedReporterId == null) return 'Not Assigned';
      final taskController = Get.find<TaskController>();
      
      // Check cache first
      if (taskController.userNameCache.containsKey(widget.task.assignedReporterId!)) {
        return taskController.userNameCache[widget.task.assignedReporterId!]!;
      }
      
      // Fallback to task field
      if (widget.task.assignedReporter != null && widget.task.assignedReporter!.isNotEmpty) {
        return widget.task.assignedReporter!;
      }
      
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getAssignedCameramanName() {
    try {
      if (widget.task.assignedCameramanId == null) return 'Not Assigned';
      final taskController = Get.find<TaskController>();
      
      // Check cache first
      if (taskController.userNameCache.containsKey(widget.task.assignedCameramanId!)) {
        return taskController.userNameCache[widget.task.assignedCameramanId!]!;
      }
      
      // Fallback to task field
      if (widget.task.assignedCameraman != null && widget.task.assignedCameraman!.isNotEmpty) {
        return widget.task.assignedCameraman!;
      }
      
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getAssignedDriverName() {
    try {
      if (widget.task.assignedDriverId == null) return 'Not Assigned';
      final taskController = Get.find<TaskController>();
      
      // Check cache first
      if (taskController.userNameCache.containsKey(widget.task.assignedDriverId!)) {
        return taskController.userNameCache[widget.task.assignedDriverId!]!;
      }
      
      // Fallback to task field
      if (widget.task.assignedDriver != null && widget.task.assignedDriver!.isNotEmpty) {
        return widget.task.assignedDriver!;
      }
      
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _markAsCompleted() async {
    // Use the new multi-user completion system
    TaskActions.completeTask(widget.task);
    
    // Show review dialog for admins and managers
    final authController = Get.find<AuthController>();
    final userRole = authController.userRole.value.toLowerCase();
    final userId = authController.auth.currentUser?.uid;
    
    if (userId != null && _canShowReviewDialog(userRole)) {
      // Wait a bit to show the review dialog after the completion snackbar
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => TaskReviewDialog(
            task: widget.task,
            reviewerId: userId,
            reviewerRole: userRole,
            onReviewSubmitted: () {
              // Refresh the task list to show the new review
              final taskController = Get.find<TaskController>();
              taskController.refreshTasks();
            },
          ),
        );
      }
    }
  }

  bool _canShowReviewDialog(String userRole) {
    switch (userRole) {
      case 'admin':
      case 'assignment_editor':
      case 'head_of_department':
      case 'head_of_unit':
        return true;
      default:
        return false;
    }
  }
}
