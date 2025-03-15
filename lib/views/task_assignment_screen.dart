// views/task_assignment_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import '../controllers/user_controller.dart';

class TaskAssignmentScreen extends StatelessWidget {
  final TaskController taskController = Get.find();
  final UserController userController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assign Tasks")),
      body: Obx(() {
        if (taskController.tasks.isEmpty) {
          return const Center(child: Text("No tasks available"));
        }
        return ListView.builder(
          itemCount: taskController.tasks.length,
          itemBuilder: (context, index) {
            final task = taskController.tasks[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text(task["title"],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(task["description"]),
                trailing: ElevatedButton(
                  onPressed: () => _showAssignmentDialog(context, task["id"]),
                  child: const Text("Assign"),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAssignmentDialog(BuildContext context, String taskId) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Assign Task",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Obx(() {
              if (userController.reporters.isEmpty) {
                return const Text("No reporters available");
              }
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Assign to Reporter"),
                items: userController.reporters.map((reporter) {
                  return DropdownMenuItem(
                      value: reporter["id"], child: Text(reporter["name"]));
                }).toList(),
                onChanged: (value) {
                  taskController.assignTaskToReporter(taskId, value!);
                },
              );
            }),
            const SizedBox(height: 10),
            Obx(() {
              if (userController.cameramen.isEmpty) {
                return const Text("No cameramen available");
              }
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Assign to Cameraman"),
                items: userController.cameramen.map((cameraman) {
                  return DropdownMenuItem(
                      value: cameraman["id"], child: Text(cameraman["name"]));
                }).toList(),
                onChanged: (value) {
                  taskController.assignTaskToCameraman(taskId, value!);
                },
              );
            }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }
}
