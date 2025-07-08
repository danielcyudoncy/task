// controllers/task_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // <-- make sure to import this!
import '../models/task_model.dart';
import '../controllers/auth_controller.dart';
import '../service/firebase_service.dart';
import '../utils/snackbar_utils.dart';
import 'package:rxdart/rxdart.dart' as rx;

class TaskController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthController authController = Get.find<AuthController>();

  var tasks = <Task>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var totalTaskCreated = 0.obs;
  var taskAssigned = 0.obs;
  var newTaskCount = 0.obs;
  var isLoadingStats = false.obs;
  var isRefreshing = false.obs; // Added newTaskCount variable

  final Map<String, String> userNameCache = {};
  final Map<String, String> taskTitleCache = {};

  // Safe snackbar method
  void _safeSnackbar(String title, String message) {
    SnackbarUtils.showSnackbar(title, message);
  }

  // Pagination, filter, and search
  DocumentSnapshot? lastDocument;
  bool hasMore = true;
  final int pageSize = 10;
  String searchTerm = '';
  String filterStatus = 'All';
  String sortBy = 'Newest';

  @override
  void onInit() async {
    super.onInit();
    // Delay initialization to ensure proper setup
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (Get.isRegistered<TaskController>()) {
        await initializeCache();
        await preFetchUserNames();
        await loadInitialTasks();
        fetchTaskCounts();
        calculateNewTaskCount(); // Calculate new task count on init
      }
    });
  }

  @override
  void onClose() {
    saveCache();
    super.onClose();
  }

  // Initialize cache from local storage if available
  Future<void> initializeCache() async {
    final prefs = await SharedPreferences.getInstance();
    String? userCache = prefs.getString("userNameCache");
    if (userCache != null) {
      userNameCache.addAll(Map<String, String>.from(jsonDecode(userCache)));
    }
    String? titleCache = prefs.getString("taskTitleCache");
    if (titleCache != null) {
      taskTitleCache.addAll(Map<String, String>.from(jsonDecode(titleCache)));
    }
  }

  // Save cache to local storage
  Future<void> saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("userNameCache", jsonEncode(userNameCache));
    prefs.setString("taskTitleCache", jsonEncode(taskTitleCache));
    prefs.setInt("cacheTimestamp", DateTime.now().millisecondsSinceEpoch);
  }

  // Pre-fetch all user names and cache them
  Future<void> preFetchUserNames() async {
    try {
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
        userNameCache[uid] = fullName;
      }
      saveCache();
      // ignore: empty_catches
    } catch (e) {}
  }

  // --- PAGINATED, FILTERED, SEARCHABLE TASK LOADING ---
  Future<void> loadInitialTasks(
      {String? search, String? filter, String? sort}) async {
    debugPrint("TaskController: loadInitialTasks called");
    tasks.clear();
    lastDocument = null;
    hasMore = true;
    errorMessage.value = '';
    searchTerm = search ?? searchTerm;
    filterStatus = filter ?? filterStatus;
    sortBy = sort ?? sortBy;
    await loadMoreTasks(reset: true);
    calculateNewTaskCount(); // Calculate new task count after loading tasks
    debugPrint("TaskController: loadInitialTasks completed, tasks count: ${tasks.length}");
  }

 Future<void> loadMoreTasks({bool reset = false}) async {
    if (!hasMore || isLoading.value) return;
    isLoading.value = true;
    try {
      if (reset) {
        tasks.clear();
        lastDocument = null;
      }

      List<QueryDocumentSnapshot> docs = [];

      // --- CASE 1: Search by title and user ---
      if (searchTerm.isNotEmpty) {
        final titleQuery = FirebaseFirestore.instance
            .collection('tasks')
            .where('title', isGreaterThanOrEqualTo: searchTerm)
            .where('title', isLessThanOrEqualTo: '$searchTerm\uf8ff')
            .orderBy('title')
            .limit(pageSize);

        final nameQuery = FirebaseFirestore.instance
            .collection('tasks')
            .where('createdByName', isGreaterThanOrEqualTo: searchTerm)
            .where('createdByName', isLessThanOrEqualTo: '$searchTerm\uf8ff')
            .orderBy('createdByName')
            .limit(pageSize);

        final titleSnap = await titleQuery.get();
        final nameSnap = await nameQuery.get();

        // Merge and deduplicate by document ID
        final seen = <String>{};
        docs = [...titleSnap.docs, ...nameSnap.docs]
            .where((doc) => seen.add(doc.id))
            .toList();
      }
      // --- CASE 2: No search ---
      else {
        Query query = FirebaseFirestore.instance
            .collection('tasks')
            .orderBy('timestamp', descending: sortBy == "Newest")
            .limit(pageSize);

        // Apply status filter
        if (filterStatus != 'All') {
          query = query.where('status', isEqualTo: filterStatus);
        }

        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument!);
        }

        final snapshot = await query.get();
        docs = snapshot.docs;
      }

      List<Task> pageTasks = [];

      for (var doc in docs) {
        var taskData = doc.data() as Map<String, dynamic>;
        String createdByName = await _getUserName(taskData["createdBy"]);
        String assignedReporterName = taskData["assignedReporterName"] ??
            (taskData["assignedReporterId"] != null
                ? await _getUserName(taskData["assignedReporterId"])
                : "Not Assigned");
        String assignedCameramanName = taskData["assignedCameramanName"] ??
            (taskData["assignedCameramanId"] != null
                ? await _getUserName(taskData["assignedCameramanId"])
                : "Not Assigned");
        String taskTitle = taskData["title"];
        taskTitleCache[doc.id] = taskTitle;

        // REMOVED THE ROLE-BASED FILTERING - JUST ADD ALL TASKS
        pageTasks.add(Task(
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
          assignedReporterId: taskData["assignedReporterId"],
          assignedCameramanId: taskData["assignedCameramanId"],
        ));
      }

      tasks.addAll(pageTasks);

      if (docs.isNotEmpty) {
        lastDocument = docs.last;
        if (docs.length < pageSize) hasMore = false;
      } else {
        hasMore = false;
      }

      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = 'Failed to load tasks: $e';
      hasMore = false;
    } finally {
      isLoading.value = false;
    }
  }


  // Calculate new task count
  void calculateNewTaskCount() {
    String? userId = authController.auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      debugPrint("calculateNewTaskCount: User not authenticated");
      newTaskCount.value = 0;
      return;
    }
    
    newTaskCount.value = tasks.where((task) {
      return (task.assignedReporterId == userId || task.assignedCameramanId == userId) &&
          task.status != "Completed";
    }).length;
  }

  // Fetch user's full name using UID with caching
  Future<String> _getUserName(String? uid) async {
    if (uid == null) return "Not Assigned";
    try {
      if (userNameCache.containsKey(uid)) {
        return userNameCache[uid]!;
      }
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();
      if (userDoc.exists) {
        String fullName = userDoc["fullName"] ?? "Unknown";
        userNameCache[uid] = fullName;
        return fullName;
      } else {
        return "User not found";
      }
    } catch (e) {
      return "Error fetching user";
    }
  }

  // Assign a task to a reporter and/or cameraman, saving both the UID and Name for each.
  Future<void> assignTaskWithNames({
    required String taskId,
    String? reporterId,
    String? reporterName,
    String? cameramanId,
    String? cameramanName,
  }) async {
    try {
          debugPrint("=== ASSIGNMENT DEBUG ===");
    debugPrint("Task ID: $taskId");
    debugPrint("Reporter ID: $reporterId");
    debugPrint("Reporter Name: $reporterName");

      final updateData = <String, dynamic>{};

      if (reporterId != null && reporterName != null) {
        updateData['assignedReporterId'] = reporterId;
        updateData['assignedReporterName'] = reporterName;
        debugPrint("✅ Setting reporter: $reporterId");
        updateData['assignmentTimestamp'] = FieldValue.serverTimestamp();
      } else {
        updateData['assignedReporterId'] = null;
        updateData['assignedReporterName'] = null;
        debugPrint("❌ Clearing reporter fields");
      }

      if (cameramanId != null && cameramanName != null) {
        updateData['assignedCameramanId'] = cameramanId;
        updateData['assignedCameramanName'] = cameramanName;
        debugPrint("✅ Setting cameraman: $cameramanId");
        updateData['assignmentTimestamp'] = FieldValue.serverTimestamp();
      } else {
        updateData['assignedCameramanId'] = null;
        updateData['assignedCameramanName'] = null;
        debugPrint("❌ Clearing cameraman fields");
      }

      updateData['assignedAt'] = FieldValue.serverTimestamp();

      debugPrint("📝 Update data: $updateData");

      // Update the task document
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update(updateData);

              debugPrint("✅ Task document updated successfully!");

      // Get task details for notification
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();

              debugPrint("📖 Task doc retrieved: ${taskDoc.exists}");

      if (taskDoc.exists) {
        final String taskTitle =
            (taskDoc.data()?['title'] as String?) ?? 'A task';
        final String taskDescription =
            (taskDoc.data()?['description'] as String?) ?? '';

        DateTime dueDate;
        final dueDateRaw = taskDoc.data()?['dueDate'];
        if (dueDateRaw is Timestamp) {
          dueDate = dueDateRaw.toDate();
        } else if (dueDateRaw is String) {
          dueDate = DateTime.tryParse(dueDateRaw) ?? DateTime.now();
        } else {
          dueDate = DateTime.now();
        }

        final String formattedDate =
            DateFormat('yyyy-MM-dd – kk:mm').format(dueDate);

        // Send notifications without awaiting to prevent blocking
        if (reporterId != null) {
          debugPrint("📧 Sending notification to reporter: $reporterId");
          FirebaseFirestore.instance
              .collection('users')
              .doc(reporterId)
              .collection('notifications')
              .add({
                'type': 'task_assigned',
                'taskId': taskId,
                'title': taskTitle,
                'message': 'Description: $taskDescription\nDue: $formattedDate',
                'isRead': false,
                'timestamp': FieldValue.serverTimestamp(),
              })
                          .then((_) => debugPrint("✅ Reporter notification sent"))
            .catchError((e) => debugPrint("❌ Reporter notification error: $e"));
        }

        if (cameramanId != null) {
          debugPrint("📧 Sending notification to cameraman: $cameramanId");
          FirebaseFirestore.instance
              .collection('users')
              .doc(cameramanId)
              .collection('notifications')
              .add({
                'type': 'task_assigned',
                'taskId': taskId,
                'title': taskTitle,
                'message': 'Description: $taskDescription\nDue: $formattedDate',
                'isRead': false,
                'timestamp': FieldValue.serverTimestamp(),
              })
                          .then((_) => debugPrint("✅ Cameraman notification sent"))
            .catchError((e) => debugPrint("❌ Cameraman notification error: $e"));
        }
      }

      // Use a delayed call to avoid setState after dispose
      Future.delayed(const Duration(milliseconds: 100), () {
        calculateNewTaskCount();
        debugPrint("🔄 Task count recalculated");
      });

              debugPrint("=== ASSIGNMENT COMPLETE ===");
    } catch (e) {
              debugPrint("❌ Assignment error: $e");
        debugPrint("Stack trace: ${StackTrace.current}");
      // Don't show snackbar here since dialog might be closed
    }
  }



  // Fetch task counts using the new fields
  Future<void> fetchTaskCounts() async {
    try {
      // Check if user is authenticated
      if (authController.auth.currentUser == null) {
        debugPrint("fetchTaskCounts: User not authenticated yet, retrying in 1 second...");
        // Retry after a short delay
        await Future.delayed(const Duration(seconds: 1));
        if (authController.auth.currentUser == null) {
          debugPrint("fetchTaskCounts: User still not authenticated, skipping");
          return;
        }
      }
      
      String userId = authController.auth.currentUser!.uid;
      String userRole = authController.userRole.value;
      
      // Check if userRole is available
      if (userRole.isEmpty) {
        debugPrint("fetchTaskCounts: User role not loaded yet, retrying in 1 second...");
        await Future.delayed(const Duration(seconds: 1));
        userRole = authController.userRole.value;
        if (userRole.isEmpty) {
          debugPrint("fetchTaskCounts: User role still not available, skipping");
          return;
        }
      }
      
      final querySnapshot = await _firebaseService.getAllTasks().first;
      final docs = querySnapshot.docs;

          debugPrint("=== ENHANCED DEBUG ===");
    debugPrint("Current User ID: $userId");
    debugPrint("User Role: $userRole");
    debugPrint("Total tasks in database: ${docs.length}");

      // Check ALL tasks and their assignment fields
      for (int i = 0; i < docs.length; i++) {
        final doc = docs[i];
        final data = doc.data() as Map<String, dynamic>;

        debugPrint("\n--- Task ${i + 1}: ${doc.id} ---");
        debugPrint("Title: ${data['title']}");
        debugPrint("createdBy: ${data['createdBy']}");
        debugPrint("assignedTo: ${data['assignedTo']}");
        debugPrint("assignedReporterId: ${data['assignedReporterId']}");
        debugPrint("assignedCameramanId: ${data['assignedCameramanId']}");
        debugPrint("assignedReporterName: ${data['assignedReporterName']}");
        debugPrint("assignedCameramanName: ${data['assignedCameramanName']}");

        // Check each condition
        bool createdByUser = data["createdBy"] == userId;
        bool assignedToUser = data["assignedTo"] == userId;
        bool assignedAsReporter = data["assignedReporterId"] == userId;
        bool assignedAsCameraman = data["assignedCameramanId"] == userId;

        debugPrint("Created by current user: $createdByUser");
        debugPrint("Assigned to current user (general): $assignedToUser");
        debugPrint("Assigned as reporter: $assignedAsReporter");
        debugPrint("Assigned as cameraman: $assignedAsCameraman");

        if (createdByUser ||
            assignedToUser ||
            assignedAsReporter ||
            assignedAsCameraman) {
          debugPrint("*** THIS TASK SHOULD BE COUNTED ***");
        }
      }

      // Count tasks created by user
      var createdTasks = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data["createdBy"] == userId;
      }).toList();

      totalTaskCreated.value = createdTasks.length;
              debugPrint("\nTasks created by user: ${createdTasks.length}");

      // Count tasks assigned to user
      var assignedTasks = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data["assignedTo"] == userId ||
            data["assignedReporterId"] == userId ||
            data["assignedCameramanId"] == userId;
      }).toList();

      taskAssigned.value = assignedTasks.length;
      debugPrint("Tasks assigned to user: ${assignedTasks.length}");

      debugPrint("=== END ENHANCED DEBUG ===\n");

      calculateNewTaskCount();
    } catch (e) {
      _safeSnackbar("Error", "Failed to fetch task counts: ${e.toString()}");
      debugPrint("Error in fetchTaskCounts: $e");
    }
  }



  // --- LEGACY STREAMING (for other screens if needed) ---
  void fetchTasks() {
    if (isLoading.value) return; // Prevent multiple simultaneous calls
    
    isLoading(true);
    try {
      String userRole = authController.userRole.value;
      String? userId = authController.auth.currentUser?.uid;
      
      if (userId == null) {
        debugPrint("TaskController: No user ID available for fetchTasks");
        isLoading(false);
        return;
      }
      
      Stream<QuerySnapshot> taskStream = _firebaseService.getAllTasks();
      taskStream.listen((snapshot) async {
        try {
          List<Task> updatedTasks = [];
          
          for (var doc in snapshot.docs) {
            var taskData = doc.data() as Map<String, dynamic>;
            String createdByName = await _getUserName(taskData["createdBy"]);
            String assignedReporterName = taskData["assignedReporterName"] ??
                (taskData["assignedReporterId"] != null
                    ? await _getUserName(taskData["assignedReporterId"])
                    : "Not Assigned");
            String assignedCameramanName = taskData["assignedCameramanName"] ??
                (taskData["assignedCameramanId"] != null
                    ? await _getUserName(taskData["assignedCameramanId"])
                    : "Not Assigned");
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
              assignedReporterId: taskData["assignedReporterId"],
              assignedCameramanId: taskData["assignedCameramanId"],
            ));
          }
          
          // Role-based filtering
          if (userRole == "Reporter" || userRole == "Cameraman") {
            updatedTasks = updatedTasks
                .where((task) =>
                    (task.createdById == userId) ||
                    (task.assignedTo == userId) ||
                    (task.assignedReporterId == userId) ||
                    (task.assignedCameramanId == userId))
                .toList();
          }
          
          tasks.value = updatedTasks;
          calculateNewTaskCount(); // Calculate new task count after fetching tasks
          saveCache();
        } catch (e) {
          debugPrint("TaskController: Error processing task stream: $e");
        }
      }, onError: (error) {
        debugPrint("TaskController: Stream error: $error");
        isLoading(false);
      });
    } catch (e) {
      debugPrint("TaskController: Error in fetchTasks: $e");
      _safeSnackbar("Error", "Failed to fetch tasks: ${e.toString()}");
      isLoading(false);
    }
  }

  // --- TASK CRUD ---
 Future<void> createTask(
    String title,
    String description, {
    String priority = 'Normal',
    DateTime? dueDate,
  }) async {
    debugPrint('createTask: started');
    try {
      // Check authentication
      if (authController.auth.currentUser == null) {
        debugPrint('createTask: ERROR - user is not authenticated');
        throw Exception('User not authenticated');
      }

      // Get current user info
      String userId = authController.auth.currentUser!.uid;
      String userRole = authController.userRole.value;
      debugPrint('createTask: userId = $userId, role = $userRole');

      // Check if user has permission to create tasks
      if (!authController.isAdmin.value &&
          !authController.canCreateTasks.value) {
        debugPrint('createTask: ERROR - user does not have create permission');
        throw Exception('You do not have permission to create tasks');
      }

      isLoading(true);
      debugPrint('createTask: isLoading set to true');
      debugPrint('createTask: creating task in Firebase');

      // Create task data
      final taskData = {
        "title": title,
        "description": description,
        "createdBy": userId,
        "createdByName": authController.fullName.value,
        "creatorAvatar": authController.profilePic.value,
        "assignedReporterId": null,
        "assignedReporterName": null,
        "assignedCameramanId": null,
        "assignedCameramanName": null,
        "status": "Pending",
        "priority": priority,
        "dueDate": dueDate?.toIso8601String(),
        "comments": [],
        "timestamp": FieldValue.serverTimestamp(),
      };

      debugPrint('createTask: taskData = $taskData');
      debugPrint('createTask: calling _firebaseService.createTask');
      await _firebaseService.createTask(taskData);
      debugPrint('createTask: Firebase call complete');

      // Update local state
      debugPrint('createTask: refreshing tasks');
      tasks.refresh();
      debugPrint('createTask: calculating new task count');
      calculateNewTaskCount();

      // Show success message
      debugPrint('createTask: showing success snackbar');
      _safeSnackbar("Success", "Task created successfully");

      // Return success
      debugPrint('createTask: finished successfully');
      return;
    } catch (e) {
      debugPrint('createTask: error: $e');
      _safeSnackbar("Error", "Failed to create task: "+e.toString());
      rethrow; // Re-throw to let the UI know creation failed
    } finally {
      debugPrint('createTask: finally block - resetting loading state');
      isLoading(false);
    }
  }

  Future<void> updateTask(
      String taskId, String title, String description, String status) async {
    try {
      isLoading(true);
      await _firebaseService.updateTask(taskId, {
        "title": title,
        "description": description,
        "status": status,
      });
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
      _safeSnackbar("Success", "Task updated successfully");
      calculateNewTaskCount(); // Calculate new task count after updating task
    } catch (e) {
      _safeSnackbar("Error", "Failed to update task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      isLoading(true);
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
      tasks.removeWhere((task) => task.taskId == taskId);
      tasks.refresh();
      _safeSnackbar("Success", "Task deleted successfully");
      calculateNewTaskCount(); // Calculate new task count after deleting task
    } catch (e) {
      _safeSnackbar("Error", "Failed to delete task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      isLoading(true);
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({'status': newStatus});
      int taskIndex = tasks.indexWhere((task) => task.taskId == taskId);
      if (taskIndex != -1) {
        Task updatedTask = tasks[taskIndex].copyWith(
          status: newStatus,
        );
        tasks[taskIndex] = updatedTask;
        tasks.refresh();
      }
      _safeSnackbar("Success", "Task status updated");
      calculateNewTaskCount(); // Calculate new task count after updating task status
    } catch (e) {
      _safeSnackbar("Error", "Failed to update task status: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }
  // --- LEGACY (optional) ---
  Future<void> assignTaskToReporter(String taskId, String reporterId) async {
    try {
      isLoading(true);
      await _firebaseService.assignTask(
          taskId, reporterId, "assignedReporterId");
      _safeSnackbar("Success", "Task assigned to Reporter successfully");
    } catch (e) {
      _safeSnackbar("Error", "Failed to assign task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  Future<void> assignTaskToCameraman(String taskId, String cameramanId) async {
    try {
      isLoading(true);
      await _firebaseService.assignTask(
          taskId, cameramanId, "assignedCameramanId");
      _safeSnackbar("Success", "Task assigned to Cameraman successfully");
    } catch (e) {
      _safeSnackbar("Error", "Failed to assign task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }
  // ========== ADD THESE NEW METHODS TO YOUR EXISTING CONTROLLER ========== //

  /// Get all tasks without any filters or pagination
  Future<List<Task>> getAllTasks() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .orderBy('timestamp', descending: true)
          .get();

      return await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final createdByName = await _getUserName(data["createdBy"]);
        final assignedReporterName = data["assignedReporterName"] ??
            (data["assignedReporterId"] != null
                ? await _getUserName(data["assignedReporterId"])
                : "Not Assigned");
        final assignedCameramanName = data["assignedCameramanName"] ??
            (data["assignedCameramanId"] != null
                ? await _getUserName(data["assignedCameramanId"])
                : "Not Assigned");

        return Task(
          taskId: doc.id,
          title: data["title"],
          description: data["description"],
          createdBy: createdByName,
          assignedReporter: assignedReporterName,
          assignedCameraman: assignedCameramanName,
          status: data["status"] ?? "Pending",
          comments: List<String>.from(data["comments"] ?? []),
          timestamp: data["timestamp"] ?? Timestamp.now(),
          createdById: data["createdBy"] ?? "",
          assignedReporterId: data["assignedReporterId"],
          assignedCameramanId: data["assignedCameramanId"],
        );
      }));
    } catch (e) {
      errorMessage.value = 'Failed to get all tasks: $e';
      return [];
    }
  }

  /// Get tasks assigned to current user
   /// Get tasks assigned to current user
  Future<List<Task>> getMyAssignedTasks() async {
    try {
      final userId = authController.auth.currentUser?.uid ?? "";
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedReporterId', isEqualTo: userId)
          .get();

      return await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final createdByName = await _getUserName(data["createdBy"]);
        final assignedReporterName = data["assignedReporterName"] ?? 
            (data["assignedReporterId"] != null 
                ? await _getUserName(data["assignedReporterId"]) 
                : "Not Assigned");
        final assignedCameramanName = data["assignedCameramanName"] ?? 
            (data["assignedCameramanId"] != null 
                ? await _getUserName(data["assignedCameramanId"]) 
                : "Not Assigned");

        return Task(
          taskId: doc.id,
          title: data["title"] ?? "",
          description: data["description"] ?? "",
          createdBy: createdByName,
          assignedReporter: assignedReporterName,
          assignedCameraman: assignedCameramanName,
          status: data["status"] ?? "Pending",
          comments: List<String>.from(data["comments"] ?? []),
          timestamp: data["timestamp"] ?? Timestamp.now(),
          createdById: data["createdBy"] ?? "",
          assignedReporterId: data["assignedReporterId"],
          assignedCameramanId: data["assignedCameramanId"],
        );
      }));
    } catch (e) {
      errorMessage.value = 'Failed to get assigned tasks: $e';
      return [];
    }
  }

  /// Get tasks created by current user
  Future<List<Task>> getMyCreatedTasks() async {
    try {
      final userId = authController.auth.currentUser?.uid ?? "";
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('createdBy', isEqualTo: userId)
          .get();

      return await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final createdByName = await _getUserName(data["createdBy"]);
        final assignedReporterName = data["assignedReporterName"] ?? 
            (data["assignedReporterId"] != null 
                ? await _getUserName(data["assignedReporterId"]) 
                : "Not Assigned");
        final assignedCameramanName = data["assignedCameramanName"] ?? 
            (data["assignedCameramanId"] != null 
                ? await _getUserName(data["assignedCameramanId"]) 
                : "Not Assigned");

        return Task(
          taskId: doc.id,
          title: data["title"] ?? "",
          description: data["description"] ?? "",
          createdBy: createdByName,
          assignedReporter: assignedReporterName,
          assignedCameraman: assignedCameramanName,
          status: data["status"] ?? "Pending",
          comments: List<String>.from(data["comments"] ?? []),
          timestamp: data["timestamp"] ?? Timestamp.now(),
          createdById: data["createdBy"] ?? "",
          assignedReporterId: data["assignedReporterId"],
          assignedCameramanId: data["assignedCameramanId"],
        );
      }));
    } catch (e) {
      errorMessage.value = 'Failed to get created tasks: $e';
      return [];
    }
  }

  /// Get task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final createdByName = await _getUserName(data["createdBy"]);
        final assignedReporterName = data["assignedReporterName"] ?? 
            (data["assignedReporterId"] != null 
                ? await _getUserName(data["assignedReporterId"]) 
                : "Not Assigned");
        final assignedCameramanName = data["assignedCameramanName"] ?? 
            (data["assignedCameramanId"] != null 
                ? await _getUserName(data["assignedCameramanId"]) 
                : "Not Assigned");

        return Task(
          taskId: doc.id,
          title: data["title"] ?? "",
          description: data["description"] ?? "",
          createdBy: createdByName,
          assignedReporter: assignedReporterName,
          assignedCameraman: assignedCameramanName,
          status: data["status"] ?? "Pending",
          comments: List<String>.from(data["comments"] ?? []),
          timestamp: data["timestamp"] ?? Timestamp.now(),
          createdById: data["createdBy"] ?? "",
          assignedReporterId: data["assignedReporterId"],
          assignedCameramanId: data["assignedCameramanId"],
        );
      }
      return null;
    } catch (e) {
      errorMessage.value = 'Failed to get task: $e';
      return null;
    }
  }

  /// Add comment to a task (no changes needed to this one as it was correct)
  Future<void> addComment(String taskId, String comment) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'comments': FieldValue.arrayUnion([comment]),
        'lastUpdated': FieldValue.serverTimestamp()
      });

      // Update local task if it exists
      final index = tasks.indexWhere((t) => t.taskId == taskId);
      if (index != -1) {
        final updatedTask = tasks[index]
            .copyWith(comments: [...tasks[index].comments, comment]);
        tasks[index] = updatedTask;
        tasks.refresh();
      }
    } catch (e) {
      _safeSnackbar("Error", "Failed to add comment: ${e.toString()}");
    }
  }

  /// Get the count of all tasks assigned to a user (assignedTo, assignedReporterId, assignedCameramanId)
  Future<int> getAssignedTasksCountForUser(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .get();
    final reporterSnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedReporterId', isEqualTo: userId)
        .get();
    final cameramanSnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedCameramanId', isEqualTo: userId)
        .get();

    // Use a set to avoid double-counting tasks assigned in multiple ways
    final taskIds = <String>{};
    taskIds.addAll(snapshot.docs.map((doc) => doc.id));
    taskIds.addAll(reporterSnapshot.docs.map((doc) => doc.id));
    taskIds.addAll(cameramanSnapshot.docs.map((doc) => doc.id));
    return taskIds.length;
  }

  /// Stream of all non-completed tasks assigned to a user (assignedTo, assignedReporterId, assignedCameramanId)
  Stream<int> assignedTasksCountStream(String userId) {
    final assignedToStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .snapshots();
    final reporterStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedReporterId', isEqualTo: userId)
        .snapshots();
    final cameramanStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedCameramanId', isEqualTo: userId)
        .snapshots();

    return rx.CombineLatestStream.combine3<QuerySnapshot, QuerySnapshot, QuerySnapshot, int>(
      assignedToStream,
      reporterStream,
      cameramanStream,
      (a, b, c) {
        final taskIds = <String>{};
        taskIds.addAll(a.docs.map((doc) => doc.id));
        taskIds.addAll(b.docs.map((doc) => doc.id));
        taskIds.addAll(c.docs.map((doc) => doc.id));
        return taskIds.length;
      },
    );
  }
}
