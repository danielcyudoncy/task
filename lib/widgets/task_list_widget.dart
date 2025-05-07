// widgets/task_list_widget.dart
import 'package:flutter/material.dart';

class TaskListWidget extends StatelessWidget {
  final List<String> tasks;
  final bool showCompleted;
  final Function(String) onTaskTap;

  const TaskListWidget({
    super.key,
    required this.tasks,
    required this.showCompleted,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: Text(tasks[index]),
            trailing: Icon(
              showCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: showCompleted ? Colors.green : Colors.grey,
            ),
            onTap: () => onTaskTap(tasks[index]),
          ),
        );
      },
    );
  }
}
