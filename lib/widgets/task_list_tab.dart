// widgets/task_list_tab.dart
import 'package:flutter/material.dart';
import 'package:task/widgets/taskCard_widget.dart';

class TaskListTab extends StatelessWidget {
  final bool isCompleted;
  final bool isDark;
  final List<dynamic> tasks;

  const TaskListTab({
    super.key,
    required this.isCompleted,
    required this.isDark,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final Color emptyListColor = isDark ? Colors.white70 : Colors.black54;

    if (tasks.isEmpty) {
      return Center(
        child: Text(
          "No tasks.",
          style: TextStyle(color: emptyListColor),
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
