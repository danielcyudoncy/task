// views/task_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import '../controllers/auth_controller.dart';

class TaskCreationScreen extends StatelessWidget {
  final TaskController taskController = Get.put(TaskController());
  final AuthController authController = Get.find();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  TaskCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Task")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Task Title"),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Task Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Obx(() => taskController.isLoading.value
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty &&
                          descriptionController.text.isNotEmpty) {
                        taskController.createTask(
                          titleController.text.trim(),
                          descriptionController.text.trim(),
                          authController.auth.currentUser!.uid,
                        );
                        Get.back();
                      } else {
                        Get.snackbar("Error", "Please fill in all fields");
                      }
                    },
                    child: const Text("Create Task"),
                  )),
          ],
        ),
      ),
    );
  }
}
