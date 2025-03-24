// controllers/task_controller.dart
import 'package:get/get.dart';
import 'package:task/service/firebase_service.dart';
import '../models/task_model.dart';

class TaskController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  var tasks = <Task>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  void fetchTasks() {
    _firebaseService.getAllTasks().listen((snapshot) {
      tasks.value = snapshot
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> createTask(
      String title, String description, String createdBy) async {
    try {
      isLoading(true);

      // Use the new method to create a task with an ID
      await _firebaseService.createTaskWithId({
        "title": title,
        "description": description,
        "createdBy": createdBy,
        "status": "Pending",
        "comments": [],
      });

      Get.snackbar("Success", "Task Created Successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to create task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // New method to add a task
  Future<void> addTask(
      String title, String description, String status) async {
    try {
      isLoading(true);
      
      // You may need to get the current user ID or use a default value
      String createdBy = "current_user_id"; // Replace with actual user ID
      
      await _firebaseService.createTaskWithId({
        "title": title,
        "description": description,
        "createdBy": createdBy,
        "status": status,
        "comments": [],
      });

      Get.snackbar("Success", "Task Added Successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to add task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // New method to update a task
  Future<void> updateTask(
      String taskId, String title, String description, String status) async {
    try {
      isLoading(true);
      
      await _firebaseService.updateTask(taskId, {
        "title": title,
        "description": description,
        "status": status,
      });

      Get.snackbar("Success", "Task Updated Successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to update task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  Future<void> assignTaskToReporter(String taskId, String reporterId) async {
    await _firebaseService.assignTask(taskId, reporterId, "assignedReporter");
  }

  Future<void> assignTaskToCameraman(String taskId, String cameramanId) async {
    await _firebaseService.assignTask(taskId, cameramanId, "assignedCameraman");
  }
}