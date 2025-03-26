import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';

class TaskCreationScreen extends StatelessWidget {
  final TaskController taskController = Get.put(TaskController());

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

            // ✅ Fix: Create Task without userId argument
            Obx(() => taskController.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _createTask,
                    child: const Text("Create Task"),
                  )),
          ],
        ),
      ),
    );
  }

  void _createTask() {
    String title = titleController.text.trim();
    String description = descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      Get.snackbar("Error", "Please fill in all fields.");
      return;
    }

    // ✅ Fix: Call createTask without passing userId
    taskController.createTask(title, description);

    titleController.clear();
    descriptionController.clear();
  }
}
