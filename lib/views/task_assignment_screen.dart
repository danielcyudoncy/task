// views/task_assignment_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';

class TaskAssignmentScreen extends StatelessWidget {
  final TaskController taskController = Get.put(TaskController());
  final UserController userController = Get.put(UserController());
  final AuthController authController = Get.find<AuthController>();

  TaskAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assign Tasks")),
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

        return Column(
          children: [
            if (authController.canAssignTask)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.add_task),
                  label: const Text("Assign Task"),
                  onPressed: () => _showAssignmentDialog(context, null),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: taskController.tasks.length,
                itemBuilder: (context, index) {
                  final task = taskController.tasks[index];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(
                        task.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(task.description),
                      trailing: authController.canAssignTask
                          ? ElevatedButton(
                              onPressed: () =>
                                  _showAssignmentDialog(context, task.taskId),
                              child: const Text("Assign"),
                            )
                          : const Text(
                              "No Permission",
                              style: TextStyle(color: Colors.grey),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showAssignmentDialog(BuildContext context, String? taskId) {
    if (!authController.canAssignTask) {
      Get.snackbar(
          "Access Denied", "You do not have permission to assign tasks.");
      return;
    }

    String? selectedTaskId = taskId;
    String? selectedReporter;
    String? selectedCameraman;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Assign Task",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // If taskId is null, show dropdown for selecting a task
            if (taskId == null)
              Obx(() {
                if (taskController.tasks.isEmpty) {
                  return const Text("No tasks available");
                }
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Select Task"),
                  items: taskController.tasks
                      .map<DropdownMenuItem<String>>((task) =>
                          DropdownMenuItem(
                            value: task.taskId,
                            child: Text(task.title),
                          ))
                      .toList(),
                  onChanged: (value) {
                    selectedTaskId = value;
                  },
                );
              }),

            const SizedBox(height: 10),

            // Assign to Reporter Dropdown
            Obx(() {
              if (userController.reporters.isEmpty) {
                return const Text("No reporters available");
              }
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Assign to Reporter"),
                items: userController.reporters
                    .map<DropdownMenuItem<String>>((reporter) {
                  return DropdownMenuItem<String>(
                    value: reporter["id"],
                    child: Text(reporter["name"]),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedReporter = value;
                },
              );
            }),

            const SizedBox(height: 10),

            // Assign to Cameraman Dropdown
            Obx(() {
              if (userController.cameramen.isEmpty) {
                return const Text("No cameramen available");
              }
              return DropdownButtonFormField<String>(
                decoration:
                    const InputDecoration(labelText: "Assign to Cameraman"),
                items: userController.cameramen
                    .map<DropdownMenuItem<String>>((cameraman) {
                  return DropdownMenuItem<String>(
                    value: cameraman["id"],
                    child: Text(cameraman["name"]),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCameraman = value;
                },
              );
            }),

            const SizedBox(height: 20),

            // Assign Task Button (works if task and at least one user is selected)
            Obx(() {
              return ElevatedButton(
                onPressed: () {
                  if (selectedTaskId == null) {
                    Get.snackbar("Error", "Please select a task.");
                    return;
                  }
                  if (selectedReporter != null) {
                    taskController.assignTaskToReporter(selectedTaskId!, selectedReporter!);
                  }
                  if (selectedCameraman != null) {
                    taskController.assignTaskToCameraman(selectedTaskId!, selectedCameraman!);
                  }
                  if (selectedReporter == null && selectedCameraman == null) {
                    Get.snackbar("Error", "Please select at least one person.");
                    return;
                  }
                  Get.snackbar("Success", "Task assigned successfully.");
                  Get.back();
                },
                child: const Text("Assign Task"),
              );
            }),
          ],
        ),
      ),
    );
  }
}