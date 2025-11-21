// widgets/task_card_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import './task_action_utility.dart';
import 'package:task/models/task.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/task_controller.dart';
import '../service/user_cache_service.dart';
import 'package:task/widgets/status_chip.dart';

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
    final mediaQuery = MediaQuery.of(context);

    final Color cardColor =
        widget.isDark ? const Color(0xFF1E1E1E) : colorScheme.primary;
    final Color textColor = widget.isDark ? Colors.white : Colors.white;
    final Color subTextColor =
        widget.isDark ? Colors.white70 : Colors.white.withValues(alpha: 0.9);
    final double textScaleFactor = mediaQuery.textScaler.scale(1);

    final String creatorName = _getCreatorNameSync();
    final String assignedReporterName = _getAssignedReporterNameSync();

    final bool isOwner =
        authController.user.value?.uid == widget.task.createdBy;
    final bool isAdmin = authController.isCurrentUserAdmin;
    final bool canManageTask = isOwner || isAdmin;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardColor,
      child: InkWell(
        onTap: () => _showTaskDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18 * textScaleFactor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.task.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: subTextColor,
                      fontSize: 14 * textScaleFactor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Creator: $creatorName',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subTextColor,
                              fontSize: 12 * textScaleFactor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Assigned: $assignedReporterName',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subTextColor,
                              fontSize: 12 * textScaleFactor,
                            ),
                          ),
                        ],
                      ),
                      StatusChip(
                        status: widget.task.status,
                        textScale: textScaleFactor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (canManageTask)
              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      TaskActions.editTask(context, widget.task);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context);
                    } else if (value == 'assign') {
                      TaskActions.assignTask(context, widget.task);
                    } else if (value == 'comment') {
                      TaskActions.addComment(context, widget.task);
                    } else if (value == 'complete') {
                      _markAsCompleted();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'assign',
                      child: Text('Assign Task'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'comment',
                      child: Text('Add Comment'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                    if (widget.task.status != 'Completed')
                      const PopupMenuItem<String>(
                        value: 'complete',
                        child: Text('Complete'),
                      ),
                  ],
                  icon: Icon(Icons.more_vert, color: textColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
