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

        if (taskController.tasks.isEmpty) {
          return const Center(
            child: Text(
              "No tasks available",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        return ListView.builder(
          itemCount: taskController.tasks.length,
          itemBuilder: (context, index) {
            var task = taskController.tasks[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                title: Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(task.description),
                trailing: _buildStatusIndicator(task.status),
              ),
            );
          },
        );
      }),
    );
  }

  // Task Status Indicator
  Widget _buildStatusIndicator(String status) {
    Color statusColor = status == "Completed" ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
