// controllers/task_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../controllers/auth_controller.dart';
import '../service/firebase_service.dart';

class TaskController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthController authController = Get.find<AuthController>();

  var tasks = <Task>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  // ✅ Fetch tasks & replace UIDs with real names
  void fetchTasks() {
    isLoading(true);
    try {
      Stream<QuerySnapshot> taskStream;
      String userRole = authController.userRole.value;
      String userId = authController.auth.currentUser!.uid;

      if (userRole == "Reporter" || userRole == "Cameraman") {
        taskStream = _firebaseService.getTasksByUser(userId);
      } else {
        taskStream = _firebaseService.getAllTasks();
      }

      taskStream.listen((snapshot) async {
        List<Task> updatedTasks = [];

        for (var doc in snapshot.docs) {
          var taskData = doc.data() as Map<String, dynamic>;

          // ✅ Replace creator's UID with name
          String createdByName = await _getUserName(taskData["createdBy"]);

          // ✅ Replace assigned reporter UID with name
          String assignedReporterName = taskData["assignedReporter"] != null
              ? await _getUserName(taskData["assignedReporter"])
              : "Not Assigned";

          // ✅ Replace assigned cameraman UID with name
          String assignedCameramanName = taskData["assignedCameraman"] != null
              ? await _getUserName(taskData["assignedCameraman"])
              : "Not Assigned";

          updatedTasks.add(Task(
            taskId: doc.id,
            title: taskData["title"],
            description: taskData["description"],
            createdBy: createdByName,
            assignedReporter: assignedReporterName,
            assignedCameraman: assignedCameramanName,
            status: taskData["status"] ?? "Pending",
            comments: List<String>.from(
                taskData["comments"] ?? []), // ✅ Fix missing comments
            timestamp: taskData["timestamp"] ??
                Timestamp.now(), // ✅ Fix missing timestamp
          ));
        }

        tasks.value = updatedTasks;
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch tasks: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // ✅ Create a new task
  Future<void> createTask(String title, String description) async {
    try {
      isLoading(true);
      String userId = authController.auth.currentUser!.uid;

      await _firebaseService.createTask({
        "title": title,
        "description": description,
        "createdBy": userId,
        "assignedReporter": null, // ✅ Initially null
        "assignedCameraman": null, // ✅ Initially null
        "status": "Pending",
        "comments": [], // ✅ Fix: Ensure comments exist
        "timestamp":
            FieldValue.serverTimestamp(), // ✅ Fix: Ensure timestamp exists
      });

      Get.snackbar("Success", "Task created successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to create task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // ✅ Update Task
  Future<void> updateTask(
      String taskId, String title, String description, String status) async {
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

  // ✅ Assign Task to Reporter & Update UI
  Future<void> assignTaskToReporter(String taskId, String reporterId) async {
    try {
      await _firebaseService.assignTask(taskId, reporterId, "assignedReporter");

      // ✅ Fetch updated reporter name
      String reporterName = await _getUserName(reporterId);

      // ✅ Find the task and create a new updated Task object
      int taskIndex = tasks.indexWhere((task) => task.taskId == taskId);
      if (taskIndex != -1) {
        Task updatedTask = Task(
          taskId: tasks[taskIndex].taskId,
          title: tasks[taskIndex].title,
          description: tasks[taskIndex].description,
          createdBy: tasks[taskIndex].createdBy,
          assignedReporter: reporterName, // ✅ Updated
          assignedCameraman: tasks[taskIndex].assignedCameraman,
          status: tasks[taskIndex].status,
          comments: tasks[taskIndex].comments,
          timestamp: tasks[taskIndex].timestamp,
        );
        tasks[taskIndex] = updatedTask;
        tasks.refresh();
      }

      Get.snackbar("Success", "Task assigned to Reporter successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to assign task: ${e.toString()}");
    }
  }

  // ✅ Assign Task to Cameraman & Update UI
  Future<void> assignTaskToCameraman(String taskId, String cameramanId) async {
    try {
      await _firebaseService.assignTask(
          taskId, cameramanId, "assignedCameraman");

      // ✅ Fetch updated cameraman name
      String cameramanName = await _getUserName(cameramanId);

      // ✅ Find the task and create a new updated Task object
      int taskIndex = tasks.indexWhere((task) => task.taskId == taskId);
      if (taskIndex != -1) {
        Task updatedTask = Task(
          taskId: tasks[taskIndex].taskId,
          title: tasks[taskIndex].title,
          description: tasks[taskIndex].description,
          createdBy: tasks[taskIndex].createdBy,
          assignedReporter: tasks[taskIndex].assignedReporter,
          assignedCameraman: cameramanName, // ✅ Updated
          status: tasks[taskIndex].status,
          comments: tasks[taskIndex].comments,
          timestamp: tasks[taskIndex].timestamp,
        );
        tasks[taskIndex] = updatedTask;
        tasks.refresh();
      }

      Get.snackbar("Success", "Task assigned to Cameraman successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to assign task: ${e.toString()}");
    }
  }

  // ✅ Fetch user's full name using UID
  Future<String> _getUserName(String uid) async {
    try {
      if (uid.isEmpty) return "Unknown";
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      // Ensure that the user exists and return the fullName
      if (userDoc.exists) {
        return userDoc["fullName"] ?? "Unknown";
      } else {
        return "User not found";
      }
    } catch (e) {
      return "Error fetching user";
    }
  }
}
