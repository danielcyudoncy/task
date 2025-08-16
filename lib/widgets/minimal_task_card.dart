// widgets/minimal_task_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/models/task_model.dart';
import 'status_chip.dart';
import 'approval_status_chip.dart';

class MinimalTaskCard extends StatelessWidget {
  final Task task;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isSelected;
  final VoidCallback? onDismiss;
  final bool enableSwipeToDelete;

  const MinimalTaskCard({
    super.key,
    required this.task,
    required this.isDark,
    this.onTap,
    this.isSelected = false,
    this.onDismiss,
    this.enableSwipeToDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    Widget cardContent = Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.1)
            : isDark
                ? const Color(0xFF292B3A)
                : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0x15000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () => _showTaskDetails(context),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : colorScheme.onSurface,
                          fontSize: 16.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      status: task.status,
                      textScale: 1.0,
                    ),
                    const SizedBox(width: 8),
                    ApprovalStatusChip(
                      approvalStatus: task.approvalStatus,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCreatorRow(context),
                const SizedBox(height: 4),
                _buildAssignmentRow(context),
                if (task.category != null && task.category!.isNotEmpty)
                  _buildCategoryRow(context),
                if (task.tags.isNotEmpty) _buildTagsRow(context),
                if (task.dueDate != null) _buildDueDateRow(context),
                _buildCommentsRow(context),
              ],
            ),
          ),
        ),
      ),
    );

    return cardContent;
  }

  Widget _buildCreatorRow(BuildContext context) {
    final creatorName = _getCreatorName();
    return Row(
      children: [
        Icon(
          Icons.person_outline,
          size: 16,
          color: isDark
              ? Colors.white70
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Created by: $creatorName',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? Colors.white70
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12.sp,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getCreatorName() {
    try {
      final taskController = Get.find<TaskController>();

      // 1. Check if we have a cached name
      if (task.createdById.isNotEmpty &&
          taskController.userNameCache.containsKey(task.createdById)) {
        return taskController.userNameCache[task.createdById]!;
      }

      // 2. Fallback to createdBy field
      if (task.createdBy.isNotEmpty) {
        return task.createdBy;
      }

      // 3. Final fallback
      return 'Unknown';
    } catch (e) {
      debugPrint('Error getting creator name: $e');
      return task.createdBy;
    }
  }

  Widget _buildAssignmentRow(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.assignment_outlined,
          size: 16,
          color: isDark
              ? Colors.white70
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            _getAssignmentText(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? Colors.white70
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12.sp,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getAssignmentText() {
    final assignments = <String>[];

    if (task.assignedReporter != null && task.assignedReporter!.isNotEmpty) {
      assignments.add('Reporter: ${task.assignedReporter}');
    }

    if (task.assignedCameraman != null && task.assignedCameraman!.isNotEmpty) {
      assignments.add('Cameraman: ${task.assignedCameraman}');
    }

    if (assignments.isEmpty) return 'Not assigned';
    return assignments.join(', ');
  }

  Widget _buildCategoryRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.category_outlined,
            size: 16,
            color: isDark
                ? Colors.white70
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              task.category!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.white70
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12.sp,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (task.priority != null && task.priority!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.flag_outlined,
              size: 16,
              color: _getPriorityColor(task.priority!),
            ),
            const SizedBox(width: 4),
            Text(
              task.priority!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getPriorityColor(task.priority!),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.label_outlined,
            size: 16,
            color: isDark
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Tags: ${task.tags.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 16,
            color: isDark
                ? Colors.white70
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Due: ${DateFormat('MMM dd').format(task.dueDate!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.white70
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12.sp,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.comment_outlined,
            size: 16,
            color: isDark
                ? Colors.white70
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Comments: ${task.comments.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.white70
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12.sp,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
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
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
