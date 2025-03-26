// controllers/task_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../controllers/auth_controller.dart';
import '../service/firebase_service.dart';

class TaskController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService(); // ✅ Fixed undefined _firebaseService
  final AuthController authController = Get.find<AuthController>();

  var tasks = <Task>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  // ✅ Fetch tasks based on user role
  void fetchTasks() {
    isLoading(true);
    try {
      Stream<QuerySnapshot> taskStream;
      String userRole = authController.userRole.value;
      String userId = authController.auth.currentUser!.uid;

      if (userRole == "Reporter" || userRole == "Cameraman") {
        // ✅ Fetch only tasks created by the logged-in user
        taskStream = _firebaseService.getTasksByUser(userId);
      } else {
        // ✅ Admin, Assignment Editors, and HoD see all tasks
        taskStream = _firebaseService.getAllTasks();
      }

      taskStream.listen((snapshot) {
        tasks.value = snapshot.docs
            .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch tasks: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // ✅ Create a new task (Now correctly expects 3 parameters)
  Future<void> createTask(String title, String description, String userId) async {
    try {
      isLoading(true);

      await _firebaseService.createTask({
        "title": title,
        "description": description,
        "createdBy": userId, // ✅ Store creator ID
        "status": "Pending",
        "comments": [],
      });

      Get.snackbar("Success", "Task created successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to create task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // ✅ Update Task
  Future<void> updateTask(String taskId, String title, String description, String status) async {
    try {
      isLoading(true);
      await _firebaseService.updateTask(taskId, {
        "title": title,
        "description": description,
        "status": status,
      });

      Get.snackbar("Success", "Task updated successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to update task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // ✅ Assign Task to Reporter
  Future<void> assignTaskToReporter(String taskId, String reporterId) async {
    await _firebaseService.assignTask(taskId, reporterId, "assignedReporter");
  }

  // ✅ Assign Task to Cameraman
  Future<void> assignTaskToCameraman(String taskId, String cameramanId) async {
    await _firebaseService.assignTask(taskId, cameramanId, "assignedCameraman");
  }
}
