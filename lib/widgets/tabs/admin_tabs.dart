// widgets/tabs/admin_tabs.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/task_controller.dart';
import '../../models/report_completion_info.dart';
import '../dialogs/task_approval_dialog.dart';
import '../report_completion_dialog.dart';
import '../ui_helpers.dart';

class TasksTab extends StatefulWidget {
  final Map<String, Map<String, String>> userCache;
  final Future<Map<String, String>> Function(String, VoidCallback)
      getUserNameAndRole;
  final Function(String) showTaskDetailDialog;
  final String taskType; // 'pending' or 'completed'

  const TasksTab({
    super.key,
    required this.userCache,
    required this.getUserNameAndRole,
    required this.showTaskDetailDialog,
    required this.taskType,
  });

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  @override
  Widget build(BuildContext context) {
    final AdminController adminController = Get.find<AdminController>();

    return Obx(() {
      if (adminController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      final tasks = widget.taskType == 'completed'
          ? adminController.completedTaskTitles
          : adminController.pendingTaskTitles;
      if (tasks.isEmpty) {
        return _buildEmptyState(context);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final title = tasks[index];
          final doc = adminController.taskSnapshotDocs
              .firstWhereOrNull((d) => d['title'] == title);

          return _buildTaskCard(context, title, doc);
        },
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks available',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tasks will appear here when created',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
      BuildContext context, String title, Map<String, dynamic>? doc) {
    final creatorId = doc?['createdBy'] ?? 'Unknown';
    final userInfo = widget.userCache[creatorId];
    if (userInfo == null && creatorId != 'Unknown') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.getUserNameAndRole(creatorId, () {
            // userCache is modified directly, no setState needed
          });
        }
      });
    }
    final creatorName = userInfo?["name"] ?? 'Unknown';
    final status = doc?['status'] ?? 'Unknown';
    final priority = doc?['priority'] ?? 'Medium';
    final taskId = doc?['id'] ?? doc?['taskId'] ?? '';

    // Check if current user can complete this task
    final authController = Get.find<AuthController>();
    final currentUserId = authController.auth.currentUser?.uid;
    final userRole = authController.userRole.value;
    final isAssignedUser = _isUserAssignedToTask(doc, currentUserId);
    final canCompleteTask =
        widget.taskType == 'pending' && isAssignedUser && currentUserId != null;

    // Debug logging

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).primaryColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.showTaskDetailDialog(title),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          creatorName.isNotEmpty
                              ? creatorName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Created by $creatorName',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            _getPriorityColor(priority).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getPriorityColor(priority)
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          color: _getPriorityColor(priority),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (canCompleteTask) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: doc != null
                            ? () => _completeTask(doc, currentUserId, userRole)
                            : null,
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _addComment(taskId, title),
                        icon: const Icon(Icons.comment, size: 16),
                        label: const Text('Comment'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.onPrimary),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          textStyle: TextStyle(fontSize: 12.sp),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isUserAssignedToTask(Map<String, dynamic>? doc, String? userId) {
    if (doc == null || userId == null) return false;

    final assignedReporterId = doc['assignedReporterId']?.toString();
    final assignedCameramanId = doc['assignedCameramanId']?.toString();
    final assignedDriverId = doc['assignedDriverId']?.toString();

    return assignedReporterId == userId ||
        assignedCameramanId == userId ||
        assignedDriverId == userId;
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFE74C3C); // Red
      case 'medium':
        return const Color(0xFFF39C12); // Orange
      case 'low':
        return const Color(0xFF27AE60); // Green
      default:
        return const Color(0xFF95A5A6); // Grey
    }
  }

  Future<void> _completeTask(
      Map<String, dynamic> doc, String currentUserId, String userRole) async {
    try {
      final taskController = Get.find<TaskController>();
      final taskId = doc['id'] ?? doc['taskId'] ?? '';

      if (taskId.isEmpty) {
        Get.snackbar("Error", "Task ID not found",
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      // If user is a reporter, show completion dialog
      if (userRole == "Reporter" &&
          doc['assignedReporterId'] == currentUserId) {
        final result = await Get.dialog<ReportCompletionInfo>(
          ReportCompletionDialog(
            onComplete: (info) {
              return Get.back(result: info);
            },
          ),
          barrierDismissible: false,
        );

        if (result != null) {
          await taskController.markTaskCompletedByUser(
            taskId,
            currentUserId,
            reportCompletionInfo: result,
          );
          Get.snackbar(
            "Success",
            "Task marked as completed with report details",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      } else {
        await taskController.markTaskCompletedByUser(taskId, currentUserId);
        Get.snackbar(
          "Success",
          "Task marked as completed",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to complete task: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _addComment(String taskId, String taskTitle) async {
    if (taskId.isEmpty) {
      Get.snackbar("Error", "Task ID not found",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final TextEditingController commentController = TextEditingController();

    final result = await Get.dialog<String>(
      AlertDialog(
        title: Text('Add Comment to "$taskTitle"'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            hintText: 'Enter your comment...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final comment = commentController.text.trim();
              if (comment.isNotEmpty) {
                Get.back(result: comment);
              }
            },
            child: const Text('Add Comment'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final taskController = Get.find<TaskController>();
        final authController = Get.find<AuthController>();
        final currentUserId = authController.auth.currentUser?.uid;

        if (currentUserId != null) {
          await taskController.addComment(taskId, result);
          Get.snackbar(
            "Success",
            "Comment added successfully",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.primary,
            colorText: Get.theme.colorScheme.onPrimary,
          );
        }
      } catch (e) {
        Get.snackbar("Error", "Failed to add comment: $e",
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }
}

class TaskApprovalTab extends StatefulWidget {
  final Map<String, Map<String, String>> userCache;
  final Future<Map<String, String>> Function(String, VoidCallback)
      getUserNameAndRole;

  const TaskApprovalTab({
    super.key,
    required this.userCache,
    required this.getUserNameAndRole,
  });

  @override
  State<TaskApprovalTab> createState() => _TaskApprovalTabState();
}

class _TaskApprovalTabState extends State<TaskApprovalTab> {
  final AdminController adminController = Get.find<AdminController>();

  @override
  void initState() {
    super.initState();
    // Fetch pending approval tasks if method exists
  }

  void _showApprovalDialog(Map<String, dynamic> taskData) {
    final creatorId = taskData['createdBy'] ?? '';
    final userInfo = widget.userCache[creatorId];
    final creatorName = userInfo?['name'] ?? 'Unknown';
    final creatorRole = userInfo?['role'] ?? 'Unknown';

    TaskApprovalDialog.show(
      context: context,
      taskId: taskData['id'] ?? '',
      title: taskData['title'] ?? 'Untitled Task',
      description: taskData['description'] ?? '',
      createdBy: creatorId,
      creatorName: creatorName,
      creatorRole: creatorRole,
      status: taskData['status'] ?? 'pending',
      priority: taskData['priority'] ?? 'medium',
      category: taskData['category'] ?? 'general',
      dueDate: taskData['dueDate'] ?? 'Not set',
      tags: List<String>.from(taskData['tags'] ?? []),
      attachmentUrls: List<String>.from(taskData['attachmentUrls'] ?? []),
      attachmentNames: List<String>.from(taskData['attachmentNames'] ?? []),
      onApprove: () => _approveTask(taskData['id']),
      onReject: () => _rejectTask(taskData['id']),
    );
  }

  void _approveTask(String taskId) async {
    try {
      await adminController.approveTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task approved successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving task: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _rejectTask(String taskId) async {
    try {
      await adminController.rejectTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task rejected successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting task: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (adminController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      final pendingTasks = adminController.pendingApprovalTasks;
      if (pendingTasks.isEmpty) {
        return _buildEmptyState(context);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingTasks.length,
        itemBuilder: (context, index) {
          final task = pendingTasks[index];
          return _buildApprovalCard(context, task);
        },
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.approval,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No pending approvals',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tasks requiring approval will appear here',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, Map<String, dynamic> task) {
    final creatorId = task['createdBy'] ?? '';
    final userInfo = widget.userCache[creatorId];
    if (userInfo == null && creatorId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.getUserNameAndRole(creatorId, () {
          // userCache is modified directly, no setState needed
        });
      });
    }

    final creatorName = userInfo?['name'] ?? 'Unknown';
    final title = task['title'] ?? 'Untitled Task';
    final priority = task['priority'] ?? 'medium';
    final category = task['category'] ?? 'general';

    String dateStr = 'Unknown';
    final createdAt = task['timestamp'];
    if (createdAt != null) {
      DateTime dt;
      if (createdAt is Timestamp) {
        dt = createdAt.toDate();
      } else if (createdAt is DateTime) {
        dt = createdAt;
      } else {
        dt = DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
      }
      dateStr = UIHelpers.formatDate(dt);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).primaryColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showApprovalDialog(task),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF39C12).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF39C12).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.pending_actions,
                        color: Color(0xFFF39C12),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            _getPriorityColor(priority).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getPriorityColor(priority)
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          color: _getPriorityColor(priority),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          creatorName.isNotEmpty
                              ? creatorName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            creatorName,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectTask(task['id']),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE74C3C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveTask(task['id']),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFE74C3C); // Red
      case 'medium':
        return const Color(0xFFF39C12); // Orange
      case 'low':
        return const Color(0xFF27AE60); // Green
      default:
        return const Color(0xFF95A5A6); // Grey
    }
  }
}
