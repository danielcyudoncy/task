// controllers/task_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task_model.dart';
import '../controllers/auth_controller.dart';
import '../service/firebase_service.dart';

class TaskController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthController authController = Get.find<AuthController>();

  var tasks = <Task>[].obs;
  var isLoading = false.obs;
  var totalTaskCreated = 0.obs;
  var taskAssigned = 0.obs;

  // In-memory cache for user names and task titles
  final Map<String, String> userNameCache = {};
  final Map<String, String> taskTitleCache = {};

  @override
  void onInit() async {
    super.onInit();
    await initializeCache();
    await preFetchUserNames();
    fetchTasks();
    fetchTaskCounts();
  }

  @override
  void onClose() {
    saveCache(); // Save the cache when the controller is disposed
    super.onClose();
  }

  // Initialize cache from local storage if available
  Future<void> initializeCache() async {
    final prefs = await SharedPreferences.getInstance();

    // Load user name cache
    String? userCache = prefs.getString("userNameCache");
    if (userCache != null) {
      userNameCache.addAll(Map<String, String>.from(jsonDecode(userCache)));
    }

    // Load task title cache
    String? titleCache = prefs.getString("taskTitleCache");
    if (titleCache != null) {
      taskTitleCache.addAll(Map<String, String>.from(jsonDecode(titleCache)));
    }
  }

  // Save cache to local storage
  Future<void> saveCache() async {
    final prefs = await SharedPreferences.getInstance();

    // Save user name cache
    prefs.setString("userNameCache", jsonEncode(userNameCache));

    // Save task title cache
    prefs.setString("taskTitleCache", jsonEncode(taskTitleCache));

    // Save timestamp for cache expiration
    prefs.setInt("cacheTimestamp", DateTime.now().millisecondsSinceEpoch);
  }

  // Pre-fetch all user names and cache them
  Future<void> preFetchUserNames() async {
    try {
      // Check if cache needs to be refreshed
      final prefs = await SharedPreferences.getInstance();
      int? lastUpdate = prefs.getInt("cacheTimestamp");
      if (lastUpdate != null &&
          DateTime.now().millisecondsSinceEpoch - lastUpdate < 86400000) {
        return;
      }

      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection("users").get();

      for (var doc in usersSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String uid = doc.id;
        String fullName = data["fullName"] ?? "Unknown";

        // Add all users to the cache
        userNameCache[uid] = fullName;
      }

      // Save updated cache
      saveCache();
    } catch (e) {}
  }

  // Fetch tasks and replace UIDs with real names and titles
  void fetchTasks() {
    isLoading(true);
    try {
      Stream<QuerySnapshot> taskStream;
      String userRole = authController.userRole.value;

      // Always fetch all tasks, filtering by role below
      taskStream = _firebaseService.getAllTasks();

      taskStream.listen((snapshot) async {
        List<Task> updatedTasks = [];
        // Move userId here, where it's actually used
        String userId = authController.auth.currentUser!.uid;

        for (var doc in snapshot.docs) {
          var taskData = doc.data() as Map<String, dynamic>;

          // Replace creator's UID with name
          String createdByName = await _getUserName(taskData["createdBy"]);

          // Replace assigned reporter UID with name
          String assignedReporterName = taskData["assignedReporter"] != null
              ? await _getUserName(taskData["assignedReporter"])
              : "Not Assigned";

          // Replace assigned cameraman UID with name
          String assignedCameramanName = taskData["assignedCameraman"] != null
              ? await _getUserName(taskData["assignedCameraman"])
              : "Not Assigned";

          // Cache task title
          String taskTitle = taskData["title"];
          taskTitleCache[doc.id] = taskTitle;

          updatedTasks.add(Task(
            taskId: doc.id,
            title: taskTitle,
            description: taskData["description"],
            createdBy: createdByName,
            assignedReporter: assignedReporterName,
            assignedCameraman: assignedCameramanName,
            status: taskData["status"] ?? "Pending",
            comments: List<String>.from(taskData["comments"] ?? []),
            timestamp: taskData["timestamp"] ?? Timestamp.now(),
            createdById: taskData["createdBy"] ?? "",
            assignedReporterId: taskData["assignedReporter"],
            assignedCameramanId: taskData["assignedCameraman"],
          ));
        }

        // Role-based filtering
        if (userRole == "Reporter") {
          updatedTasks = updatedTasks
              .where((task) =>
                  (task.assignedReporterId == userId) ||
                  (task.createdById == userId))
              .toList();
        } else if (userRole == "Cameraman") {
          updatedTasks = updatedTasks
              .where((task) =>
                  (task.assignedCameramanId == userId) ||
                  (task.createdById == userId))
              .toList();
        }

        tasks.value = updatedTasks;
        saveCache(); // Save the updated cache
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch tasks: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // Fetch task counts
  Future<void> fetchTaskCounts() async {
    try {
      String userId = authController.auth.currentUser!.uid;

      final queryCreated = await _firebaseService.getAllTasks().first;
      totalTaskCreated.value =
          queryCreated.docs.where((doc) => doc["createdBy"] == userId).length;

      final queryAssigned = await _firebaseService.getAllTasks().first;
      taskAssigned.value = queryAssigned.docs
          .where((doc) =>
              doc["assignedReporter"] == userId ||
              doc["assignedCameraman"] == userId)
          .length;
    } catch (e) {
      print('Error fetching task counts: $e');
    }
  }

  // Fetch user's full name using UID with caching
  Future<String> _getUserName(String? uid) async {
    if (uid == null) return "Not Assigned";
    try {
      // Check if the name is already in the cache
      if (userNameCache.containsKey(uid)) {
        return userNameCache[uid]!;
      }

      // If not in cache, fetch from Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (userDoc.exists) {
        String fullName = userDoc["fullName"] ?? "Unknown";

        // Add the name to the cache
        userNameCache[uid] = fullName;

        return fullName;
      } else {
        return "User not found";
      }
    } catch (e) {
      return "Error fetching user";
    }
  }

  // Assign Task to Reporter
  Future<void> assignTaskToReporter(String taskId, String reporterId) async {
    try {
      isLoading(true);
      await _firebaseService.assignTask(taskId, reporterId, "assignedReporter");
      Get.snackbar("Success", "Task assigned to Reporter successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to assign task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // Assign Task to Cameraman
  Future<void> assignTaskToCameraman(String taskId, String cameramanId) async {
    try {
      isLoading(true);
      await _firebaseService.assignTask(
          taskId, cameramanId, "assignedCameraman");
      Get.snackbar("Success", "Task assigned to Cameraman successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to assign task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // Create a new task
  Future<void> createTask(String title, String description) async {
    try {
      isLoading(true);
      String userId = authController.auth.currentUser!.uid;

      await _firebaseService.createTask({
        "title": title,
        "description": description,
        "createdBy": userId,
        "assignedReporter": null,
        "assignedCameraman": null,
        "status": "Pending",
        "comments": [],
        "timestamp": FieldValue.serverTimestamp(),
      });

      Get.snackbar("Success", "Task created successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to create task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateTask(
      String taskId, String title, String description, String status) async {
    try {
      isLoading(true);
      // Call Firestore service to update the task
      await _firebaseService.updateTask(taskId, {
        "title": title,
        "description": description,
        "status": status,
      });

      // Update the local task list if necessary
      int taskIndex = tasks.indexWhere((task) => task.taskId == taskId);
      if (taskIndex != -1) {
        Task updatedTask = tasks[taskIndex].copyWith(
          title: title,
          description: description,
          status: status,
        );
        tasks[taskIndex] = updatedTask;
        tasks.refresh();
      }

      Get.snackbar("Success", "Task updated successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to update task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }
}
