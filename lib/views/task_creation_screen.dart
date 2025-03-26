// views/task_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import '../controllers/auth_controller.dart';

class TaskCreationScreen extends StatelessWidget {
  final TaskController taskController = Get.put(TaskController());
  final AuthController authController = Get.find<AuthController>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  TaskCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Task")),
      body: _canCreateTask()
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "New Task",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Task Title Field
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Task Title"),
                  ),

                  // Task Description Field
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "Task Description"),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 20),

                  // Create Task Button with Loading Indicator
                  Obx(() => taskController.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _createTask,
                          child: const Text("Create Task"),
                        )),
                ],
              ),
            )
          : const Center(
              child: Text(
                "Access Denied: You do not have permission to create tasks.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }

  // ✅ Check if user has permission to create tasks
  bool _canCreateTask() {
    String role = authController.userRole.value;
    return role == "Reporter" || role == "Cameraman";
  }

  // ✅ Task Creation Logic with Creator Information
  void _createTask() {
    String title = titleController.text.trim();
    String description = descriptionController.text.trim();
    String? userId = authController.auth.currentUser?.uid;

    if (title.isEmpty || description.isEmpty) {
      Get.snackbar("Error", "Please fill in all fields.");
      return;
    }

    if (userId == null) {
      Get.snackbar("Error", "User not found. Please log in again.");
      return;
    }

    // ✅ Create the task and add user ID
    taskController.createTask(title, description, userId).then((_) {
      Get.snackbar("Success", "Task created successfully");
      Get.back();
    });

    // ✅ Clear fields after task creation
    titleController.clear();
    descriptionController.clear();
  }
}
