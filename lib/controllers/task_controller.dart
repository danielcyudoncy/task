// controllers/task_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // <-- make sure to import this!
import '../models/task_model.dart';
import '../controllers/auth_controller.dart';
import '../service/firebase_service.dart';

class TaskController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthController authController = Get.find<AuthController>();

  var tasks = <Task>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var totalTaskCreated = 0.obs;
  var taskAssigned = 0.obs;
  var newTaskCount = 0.obs; // Added newTaskCount variable

  final Map<String, String> userNameCache = {};
  final Map<String, String> taskTitleCache = {};

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
    await initializeCache();
    await preFetchUserNames();
    await loadInitialTasks();
    fetchTaskCounts();
    calculateNewTaskCount(); // Calculate new task count on init
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
            .where('title', isLessThanOrEqualTo: searchTerm + '\uf8ff')
            .orderBy('title')
            .limit(pageSize);

        final nameQuery = FirebaseFirestore.instance
            .collection('tasks')
            .where('createdByName', isGreaterThanOrEqualTo: searchTerm)
            .where('createdByName', isLessThanOrEqualTo: searchTerm + '\uf8ff')
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
      String userRole = authController.userRole.value;
      String userId = authController.auth.currentUser?.uid ?? "";

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

        final task = Task(
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
        );

        // Role-based filtering
        if (userRole == "Reporter") {
          if (task.assignedReporterId == userId || task.createdById == userId) {
            pageTasks.add(task);
          }
        } else if (userRole == "Cameraman") {
          if (task.assignedCameramanId == userId ||
              task.createdById == userId) {
            pageTasks.add(task);
          }
        } else {
          pageTasks.add(task);
        }
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
  String userId = authController.auth.currentUser?.uid ?? "";
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
      updateData['assignedAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update(updateData);

      // --- NEW: Send notification to assigned users ---
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();

      final String taskTitle =
          (taskDoc.data()?['title'] as String?) ?? 'A task';
      final String taskDescription =
          (taskDoc.data()?['description'] as String?) ?? '';
      // --- Handle dueDate which could be null or ISO string or Firestore Timestamp ---
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

      // Reporter notification
      if (reporterId != null) {
        await FirebaseFirestore.instance
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
        });
      }

      // Cameraman notification
      if (cameramanId != null) {
        await FirebaseFirestore.instance
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
        });
      }
      calculateNewTaskCount(); // Calculate new task count after assigning task
    } catch (e) {
      Get.snackbar("Assignment Error", "Failed to assign task: $e");
    }
  }

  // Fetch task counts using the new fields
  Future<void> fetchTaskCounts() async {
    try {
      String userId = authController.auth.currentUser!.uid;
      final queryCreated = await _firebaseService.getAllTasks().first;
      totalTaskCreated.value = queryCreated.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data["createdBy"] == userId;
      }).length;
      final queryAssigned = await _firebaseService.getAllTasks().first;
      taskAssigned.value = queryAssigned.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data["assignedReporterId"] == userId ||
            data["assignedCameramanId"] == userId;
      }).length;
      calculateNewTaskCount(); // Calculate new task count after fetching task counts
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch task counts: ${e.toString()}");
    }
  }

  // --- LEGACY STREAMING (for other screens if needed) ---
  void fetchTasks() {
    isLoading(true);
    try {
      Stream<QuerySnapshot> taskStream;
      String userRole = authController.userRole.value;
      taskStream = _firebaseService.getAllTasks();
      taskStream.listen((snapshot) async {
        List<Task> updatedTasks = [];
        String userId = authController.auth.currentUser!.uid;
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
        calculateNewTaskCount(); // Calculate new task count after fetching tasks
        saveCache();
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch tasks: ${e.toString()}");
    } finally {
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
    try {
      isLoading(true);
      String userId = authController.auth.currentUser!.uid;
      await _firebaseService.createTask({
        "title": title,
        "description": description,
        "createdBy": userId,
        "assignedReporterId": null,
        "assignedReporterName": null,
        "assignedCameramanId": null,
        "assignedCameramanName": null,
        "status": "Pending",
        "priority": priority,
        "dueDate": dueDate?.toIso8601String(),
        "comments": [],
        "timestamp": FieldValue.serverTimestamp(),
      });
      Get.snackbar("Success", "Task created successfully");
      calculateNewTaskCount(); // Calculate new task count after creating task
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
      Get.snackbar("Success", "Task updated successfully");
      calculateNewTaskCount(); // Calculate new task count after updating task
    } catch (e) {
      Get.snackbar("Error", "Failed to update task: ${e.toString()}");
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
      Get.snackbar("Success", "Task deleted successfully");
      calculateNewTaskCount(); // Calculate new task count after deleting task
    } catch (e) {
      Get.snackbar("Error", "Failed to delete task: ${e.toString()}");
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
      Get.snackbar("Success", "Task status updated");
      calculateNewTaskCount(); // Calculate new task count after updating task status
    } catch (e) {
      Get.snackbar("Error", "Failed to update task status: ${e.toString()}");
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
      Get.snackbar("Success", "Task assigned to Reporter successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to assign task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  Future<void> assignTaskToCameraman(String taskId, String cameramanId) async {
    try {
      isLoading(true);
      await _firebaseService.assignTask(
          taskId, cameramanId, "assignedCameramanId");
      Get.snackbar("Success", "Task assigned to Cameraman successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to assign task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }
}
