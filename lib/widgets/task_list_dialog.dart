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
    return Obx(() {
      if (tasks.isEmpty) {
        return const SimpleDialog(
          title: Text('Assign Task'),
          children: [
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
        title: const Text('Assign Task'),
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