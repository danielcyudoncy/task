// widgets/task_list_tab.dart
import 'package:flutter/material.dart';

import 'package:task/widgets/task_card_widget.dart';
import 'package:task/models/task.dart';

class TaskListTab extends StatelessWidget {
  final bool isCompleted;
  final bool isDark;
  final List<Task> tasks;

  const TaskListTab({
    super.key,
    required this.isCompleted,
    required this.isDark,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (tasks.isEmpty) {
      return Center(
        child: Text(
          "No tasks.",
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCardWidget(
          task: task,
          isCompleted: isCompleted,
          isDark: isDark,
        );
      },
    );
  }
}
