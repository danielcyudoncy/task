// widgets/minimal_task_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:task/models/task_model.dart';
import 'status_chip.dart';

class MinimalTaskCard extends StatelessWidget {
  final Task task;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isSelected;
  final VoidCallback? onDismiss;

  const MinimalTaskCard({
    super.key,
    required this.task,
    required this.isDark,
    this.onTap,
    this.isSelected = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    // Use theme-aware colors
    final Color cardColor = isDark 
        ? const Color(0xFF292B3A) 
        : colorScheme.surface;
    final Color textColor = isDark ? Colors.white : colorScheme.onSurface;
    final Color subTextColor = isDark ? Colors.white70 : colorScheme.onSurfaceVariant;
    final Color borderColor = colorScheme.outline.withValues(alpha: 0.3);
    final Color selectedColor = colorScheme.primary.withValues(alpha: 0.1);

    return Dismissible(
      key: ValueKey(task.taskId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        debugPrint('MinimalTaskCard: Swipe detected for task - ${task.title}');
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Are you sure you want to delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        debugPrint('MinimalTaskCard: Task dismissed - ${task.title}');
        onDismiss?.call();
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 30,
        ),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x15000000),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with title and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textColor,
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Creator info
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: subTextColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Created by: ${task.createdBy}',
                          style: textTheme.bodySmall?.copyWith(
                            color: subTextColor,
                            fontSize: 12.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Assignment info
                  Row(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 16,
                        color: subTextColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getAssignmentText(),
                          style: textTheme.bodySmall?.copyWith(
                            color: subTextColor,
                            fontSize: 12.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Category and priority (if available)
                  if (task.category != null && task.category!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 16,
                          color: subTextColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task.category!,
                            style: textTheme.bodySmall?.copyWith(
                              color: subTextColor,
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
                            style: textTheme.bodySmall?.copyWith(
                              color: _getPriorityColor(task.priority!),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  
                  // Tags (if available)
                  if (task.tags != null && task.tags!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 16,
                          color: isDark ? Colors.white : subTextColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Tags: ${task.tags!.join(', ')}',
                            style: textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white : subTextColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Due date (if available)
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 16,
                          color: subTextColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Due: ${DateFormat('MMM dd').format(task.dueDate!)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: subTextColor,
                              fontSize: 12.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
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
    
    if (assignments.isEmpty) {
      return 'Not assigned';
    }
    
    return assignments.join(', ');
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
} 