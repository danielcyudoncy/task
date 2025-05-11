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

  // In-memory cache for user names and task titles
  final Map<String, String> userNameCache = {};
  final Map<String, String> taskTitleCache = {};

  @override
  void onInit() async {
    super.onInit();
    await initializeCache();
    await preFetchUserNames();
    fetchTasks();
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

    print("Caches initialized: UserNameCache: $userNameCache, TaskTitleCache: $taskTitleCache");
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

    print("Caches saved");
  }

  // Pre-fetch all user names and cache them
  Future<void> preFetchUserNames() async {
    try {
      // Check if cache needs to be refreshed
      final prefs = await SharedPreferences.getInstance();
      int? lastUpdate = prefs.getInt("cacheTimestamp");
      if (lastUpdate != null &&
          DateTime.now().millisecondsSinceEpoch - lastUpdate < 86400000) {
        print("Cache is still valid, skipping pre-fetch.");
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
      print("User names pre-fetched and cached!");
    } catch (e) {
      print("Error pre-fetching user names: $e");
    }
  }

  // Fetch tasks and replace UIDs with real names and titles
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
            comments: List<String>.from(
                taskData["comments"] ?? []), // Fix missing comments
            timestamp: taskData["timestamp"] ??
                Timestamp.now(), // Fix missing timestamp
          ));
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

  // Fetch user's full name using UID with caching
  Future<String> _getUserName(String uid) async {
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

  Future<void> updateTask(String taskId, String title, String description, String status) async {
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

  // Fetch task title using taskId with caching
  Future<String> _getTaskTitle(String taskId) async {
    try {
      // Check if the title is already in the cache
      if (taskTitleCache.containsKey(taskId)) {
        return taskTitleCache[taskId]!;
      }

      // If not in cache, fetch from Firestore
      DocumentSnapshot taskDoc =
          await FirebaseFirestore.instance.collection("tasks").doc(taskId).get();

      if (taskDoc.exists) {
        String title = taskDoc["title"] ?? "Unknown";

        // Add the title to the cache
        taskTitleCache[taskId] = title;

        return title;
      } else {
        return "Task not found";
      }
    } catch (e) {
      return "Error fetching task title";
    }
  }
}