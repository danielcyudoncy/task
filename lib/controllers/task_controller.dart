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
import 'package:task/service/fcm_service.dart';

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
  final Map<String, String> userAvatarCache = {};
  final Map<String, String> taskTitleCache = {};

  // Safe snackbar method
  void _safeSnackbar(String title, String message) {
    SnackbarUtils.showSnackbar(title, message);
  }

  // Helper method to validate and clean avatar URLs
  String _validateAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    
    // If it's already a valid network URL, return it
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // If it's a local file path, return empty string
    if (url.startsWith('file://') || url.startsWith('/')) {
      return '';
    }
    
    return '';
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
    await loadCache();
  }

  // Save cache to local storage
  Future<void> saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("userNameCache", jsonEncode(userNameCache));
    prefs.setString("userAvatarCache", jsonEncode(userAvatarCache));
    prefs.setString("taskTitleCache", jsonEncode(taskTitleCache));
    prefs.setInt("cacheTimestamp", DateTime.now().millisecondsSinceEpoch);
  }

  // Load cache from local storage
  Future<void> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userNameCacheString = prefs.getString("userNameCache");
      final userAvatarCacheString = prefs.getString("userAvatarCache");
      final taskTitleCacheString = prefs.getString("taskTitleCache");
      
      if (userNameCacheString != null) {
        final Map<String, dynamic> decoded = jsonDecode(userNameCacheString);
        userNameCache.clear();
        userNameCache.addAll(Map<String, String>.from(decoded));
      }
      
      if (userAvatarCacheString != null) {
        final Map<String, dynamic> decoded = jsonDecode(userAvatarCacheString);
        userAvatarCache.clear();
        userAvatarCache.addAll(Map<String, String>.from(decoded));
      }
      
      if (taskTitleCacheString != null) {
        final Map<String, dynamic> decoded = jsonDecode(taskTitleCacheString);
        taskTitleCache.clear();
        taskTitleCache.addAll(Map<String, String>.from(decoded));
      }
    } catch (e) {
      // debugPrint("TaskController: Error loading cache: $e");
    }
  }

  // Pre-fetch all user names and avatars and cache them
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
        String photoUrl = _validateAvatarUrl(data["photoUrl"]);
        userNameCache[uid] = fullName;
        userAvatarCache[uid] = photoUrl;
      }
      saveCache();
    } catch (e) {
      // debugPrint("TaskController: Error in preFetchUserNames: $e");
    }
  }

  // --- PAGINATED, FILTERED, SEARCHABLE TASK LOADING ---
  Future<void> loadInitialTasks(
      {String? search, String? filter, String? sort}) async {
    tasks.clear();
    lastDocument = null;
    hasMore = true;
    errorMessage.value = '';
    searchTerm = search ?? searchTerm;
    filterStatus = filter ?? filterStatus;
    sortBy = sort ?? sortBy;
    await loadMoreTasks(reset: true);
    calculateNewTaskCount(); // Calculate new task count after loading tasks
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

        // Use Task.fromMap to ensure all fields are included
        final task = Task.fromMap(taskData, doc.id);
        debugPrint('TaskController: loaded task ${task.taskId} with category=${task.category}, tags=${task.tags}, dueDate=${task.dueDate}');
        pageTasks.add(task);
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

  // Method specifically for AllTaskScreen - loads all tasks without role filtering
  Future<void> loadAllTasksForAllUsers({
    String? search,
    String? filter,
    String? sort,
  }) async {
    // Reset loading state to ensure we can proceed
    isLoading.value = false;
    hasMore = true;
    tasks.clear();
    lastDocument = null;
    errorMessage.value = '';
    searchTerm = search ?? searchTerm;
    filterStatus = filter ?? filterStatus;
    sortBy = sort ?? sortBy;
    await loadMoreTasksForAllUsers(reset: true);
  }

  Future<void> loadMoreTasksForAllUsers({bool reset = false}) async {
    if (!hasMore || isLoading.value) {
      return;
    }
    isLoading.value = true;
    try {
      if (reset) {
        tasks.clear();
        lastDocument = null;
        hasMore = true; // Reset hasMore when resetting
      }

      List<QueryDocumentSnapshot> docs = [];

      // Simplified query - just get all tasks
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .get();
      docs = snapshot.docs;

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

        // Use Task.fromMap to ensure all fields are included
        final task = Task.fromMap(taskData, doc.id);
        debugPrint('TaskController: loaded task ${task.taskId} with category=${task.category}, tags=${task.tags}, dueDate=${task.dueDate}');
        pageTasks.add(task);
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
      // debugPrint("TaskController: Error in loadMoreTasksForAllUsers: $e");
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
      newTaskCount.value = 0;
      return;
    }
    
    newTaskCount.value = tasks.where((task) {
          return (task.assignedReporterId == userId || task.assignedCameramanId == userId || task.assignedDriverId == userId || task.assignedLibrarianId == userId) &&
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
        String photoUrl = _validateAvatarUrl(userDoc["photoUrl"]);
        userNameCache[uid] = fullName;
        userAvatarCache[uid] = photoUrl;
        return fullName;
      } else {
        return "User not found";
      }
    } catch (e) {
      // debugPrint("TaskController: Error fetching user $uid: $e");
      return "Error fetching user";
    }
  }

  // Assign a task to a reporter, cameraman, driver, and/or librarian, saving both the UID and Name for each.
  Future<void> assignTaskWithNames({
    required String taskId,
    String? reporterId,
    String? reporterName,
    String? cameramanId,
    String? cameramanName,
    String? driverId,
    String? driverName,
    String? librarianId,
    String? librarianName,
  }) async {
    try {
          final updateData = <String, dynamic>{};

      if (reporterId != null && reporterName != null) {
        updateData['assignedReporterId'] = reporterId;
        updateData['assignedReporterName'] = reporterName;
      } else {
        updateData['assignedReporterId'] = null;
        updateData['assignedReporterName'] = null;
      }

      if (cameramanId != null && cameramanName != null) {
        updateData['assignedCameramanId'] = cameramanId;
        updateData['assignedCameramanName'] = cameramanName;
      } else {
        updateData['assignedCameramanId'] = null;
        updateData['assignedCameramanName'] = null;
      }

      if (driverId != null && driverName != null) {
        updateData['assignedDriverId'] = driverId;
        updateData['assignedDriverName'] = driverName;
      } else {
        updateData['assignedDriverId'] = null;
        updateData['assignedDriverName'] = null;
      }

      if (librarianId != null && librarianName != null) {
        updateData['assignedLibrarianId'] = librarianId;
        updateData['assignedLibrarianName'] = librarianName;
      } else {
        updateData['assignedLibrarianId'] = null;
        updateData['assignedLibrarianName'] = null;
      }

      updateData['assignedAt'] = FieldValue.serverTimestamp();

      // Update the task document
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update(updateData);

      // Get task details for notification
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();

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

        // Send notifications and push notifications to all assigned users
        final List<String?> assignedUserIds = [reporterId, cameramanId, driverId, librarianId];
        for (final userId in assignedUserIds) {
          if (userId != null) {
            // In-app notification
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .add({
                  'type': 'task_assigned',
                  'taskId': taskId,
                  'title': taskTitle,
                  'message': 'Description: $taskDescription\nDue: $formattedDate',
                  'isRead': false,
                  'timestamp': FieldValue.serverTimestamp(),
                })
                .then((_) => debugPrint("✅ Notification sent to $userId"))
                .catchError((e) => debugPrint("❌ Notification error for $userId: $e"));
            // Push notification
            await sendTaskNotification(userId, taskTitle);
          }
        }
      }

      // Use a delayed call to avoid setState after dispose
      Future.delayed(const Duration(milliseconds: 100), () {
        calculateNewTaskCount();
      });
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

      // Check ALL tasks and their assignment fields
      for (int i = 0; i < docs.length; i++) {
        final doc = docs[i];
        final data = doc.data() as Map<String, dynamic>;

        // Check each condition
        bool createdByUser = data["createdBy"] == userId;
        bool assignedToUser = data["assignedTo"] == userId;
        bool assignedAsReporter = data["assignedReporterId"] == userId;
        bool assignedAsCameraman = data["assignedCameramanId"] == userId;
        bool assignedAsDriver = data["assignedDriverId"] == userId;
        bool assignedAsLibrarian = data["assignedLibrarianId"] == userId;

        if (createdByUser ||
            assignedToUser ||
            assignedAsReporter ||
            assignedAsCameraman ||
            assignedAsDriver ||
            assignedAsLibrarian) {
        }
      }

      // Count tasks created by user
      var createdTasks = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data["createdBy"] == userId;
      }).toList();

      totalTaskCreated.value = createdTasks.length;

      // Count tasks assigned to user
      var assignedTasks = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data["assignedTo"] == userId ||
            data["assignedReporterId"] == userId ||
            data["assignedCameramanId"] == userId ||
            data["assignedDriverId"] == userId ||
            data["assignedLibrarianId"] == userId;
      }).toList();

      taskAssigned.value = assignedTasks.length;

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
            // Use Task.fromMap for robust mapping
            final task = Task.fromMap(taskData, doc.id);
            debugPrint('fetchTasks: loaded task ${task.taskId} with category=${task.category}, tags=${task.tags}, dueDate=${task.dueDate}, priority=${task.priority}, assignedReporter=${task.assignedReporter}, assignedCameraman=${task.assignedCameraman}');
            updatedTasks.add(task);
          }
          
          // Role-based filtering
          if (userRole == "Reporter" || userRole == "Cameraman" || userRole == "Driver" || userRole == "Librarian") {
            updatedTasks = updatedTasks
                .where((task) =>
                    (task.createdById == userId) ||
                    (task.assignedTo == userId) ||
                    (task.assignedReporterId == userId) ||
                    (task.assignedCameramanId == userId) ||
                    (task.assignedDriverId == userId) ||
                    (task.assignedLibrarianId == userId))
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
    String? category,
    List<String>? tags,
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
        "creatorAvatar": _validateAvatarUrl(userAvatarCache[userId] ?? authController.profilePic.value),
        "assignedReporterId": null,
        "assignedReporterName": null,
        "assignedCameramanId": null,
        "assignedCameramanName": null,
        "status": "Pending",
        "priority": priority,
        "dueDate": dueDate != null ? dueDate.toIso8601String() : null,
        "comments": [],
        "timestamp": FieldValue.serverTimestamp(),
        "category": category,
        "tags": tags ?? [],
      };
      debugPrint('createTask: taskData = $taskData');
      debugPrint('createTask: calling _firebaseService.createTask');
      await _firebaseService.createTask(taskData);
      debugPrint('createTask: Firebase call complete');
      debugPrint('createTask: refreshing tasks');
      // Force a full refresh from Firestore after creation
      await loadInitialTasks();
      // Add debug print for all tasks
      for (final t in tasks) {
        debugPrint('TaskController: after create, taskId=${t.taskId}, category=${t.category}, tags=${t.tags}, dueDate=${t.dueDate}');
      }
      debugPrint('createTask: calculating new task count');
      debugPrint('createTask: showing success snackbar');
      _safeSnackbar("Success", "Task created successfully");
      debugPrint('createTask: finished successfully');
      return;
    } catch (e) {
      debugPrint('createTask: error: $e');
      _safeSnackbar("Error", "Failed to create task: $e");
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
        // Use Task.fromMap for consistent mapping
        final task = Task.fromMap(data, doc.id);
        debugPrint('getAllTasks: loaded task ${task.taskId} with category=${task.category}, tags=${task.tags}, dueDate=${task.dueDate}');
        return task;
      }));
    } catch (e) {
      errorMessage.value = 'Failed to get all tasks: $e';
      return [];
    }
  }

  /// Get tasks assigned to current user
  Future<List<Task>> getAssignedTasks() async {
    try {
      final userId = authController.auth.currentUser?.uid ?? "";
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedReporterId', isEqualTo: userId)
          .get();

      return await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        // Use Task.fromMap for consistent mapping
        final task = Task.fromMap(data, doc.id);
        debugPrint('getAssignedTasks: loaded task ${task.taskId} with category=${task.category}, tags=${task.tags}, dueDate=${task.dueDate}');
        return task;
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
        // Use Task.fromMap for consistent mapping
        final task = Task.fromMap(data, doc.id);
        debugPrint('getMyCreatedTasks: loaded task ${task.taskId} with category=${task.category}, tags=${task.tags}, dueDate=${task.dueDate}');
        return task;
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
        // Use Task.fromMap for consistent mapping
        final task = Task.fromMap(data, doc.id);
        debugPrint('getTaskById: loaded task ${task.taskId} with category=${task.category}, tags=${task.tags}, dueDate=${task.dueDate}');
        return task;
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

  /// Get the count of all tasks assigned to a user (assignedTo, assignedReporterId, assignedCameramanId, assignedDriverId, assignedLibrarianId)
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

  /// Stream of all non-completed tasks assigned to a user (assignedTo, assignedReporterId, assignedCameramanId, assignedDriverId, assignedLibrarianId)
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

  /// Stream of all tasks created by a user
  Stream<int> createdTasksCountStream(String userId) {
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Fetch all tasks relevant to the current user (created or assigned)
  Future<void> fetchRelevantTasksForUser() async {
    isLoading.value = true;
    try {
      final userId = authController.auth.currentUser?.uid;
      debugPrint('fetchRelevantTasksForUser: userId = $userId');
      if (userId == null) {
        debugPrint('fetchRelevantTasksForUser: No user ID, clearing tasks');
        tasks.clear();
        isLoading.value = false;
        return;
      }
      
      // First, let's get all tasks to debug the values
      final allTasksSnap = await FirebaseFirestore.instance
          .collection('tasks')
          .get();
      debugPrint('fetchRelevantTasksForUser: total tasks in collection = ${allTasksSnap.docs.length}');
      
      // Debug: Print assignment fields for all tasks
      for (var doc in allTasksSnap.docs) {
        final data = doc.data();
        debugPrint('fetchRelevantTasksForUser: task ${doc.id} - assignedTo=${data['assignedTo']}, assignedReporterId=${data['assignedReporterId']}, assignedCameramanId=${data['assignedCameramanId']}, assignedDriverId=${data['assignedDriverId']}, assignedLibrarianId=${data['assignedLibrarianId']}');
      }
      
      // Fetch tasks where user is creator
      final createdSnap = await FirebaseFirestore.instance
          .collection('tasks')
          .where('createdBy', isEqualTo: userId)
          .get();
      debugPrint('fetchRelevantTasksForUser: created tasks count = ${createdSnap.docs.length}');
      // Fetch tasks where user is assigned as reporter
      final reporterSnap = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedReporterId', isEqualTo: userId)
          .get();
      debugPrint('fetchRelevantTasksForUser: reporter tasks count = ${reporterSnap.docs.length}');
      // Fetch tasks where user is assigned as cameraman
      final cameramanSnap = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedCameramanId', isEqualTo: userId)
          .get();
      debugPrint('fetchRelevantTasksForUser: cameraman tasks count = ${cameramanSnap.docs.length}');
      // Fetch tasks where user is assignedTo (generic)
      final assignedToSnap = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .get();
      debugPrint('fetchRelevantTasksForUser: assignedTo tasks count = ${assignedToSnap.docs.length}');
      // Merge and deduplicate by taskId
      final allDocs = <String, Map<String, dynamic>>{};
      for (var doc in createdSnap.docs) {
        allDocs[doc.id] = doc.data() as Map<String, dynamic>;
        debugPrint('fetchRelevantTasksForUser: added created task ${doc.id}');
      }
      for (var doc in reporterSnap.docs) {
        allDocs[doc.id] = doc.data() as Map<String, dynamic>;
        debugPrint('fetchRelevantTasksForUser: added reporter task ${doc.id}');
      }
      for (var doc in cameramanSnap.docs) {
        allDocs[doc.id] = doc.data() as Map<String, dynamic>;
        debugPrint('fetchRelevantTasksForUser: added cameraman task ${doc.id}');
      }
      for (var doc in assignedToSnap.docs) {
        allDocs[doc.id] = doc.data() as Map<String, dynamic>;
        debugPrint('fetchRelevantTasksForUser: added assignedTo task ${doc.id}');
      }
      // Convert to Task objects
      final relevantTasks = allDocs.entries.map((e) => Task.fromMap(e.value, e.key)).toList();
      debugPrint('fetchRelevantTasksForUser: final merged tasks count = ${relevantTasks.length}');
      tasks.assignAll(relevantTasks);
      errorMessage.value = '';
    } catch (e) {
      debugPrint('fetchRelevantTasksForUser: error = $e');
      errorMessage.value = 'Failed to fetch relevant tasks: $e';
      tasks.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
