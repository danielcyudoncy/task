// widgets/task_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/settings_controller.dart';
import './task_action_utility.dart';
import 'package:task/models/task_model.dart';


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
    
    // Use the same color scheme as admin dashboard
    final Color cardColor = isDark 
        ? const Color(0xFF292B3A) 
        : Theme.of(context).primaryColor;
    const Color textColor = Colors.white;
    const Color subTextColor = Colors.white70;
    final Color borderColor = colorScheme.outline.withAlpha((0.3 * 255).toInt());

    // Debug prints for diagnosis
    print(
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
                style: TextStyle(
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
              const SizedBox(height: 6),
              // Due Date
              Builder(
                builder: (context) {
                  final dueDate = task.dueDate;
                  final dueDateStr = dueDate != null ? DateFormat('yyyy-MM-dd – kk:mm').format(dueDate) : 'N/A';
                  debugPrint('TaskCardWidget: dueDate = $dueDateStr');
                  return Text(
                    'due_date'.trParams({'date': dueDateStr}),
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              // Category
              Builder(
                builder: (context) {
                  final category = task.category ?? 'No category';
                  return Text(
                    category,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              // Tags
              Builder(
                builder: (context) {
                  final tags = task.tags ?? [];
                  final tagsStr = tags.isNotEmpty ? tags.join(', ') : 'No tags';
                  return Text(
                    tagsStr,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isCompleted) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(40, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text("Complete", style: TextStyle(fontSize: 13)),
                      onPressed: () {
                        TaskActions.completeTask(task);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(40, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text("Delete", style: TextStyle(fontSize: 13)),
                    onPressed: () async {
                      final confirmed = await _showDeleteConfirmation(context);
                      if (confirmed == true) {
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
    );
  }

  Widget _buildCompleteBackground() {
    return Container(
      color: Colors.green[600],
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      child: const Row(
        children: [
          Icon(Icons.check, color: Colors.white),
          SizedBox(width: 8),
          Text("Complete", style: TextStyle(color: Colors.white)),
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
          Icon(Icons.delete, color: Colors.white),
          SizedBox(width: 8),
          Text("Delete", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<bool?> _handleDismiss(
      BuildContext context, DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd && !isCompleted) {
      TaskActions.completeTask(task);
      return false;
    } else if (direction == DismissDirection.endToStart) {
      return await _showDeleteConfirmation(context);
    }
    return false;
  }

  void _handleDismissed(DismissDirection direction) {
    if (direction == DismissDirection.endToStart) {
      TaskActions.deleteTask(task);
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          "Delete Task",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this task?",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.find<SettingsController>().triggerFeedback();
              Navigator.of(ctx).pop(false);
            },
            child: Text(
              "Cancel",
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.find<SettingsController>().triggerFeedback();
              Navigator.of(ctx).pop(true);
            },
            child: Text(
              "Delete", 
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ],
      ),
    );
  }
}
