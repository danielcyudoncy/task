// views/task_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';

class TaskListScreen extends StatelessWidget {
  final TaskController taskController = Get.put(TaskController());

   TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Tasks")),
      body: Obx(() {
        if (taskController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: taskController.tasks.length,
          itemBuilder: (context, index) {
            var task = taskController.tasks[index];
            return Card(
              child: ListTile(
                title: Text(task.title),
                subtitle: Text(task.description),
                trailing: Text(task.status,
                    style: TextStyle(
                        color: task.status == "Completed"
                            ? Colors.green
                            : Colors.red)),
              ),
            );
          },
        );
      }),
    );
  }
}
