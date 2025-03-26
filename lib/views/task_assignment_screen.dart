// views/task_assignment_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';

class TaskAssignmentScreen extends StatelessWidget {
  final TaskController taskController = Get.put(TaskController());
  final UserController userController = Get.put(UserController());
  final AuthController authController = Get.find<AuthController>(); // ✅ Get user role

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

        return ListView.builder(
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
                trailing: _canAssignTask()
                    ? ElevatedButton(
                        onPressed: () => _showAssignmentDialog(context, task.taskId),
                        child: const Text("Assign"),
                      )
                    : const Text(
                        "No Permission",
                        style: TextStyle(color: Colors.grey),
                      ),
              ),
            );
          },
        );
      }),
    );
  }

  // ✅ Check if user can assign tasks
  bool _canAssignTask() {
    String userRole = authController.userRole.value;
    return userRole == "Admin" || userRole == "Assignment Editor" || userRole == "Head of Department";
  }

  // ✅ Show Assignment Dialog
  void _showAssignmentDialog(BuildContext context, String taskId) {
    if (!_canAssignTask()) {
      Get.snackbar("Access Denied", "You do not have permission to assign tasks.");
      return;
    }

    String? selectedReporter;
    String? selectedCameraman;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        height: 350,
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

            // ✅ Assign to Reporter Dropdown
            Obx(() {
              if (userController.reporters.isEmpty) {
                return const Text("No reporters available");
              }
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Assign to Reporter"),
                items: userController.reporters.map<DropdownMenuItem<String>>((reporter) {
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

            // ✅ Assign to Cameraman Dropdown
            Obx(() {
              if (userController.cameramen.isEmpty) {
                return const Text("No cameramen available");
              }
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Assign to Cameraman"),
                items: userController.cameramen.map<DropdownMenuItem<String>>((cameraman) {
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

            // ✅ Assign Task Button
            ElevatedButton(
              onPressed: () {
                if (selectedReporter != null && selectedCameraman != null) {
                  taskController.assignTaskToReporter(taskId, selectedReporter!);
                  taskController.assignTaskToCameraman(taskId, selectedCameraman!);
                  Get.snackbar("Success", "Task assigned successfully.");
                } else if (selectedReporter != null) {
                  taskController.assignTaskToReporter(taskId, selectedReporter!);
                  Get.snackbar("Success", "Task assigned to Reporter.");
                } else if (selectedCameraman != null) {
                  taskController.assignTaskToCameraman(taskId, selectedCameraman!);
                  Get.snackbar("Success", "Task assigned to Cameraman.");
                } else {
                  Get.snackbar("Error", "Please select at least one person.");
                }

                Get.back();
              },
              child: const Text("Assign Task"),
            ),
          ],
        ),
      ),
    );
  }
}
