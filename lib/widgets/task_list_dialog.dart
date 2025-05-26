// widgets/task_list_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/manage_users_controller.dart';

class TaskListDialog extends StatelessWidget {
  final ManageUsersController controller;
  final Map<String, dynamic> user;

  const TaskListDialog({
    required this.controller,
    required this.user,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tasks = controller.tasksList;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userName = user['name'] ?? 'User';

    return Obx(() {
      if (tasks.isEmpty) {
        return SimpleDialog(
          title: Text(
            'Assign Task to $userName',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: const [
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text("No tasks available"),
              ),
            )
          ],
        );
      }
      return SimpleDialog(
        title: Text(
          'Assign Task to $userName',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: tasks.map((task) {
          return SimpleDialogOption(
            onPressed: () {
              controller.assignTaskToUser(user['id'], task['taskId']);
              Navigator.pop(context);
              Get.snackbar('Success', 'Task assigned successfully',
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: Text(task['title']),
          );
        }).toList(),
      );
    });
  }
}
