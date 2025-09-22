// widgets/task_card_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/settings_controller.dart';
import './task_action_utility.dart';
import 'package:task/models/task_model.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/task_controller.dart';
import '../service/user_cache_service.dart';

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
  void initState() {
    super.initState();
    _refreshCreatorNameInBackground();
    _refreshAssignedReporterNameInBackground();
  }

  String _getAssignedReporterNameSync() {
    try {
      if (widget.task.assignedReporterId == null) return 'Not Assigned';

      final userCacheService = Get.find<UserCacheService>();
      final cachedName =
          userCacheService.getUserNameSync(widget.task.assignedReporterId!);
      if (cachedName != 'Unknown User') {
        return cachedName;
      }

      if (widget.task.assignedReporter != null &&
          widget.task.assignedReporter!.isNotEmpty) {
        return widget.task.assignedReporter!;
      }

      return 'Unknown';
    } catch (e) {
      debugPrint('Error in _getAssignedReporterNameSync: $e');
      return 'Error';
    }
  }

  Future<String> _getAssignedCameramanName() async {
    try {
      if (widget.task.assignedCameramanId == null) return 'Not Assigned';

      try {
        final userCacheService = Get.find<UserCacheService>();
        final name = await userCacheService
            .getUserName(widget.task.assignedCameramanId!);
        return name;
      } catch (e) {
        debugPrint('Error getting cameraman name: $e');
        if (widget.task.assignedCameraman != null &&
            widget.task.assignedCameraman!.isNotEmpty) {
          return widget.task.assignedCameraman!;
        }
        return 'Unknown';
      }
    } catch (e) {
      debugPrint('Error in _getAssignedCameramanName: $e');
      return 'Error';
    }
  }

  Future<String> _getAssignedDriverName() async {
    try {
      if (widget.task.assignedDriverId == null) return 'Not Assigned';

      try {
        final userCacheService = Get.find<UserCacheService>();
        final name =
            await userCacheService.getUserName(widget.task.assignedDriverId!);
        return name;
      } catch (e) {
        debugPrint('Error getting driver name: $e');
        if (widget.task.assignedDriver != null &&
            widget.task.assignedDriver!.isNotEmpty) {
          return widget.task.assignedDriver!;
        }
        return 'Unknown';
      }
    } catch (e) {
      debugPrint('Error in _getAssignedDriverName: $e');
      return 'Error';
    }
  }

  String _getCreatorNameSync() {
    try {
      if (widget.task.createdByName != null &&
          widget.task.createdByName!.isNotEmpty) {
        return widget.task.createdByName!;
      }

      if (widget.task.createdById.isEmpty) return 'Unknown';

      final userCacheService = Get.find<UserCacheService>();
      final cachedName =
          userCacheService.getUserNameSync(widget.task.createdById);
      if (cachedName != 'Unknown User') {
        return cachedName;
      }

      if (widget.task.createdBy.isNotEmpty) {
        return widget.task.createdBy;
      }

      return 'Unknown';
    } catch (e) {
      debugPrint('Error in _getCreatorNameSync: $e');
      return 'Unknown';
    }
  }

  void _refreshCreatorNameInBackground() {
    if (widget.task.createdById.isNotEmpty) {
      try {
        final userCacheService = Get.find<UserCacheService>();
        userCacheService.getUserName(widget.task.createdById).then((name) {
          if (mounted && name != 'Unknown User') {
            setState(() {});
          }
        }).catchError((e) {
          debugPrint('Error refreshing creator name: $e');
        });
      } catch (e) {
        debugPrint('Error getting UserCacheService: $e');
      }
    }
  }

  void _refreshAssignedReporterNameInBackground() {
    if (widget.task.assignedReporterId != null) {
      try {
        final userCacheService = Get.find<UserCacheService>();
        userCacheService
            .getUserName(widget.task.assignedReporterId!)
            .then((name) {
          if (mounted && name != 'Unknown User') {
            setState(() {});
          }
        }).catchError((e) {
          debugPrint('Error refreshing reporter name: $e');
        });
      } catch (e) {
        debugPrint('Error getting UserCacheService: $e');
      }
    }
  }

  Widget _buildCompleteBackground() {
    return Container(
      color: Colors.green[600],
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      child: const Icon(
        Icons.check_circle_outline,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      color: Colors.red[600],
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(
        Icons.delete_outline,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Future<bool?> _handleDismiss(
      BuildContext context, DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd) {
      return await _showCompleteConfirmation(context);
    } else {
      return await _showDeleteConfirmation(context);
    }
  }

  Future<void> _handleDismissed(DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd) {
      await _markAsCompleted();
    } else {
      final confirmed = await _showDeleteConfirmation(context);
      if (confirmed == true) {
        await TaskActions.deleteTask(widget.task);
      }
    }
  }

  Future<void> _markAsCompleted() async {
    try {
      final taskController = Get.find<TaskController>();
      await taskController.updateTaskStatus(
        widget.task.taskId,
        'Completed',
      );
      Get.snackbar(
        'Success',
        'Task marked as completed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      debugPrint('Error marking task as completed: $e');
      Get.snackbar(
        'Error',
        'Failed to mark task as completed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<bool?> _showCompleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Task'),
          content: const Text(
              'Are you sure you want to mark this task as completed?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text(
              'Are you sure you want to delete this task? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showTaskDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Theme.of(dialogContext).colorScheme.surface,
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
                Text(
                    'Due Date: ${widget.task.dueDate != null ? DateFormat('yyyy-MM-dd – kk:mm').format(widget.task.dueDate!) : 'N/A'}'),
                const SizedBox(height: 8),
                Text(
                    'Tags: ${widget.task.tags.isNotEmpty ? widget.task.tags.join(', ') : 'None'}'),
                const SizedBox(height: 8),
                Text('Creator: ${_getCreatorNameSync()}'),
                const SizedBox(height: 8),
                Text('Reporter: ${_getAssignedReporterNameSync()}'),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: _getAssignedCameramanName(),
                  builder: (context, snapshot) {
                    return Text('Cameraman: ${snapshot.data ?? 'Loading...'}');
                  },
                ),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: _getAssignedDriverName(),
                  builder: (context, snapshot) {
                    return Text('Driver: ${snapshot.data ?? 'Loading...'}');
                  },
                ),
                const SizedBox(height: 16),
                if (widget.task.comments.isNotEmpty) ...[
                  const Text('Comments:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                backgroundColor:
                    Theme.of(dialogContext).colorScheme.primary.withAlpha(25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authController = Get.find<AuthController>();
    final currentUserId = authController.auth.currentUser?.uid;
    final isAdmin = authController.isAdmin.value;
    final isTaskOwner = widget.task.createdById == currentUserId;
    final isAssignedUser = widget.task.assignedReporterId == currentUserId ||
        widget.task.assignedCameramanId == currentUserId ||
        widget.task.assignedDriverId == currentUserId ||
        (widget.task.assignedTo != null &&
            currentUserId != null &&
            widget.task.assignedTo!.contains(currentUserId));

    // Simplified permission logic:
    // Task creators can always manage their tasks
    // Admins can manage all tasks
    // Assigned users can manage their assigned tasks
    final canManageTask = isTaskOwner || isAdmin || isAssignedUser;

    final Color cardColor =
        widget.isDark ? const Color(0xFF1E1E1E) : colorScheme.primary;
    final Color textColor = widget.isDark ? Colors.white : Colors.white;
    final Color subTextColor =
        widget.isDark ? Colors.white70 : Colors.white.withValues(alpha: 0.9);

    return Dismissible(
      key: ValueKey(widget.task.taskId),
      background:
          !widget.isCompleted ? _buildCompleteBackground() : Container(),
      secondaryBackground: _buildDeleteBackground(),
      confirmDismiss: (direction) => _handleDismiss(context, direction),
      onDismissed: _handleDismissed,
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
                  color: widget.isDark
                      ? Colors.black.withAlpha(64)
                      : Colors.black12,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: subTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Created by: ${_getCreatorNameSync()}',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Assigned Reporter: ${_getAssignedReporterNameSync()}',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: _getAssignedCameramanName(),
                  builder: (context, snapshot) {
                    return Text(
                      'Assigned Cameraman: ${snapshot.data ?? 'Loading...'}',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: _getAssignedDriverName(),
                  builder: (context, snapshot) {
                    return Text(
                      'Assigned Driver: ${snapshot.data ?? 'Loading...'}',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${widget.task.status}',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.task.tags.isNotEmpty)
                  Text(
                    'Tags: ${widget.task.tags.join(', ')}',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                const SizedBox(height: 4),
                if (widget.task.priority != null)
                  Text(
                    'Priority: ${widget.task.priority}',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                const SizedBox(height: 4),
                if (widget.task.dueDate != null)
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy – HH:mm').format(widget.task.dueDate!)}',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                const SizedBox(height: 16),
                if (canManageTask)
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
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Complete',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            color: Colors.red[400], size: 22),
                        onPressed: () {
                          Get.find<SettingsController>().triggerFeedback();
                          _showDeleteConfirmation(context).then((confirmed) {
                            if (confirmed == true) {
                              TaskActions.deleteTask(widget.task);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.edit_note_rounded,
                            color: widget.isDark ? Colors.white : Colors.white,
                            size: 22),
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
}
