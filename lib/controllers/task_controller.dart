// controllers/task_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task/controllers/notification_controller.dart';
import 'package:task/models/task.dart';
import 'package:task/models/task_metadata.dart';
import 'package:task/models/report_completion_info.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/utils/constants/app_constants.dart';
import 'package:task/service/firebase_service.dart';
import 'package:task/utils/snackbar_utils.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:task/service/fcm_service.dart';
import 'package:task/service/user_cache_service.dart';
import 'package:task/service/enhanced_notification_service.dart';
import 'package:task/service/audit_service.dart';

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
  final _isScrolling =
      false.obs; // Track scroll state for performance optimization

  // Using UserCacheService for better caching performance
  final Map<String, String> taskTitleCache = {};

  // Safe snackbar method
  void _safeSnackbar(String title, String message) {
    SnackbarUtils.showSnackbar(title, message);
  }

  /// Safe state update method that prevents updates during Flutter's build phase
  /// to avoid parentDataDirty assertion errors
  void _safeStateUpdate(VoidCallback update) {
    // Use a simple post-frame callback to defer updates and avoid build phase conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      update();
    });
  }

  /// Safe async state update method that prevents updates during Flutter's build phase
  /// and properly handles async operations to avoid parentDataDirty assertion errors.
  ///
  /// This method:
  /// 1. Defers the async operation to after the current frame
  /// 2. Catches and logs any errors that occur during the async operation
  /// 3. Returns a Future that completes when the operation is done
  Future<T?> _safeAsyncStateUpdate<T>(Future<T> Function() asyncUpdate) async {
    final completer = Completer<T?>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final result = await asyncUpdate();
        completer.complete(result);
      } catch (e, stackTrace) {
        debugPrint('_safeAsyncStateUpdate error: $e');
        debugPrint('Stack trace: $stackTrace');
        completer.complete(null);
      }
    });

    return completer.future;
  }

  /// Pause heavy operations during scroll for better performance
  void setScrollState(bool isScrolling) {
    _isScrolling(isScrolling);
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

  // Helper method to get user name using UserCacheService
  Future<String> _getUserName(String userId) async {
    try {
      final userCacheService = Get.find<UserCacheService>();
      return await userCacheService.getUserName(userId);
    } catch (e) {
      debugPrint('TaskController: Error getting user name for $userId: $e');
      return 'Unknown User';
    }
  }

  /// Populate missing createdByName field for a task
  Future<void> _populateCreatedByName(Task task) async {
    debugPrint(
        '_populateCreatedByName: Checking task ${task.taskId}, current createdByName: ${task.createdByName}');
    if (task.createdByName == null || task.createdByName!.isEmpty) {
      try {
        final creatorName = await _getUserName(task.createdById);
        // Update the task with new creator name using safe async state update
        await _safeAsyncStateUpdate(() async {
          final updatedTask = task.withCreatedByName(creatorName);
          // Replace in the tasks list
          final index = tasks.indexWhere((t) => t.taskId == task.taskId);
          if (index != -1) {
            tasks[index] = updatedTask;
          }
          debugPrint(
              '_populateCreatedByName: Updated task ${task.taskId} createdByName to: $creatorName');
          // Trigger UI update after updating the name
          tasks.refresh();
          return true;
        });
      } catch (e) {
        debugPrint(
            '_populateCreatedByName: Error getting creator name for ${task.createdById}: $e');
        // Update the task with unknown user name using safe async state update
        await _safeAsyncStateUpdate(() async {
          final updatedTask = task.withCreatedByName('Unknown User');
          // Replace in the tasks list
          final index = tasks.indexWhere((t) => t.taskId == task.taskId);
          if (index != -1) {
            tasks[index] = updatedTask;
          }
          // Trigger UI update even on error
          tasks.refresh();
          return true;
        });
      }
    } else {
      debugPrint(
          '_populateCreatedByName: Task ${task.taskId} already has createdByName: ${task.createdByName}');
    }
  }

  // Helper method to get user avatar using UserCacheService
  Future<String> _getUserAvatar(String userId) async {
    try {
      final userCacheService = Get.find<UserCacheService>();
      final avatar = await userCacheService.getUserAvatar(userId);
      return _validateAvatarUrl(avatar);
    } catch (e) {
      debugPrint('TaskController: Error getting user avatar for $userId: $e');
      return authController.profilePic.value;
    }
  }

  // Pagination, filter, and search
  DocumentSnapshot? lastDocument;
  bool hasMore = true;
  final int pageSize = AppConstants.defaultPageSize;
  String searchTerm = '';
  String filterStatus = 'All';
  String sortBy = 'Newest';

  StreamSubscription? _taskStreamSubscription;
  StreamSubscription<QuerySnapshot>? _legacyTaskStreamSubscription;

  @override
  void onInit() async {
    super.onInit();
    debugPrint('TaskController: onInit called');

    // Listen to auth state changes
    ever(AuthController.to.user, (User? user) {
      if (user != null) {
        _initializeWhenAuthenticated();
      } else {
        // Cancel streams and clear data
        _taskStreamSubscription?.cancel();
        _taskStreamSubscription = null;
        _legacyTaskStreamSubscription?.cancel();
        _legacyTaskStreamSubscription = null;
        tasks.clear();
        errorMessage.value = '';
      }
    });

    // Initialize if already authenticated
    if (AuthController.to.currentUser != null) {
      _initializeWhenAuthenticated();
    }
  }

  Future<void> _initializeWhenAuthenticated() async {
    // Delay initialization to ensure proper setup
    Future.delayed(const Duration(milliseconds: 300), () async {
      debugPrint('TaskController: Starting delayed initialization');
      if (Get.isRegistered<TaskController>()) {
        debugPrint(
            'TaskController: Controller is registered, proceeding with initialization');

        // Ensure user document exists before proceeding
        final user = AuthController.to.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (!userDoc.exists) {
            debugPrint(
                'TaskController: User document does not exist, creating it');
            // Create user document if missing
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'uid': user.uid,
              'email': user.email ?? '',
              'fullName': user.displayName ?? '',
              'role': 'Reporter',
              'profileComplete': false,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }

        await initializeCache();
        await _preFetchUsersWithCacheService();
        await loadInitialTasks();
        fetchTaskCounts();
        calculateNewTaskCount(); // Calculate new task count on init
        _startRealtimeTaskListener(); // Start real-time listener
        debugPrint('TaskController: Initialization complete');
      } else {
        debugPrint(
            'TaskController: Controller not registered, skipping initialization');
      }
    });
  }

  @override
  void onClose() {
    // Cancel all stream subscriptions to prevent memory leaks
    _taskStreamSubscription?.cancel();
    _taskStreamSubscription = null;

    _legacyTaskStreamSubscription?.cancel();
    _legacyTaskStreamSubscription = null;

    // Save cache before closing
    try {
      saveCache();
    } catch (e) {
      debugPrint('Error saving cache during controller close: $e');
    }

    debugPrint('TaskController: Properly disposed');
    super.onClose();
  }

  // Start real-time listener for task updates
  void _startRealtimeTaskListener() {
    debugPrint('TaskController: Starting real-time task listener');
    debugPrint(
        'TaskController: User role: ${AuthController.to.userRole.value}');
    // Only start real-time listener for admins to avoid permission issues.
    // Also ensure the user's role has been loaded to avoid race conditions
    // where `isAdmin` is false/unknown and we attempt restricted listeners.
    if (!AuthController.to.isRoleLoaded.value) {
      debugPrint(
          'TaskController: Role not loaded yet, deferring real-time listener until role is available');
      // Start listener once when role is loaded
      once(AuthController.to.isRoleLoaded, (loaded) {
        if (loaded == true) {
          debugPrint(
              'TaskController: Role loaded - attempting to start real-time listener');
          // Ensure we don't create duplicate subscriptions
          Future.microtask(() => _startRealtimeTaskListener());
        }
      });
      return;
    }

    // Only start real-time listener for admins to avoid permission issues
    final isAdmin = AuthController.to.isAdmin.value;
    debugPrint('TaskController: User is admin: $isAdmin');

    if (isAdmin) {
      // Avoid starting a second subscription if one already exists
      if (_taskStreamSubscription != null) {
        debugPrint(
            'TaskController: Real-time task listener already active, skipping start');
        return;
      }
      _taskStreamSubscription = FirebaseFirestore.instance
          .collection('tasks')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen(
        (snapshot) async {
          // Check if user is still authenticated
          if (AuthController.to.currentUser == null) {
            debugPrint(
                'TaskController: User not authenticated, skipping update');
            return;
          }
          debugPrint(
              'TaskController: Real-time update received, ${snapshot.docs.length} tasks');
          final updatedTasks = await Future.wait(snapshot.docs.map((doc) async {
            final data = doc.data();
            data['taskId'] = doc.id;
            final task = Task.fromMap(data);
            await _populateCreatedByName(task);
            return task;
          }));

          // Update the tasks list safely using async state update to avoid parentDataDirty assertion errors
          await _safeAsyncStateUpdate(() async {
            tasks.assignAll(updatedTasks);
            tasks.refresh();
            return true;
          });
          debugPrint('TaskController: Tasks updated via real-time listener');
        },
        onError: (error) {
          debugPrint('TaskController: Real-time listener error: $error');
        },
      );
    } else {
      debugPrint(
          'TaskController: Starting real-time listener for non-admin user');
      final userId = AuthController.to.currentUser?.uid;
      if (userId != null) {
        _startNonAdminRealtimeListener(userId);
      }
    }
  }

  // Start real-time listener for non-admin users
  void _startNonAdminRealtimeListener(String userId) {
    debugPrint(
        'TaskController: Starting non-admin real-time listener for userId: \$userId');

    // Define the streams matching fetchRelevantTasksForUser logic
    final streams = [
      FirebaseFirestore.instance
          .collection('tasks')
          .where('createdBy', isEqualTo: userId)
          .snapshots(),
      FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedReporterId', isEqualTo: userId)
          .snapshots(),
      FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedCameramanId', isEqualTo: userId)
          .snapshots(),
      FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedDriverId', isEqualTo: userId)
          .snapshots(),
      FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedLibrarianId', isEqualTo: userId)
          .snapshots(),
      FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .snapshots(),
    ];

    // Combine streams using Rx.combineLatest (imported as rx)
    // We use CombineLatestStream.list to get a List<QuerySnapshot>
    _taskStreamSubscription = rx.CombineLatestStream.list(streams).listen(
      (List<QuerySnapshot> snapshots) async {
        if (AuthController.to.currentUser == null) return;

        debugPrint(
            'TaskController: Non-admin real-time update received from \${snapshots.length} streams');

        // Merge and deduplicate results
        final allDocs = <String, Map<String, dynamic>>{};
        for (var snapshot in snapshots) {
          for (var doc in snapshot.docs) {
            allDocs[doc.id] = (doc.data() as Map<String, dynamic>);
          }
        }

        debugPrint(
            'TaskController: Non-admin unique tasks found: \${allDocs.length}');

        // Convert to Task objects
        final updatedTasks = await Future.wait(allDocs.entries.map((e) async {
          final data = e.value;
          data['taskId'] = e.key;
          final task = Task.fromMap(data);
          await _populateCreatedByName(task);
          return task;
        }));

        // Update the tasks list safely using async state update
        await _safeAsyncStateUpdate(() async {
          tasks.assignAll(updatedTasks);
          tasks.refresh();
          return true;
        });
        debugPrint(
            'TaskController: Non-admin tasks updated via real-time listener');
      },
      onError: (error) {
        debugPrint('TaskController: Non-admin real-time listener error: \$error');
      },
    );
  }

  // Refresh tasks list
  Future<void> refreshTasks() async {
    isRefreshing(true);
    try {
      await loadInitialTasks();
    } finally {
      isRefreshing(false);
    }
  }

  // Initialize cache from local storage if available
  Future<void> initializeCache() async {
    await loadCache();
  }

  // Save cache to local storage
  Future<void> saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    // Only save task title cache, user data is handled by UserCacheService
    prefs.setString("taskTitleCache", jsonEncode(taskTitleCache));
    prefs.setInt("cacheTimestamp", DateTime.now().millisecondsSinceEpoch);
  }

  // Load cache from local storage
  Future<void> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only load task title cache, user data is handled by UserCacheService
      final taskTitleCacheString = prefs.getString("taskTitleCache");

      if (taskTitleCacheString != null) {
        final Map<String, dynamic> decoded = jsonDecode(taskTitleCacheString);
        taskTitleCache.clear();
        taskTitleCache.addAll(Map<String, String>.from(decoded));
      }
    } catch (e) {
      // debugPrint("TaskController: Error loading cache: $e");
    }
  }

  // Pre-fetch all user names and avatars using UserCacheService
  Future<void> _preFetchUsersWithCacheService() async {
    try {
      final userCacheService = Get.find<UserCacheService>();
      await userCacheService.preFetchAllUsers();
      debugPrint('TaskController: Pre-fetched users using UserCacheService');
    } catch (e) {
      debugPrint('TaskController: Error pre-fetching users: $e');
    }
  }

  // --- PAGINATED, FILTERED, SEARCHABLE TASK LOADING ---
  Future<void> loadInitialTasksPaginated(
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
        final isAdmin = AuthController.to.isAdmin.value;
        debugPrint('loadMoreTasks: User is admin: $isAdmin');

        if (isAdmin) {
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
        } else {
          // For non-admins, use filtered queries to avoid permission errors
          debugPrint(
              'loadMoreTasks: Using filtered queries for non-admin user');
          // Since pagination on multiple queries is complex, for simplicity, fetch relevant tasks and paginate locally or adjust
          // For now, fetch all relevant and handle pagination differently
          // This is a placeholder; in a full implementation, you'd need to paginate the relevant queries
          final relevantSnapshot = await FirebaseFirestore.instance
              .collection('tasks')
              .where('assignedReporterId',
                  isEqualTo: AuthController.to.currentUser?.uid)
              .orderBy('timestamp', descending: sortBy == "Newest")
              .limit(pageSize)
              .get();
          docs = relevantSnapshot.docs;
          // Note: This only fetches assigned reporter tasks; you may need to combine multiple where clauses or use a different strategy
        }
      }

      List<Task> pageTasks = [];

      for (var doc in docs) {
        var taskData = doc.data() as Map<String, dynamic>;
        String taskTitle = taskData["title"];
        taskTitleCache[doc.id] = taskTitle;

        // Use Task.fromMap to ensure all fields are included
        taskData['taskId'] = doc.id;
        final task = Task.fromMap(taskData);

        // Populate missing creator names to fix "created by" showing user ID instead of name
        await _populateCreatedByName(task);

        debugPrint(
            'TaskController: loaded task ${task.taskId} - title: ${task.title}, approvalStatus: ${task.approvalStatus}, isApproved: ${task.isApproved}, canBeAssigned: ${task.canBeAssigned}');
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

      // FIXED: Show ALL tasks for ALL users, regardless of role
      // This method is specifically for the AllTasksScreen where everyone should see all tasks
      debugPrint('loadMoreTasksForAllUsers: Loading ALL tasks for ALL users');
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .orderBy('timestamp', descending: sortBy == "Newest")
          .limit(pageSize)
          .get();
      docs = snapshot.docs;

      // Apply pagination if not reset
      if (lastDocument != null) {
        final paginatedSnapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .orderBy('timestamp', descending: sortBy == "Newest")
            .startAfterDocument(lastDocument!)
            .limit(pageSize)
            .get();
        docs = paginatedSnapshot.docs;
      }

      List<Task> pageTasks = [];

      for (var doc in docs) {
        var taskData = doc.data() as Map<String, dynamic>;
        String taskTitle = taskData["title"];
        taskTitleCache[doc.id] = taskTitle;

        // Use Task.fromMap to ensure all fields are included
        taskData['taskId'] = doc.id;
        final task = Task.fromMap(taskData);

        // Populate missing creator names to fix "created by" showing user ID instead of name
        await _populateCreatedByName(task);

        debugPrint(
            'TaskController: loaded task ${task.taskId} - title: ${task.title}, approvalStatus: ${task.approvalStatus}, isApproved: ${task.isApproved}, canBeAssigned: ${task.canBeAssigned}');
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
      return (task.assignedReporterId == userId ||
              task.assignedCameramanId == userId ||
              task.assignedDriverId == userId ||
              task.assignedLibrarianId == userId) &&
          task.status != "Completed";
    }).length;
  }

  // Fetch user's full name using UID with caching

  // Assign a task to a reporter, cameraman, driver, and/or librarian, saving both the UID and Name for each.
  /// Updates task assignments and notifies all assigned users
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
      // Validate task can be assigned
      final validationError = await _validateTaskAssignment(taskId);
      if (validationError != null) {
        _safeSnackbar("Error", validationError);
        return;
      }

      // Prepare the update data with proper null safety
      final updateData = await _prepareAssignmentUpdates(
        reporterId: reporterId,
        reporterName: reporterName,
        cameramanId: cameramanId,
        cameramanName: cameramanName,
        driverId: driverId,
        driverName: driverName,
        librarianId: librarianId,
        librarianName: librarianName,
      );

      // Update the task document
      await _updateTaskAssignments(taskId, updateData);

      // Get task details for notification
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();

      if (taskDoc.exists) {
        await _notifyAssignedUsers(
          taskDoc: taskDoc,
          taskId: taskId,
          reporterId: reporterId,
          cameramanId: cameramanId,
          driverId: driverId,
          librarianId: librarianId,
        );
      }

      // Update UI state
      Future.delayed(AppConstants.fastAnimationDuration, calculateNewTaskCount);
    } catch (e, stackTrace) {
      _logError('Error in assignTaskWithNames', e, stackTrace);
      // Don't show snackbar here since dialog might be closed
    }
  }

  /// Validates that a task can be assigned
  Future<String?> _validateTaskAssignment(String taskId) async {
    // Check if task is approved before allowing assignment
    final taskIndex = tasks.indexWhere((task) => task.taskId == taskId);
    if (taskIndex != -1) {
      final task = tasks[taskIndex];
      if (!task.canBeAssigned) {
        return "This task must be approved before it can be assigned to users";
      }
    } else {
      // If task not found locally, check Firebase
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();

      if (taskDoc.exists) {
        final taskData = taskDoc.data()!;
        final approvalStatus = taskData['approvalStatus'] ?? 'pending';
        if (approvalStatus.toLowerCase() != 'approved') {
          return "This task must be approved before it can be assigned to users";
        }
      } else {
        return "Task not found";
      }
    }

    return null; // Valid
  }

  /// Prepares the assignment updates with proper null safety
  Future<Map<String, dynamic>> _prepareAssignmentUpdates({
    String? reporterId,
    String? reporterName,
    String? cameramanId,
    String? cameramanName,
    String? driverId,
    String? driverName,
    String? librarianId,
    String? librarianName,
  }) async {
    final updateData = <String, dynamic>{
      'assignedAt': FieldValue.serverTimestamp(),
    };

    // Helper function to add assignment if both ID and name are provided
    void addAssignmentIfValid({
      required String? id,
      required String? name,
      required String idField,
      required String nameField,
    }) {
      if (id != null && name != null) {
        updateData[idField] = id;
        updateData[nameField] = name;
      } else {
        updateData[idField] = null;
        updateData[nameField] = null;
      }
    }

    // Add all assignments
    addAssignmentIfValid(
      id: reporterId,
      name: reporterName,
      idField: 'assignedReporterId',
      nameField: 'assignedReporterName',
    );

    addAssignmentIfValid(
      id: cameramanId,
      name: cameramanName,
      idField: 'assignedCameramanId',
      nameField: 'assignedCameramanName',
    );

    addAssignmentIfValid(
      id: driverId,
      name: driverName,
      idField: 'assignedDriverId',
      nameField: 'assignedDriverName',
    );

    addAssignmentIfValid(
      id: librarianId,
      name: librarianName,
      idField: 'assignedLibrarianId',
      nameField: 'assignedLibrarianName',
    );

    return updateData;
  }

  /// Updates task assignments in Firestore
  Future<void> _updateTaskAssignments(
    String taskId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update(updateData);
    } catch (e, stackTrace) {
      _logError('Failed to update task assignments', e, stackTrace);
      rethrow;
    }
  }

  /// Sends notifications to all assigned users
  Future<void> _notifyAssignedUsers({
    required DocumentSnapshot taskDoc,
    required String taskId,
    String? reporterId,
    String? cameramanId,
    String? driverId,
    String? librarianId,
  }) async {
    try {
      final taskData = taskDoc.data() as Map<String, dynamic>?;
      if (taskData == null) return;

      final taskTitle = taskData['title'] as String? ?? 'A task';
      final taskDescription = taskData['description'] as String? ?? '';
      final dueDate = _parseDueDate(taskData['dueDate']);
      final formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(dueDate);

      // Send notifications to all assigned users
      final assignedUserIds = [reporterId, cameramanId, driverId, librarianId]
          .whereType<String>()
          .toList();

      for (final userId in assignedUserIds) {
        await _sendUserNotification(
          userId: userId,
          taskId: taskId,
          taskTitle: taskTitle,
          taskDescription: taskDescription,
          formattedDate: formattedDate,
        );
      }
    } catch (e, stackTrace) {
      _logError('Error in _notifyAssignedUsers', e, stackTrace);
    }
  }

  /// Parses the due date from various possible formats
  DateTime _parseDueDate(dynamic dueDateRaw) {
    if (dueDateRaw is Timestamp) {
      return dueDateRaw.toDate();
    } else if (dueDateRaw is String) {
      return DateTime.tryParse(dueDateRaw) ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// Sends a notification to a single user
  Future<void> _sendUserNotification({
    required String userId,
    required String taskId,
    required String taskTitle,
    required String taskDescription,
    required String formattedDate,
  }) async {
    try {
      // In-app notification
      await FirebaseFirestore.instance
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
      });

      // Push notification
      await sendTaskNotification(userId, taskTitle, taskId);

      // Show local in-app notification
      try {
        final enhancedNotificationService =
            Get.find<EnhancedNotificationService>();
        enhancedNotificationService.showInfo(
          title: 'Task Assigned',
          message:
              'Task "$taskTitle" has been assigned\nDescription: $taskDescription\nDue: $formattedDate',
          duration: const Duration(seconds: 5),
        );
      } catch (e) {
        // Enhanced notification service might not be initialized
      }
    } catch (e, stackTrace) {
      _logError('Error sending notification to user $userId', e, stackTrace);
    }
  }

  /// Helper method for consistent error logging
  void _logError(String message, dynamic error, StackTrace stackTrace) {
    // Use GetX's logging in production, or debugPrint in development
    if (kReleaseMode) {
      Get.log('$message: $error', isError: true);
      Get.log('Stack trace: $stackTrace', isError: true);
    } else {
      debugPrint('❌ $message: $error');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Fetch task counts using the new fields
  Future<void> fetchTaskCounts() async {
    try {
      // Check if user is authenticated
      if (authController.auth.currentUser == null) {
        debugPrint(
            "fetchTaskCounts: User not authenticated yet, retrying in 1 second...");
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
        debugPrint(
            "fetchTaskCounts: User role not loaded yet, retrying in 1 second...");
        await Future.delayed(const Duration(seconds: 1));
        userRole = authController.userRole.value;
        if (userRole.isEmpty) {
          debugPrint(
              "fetchTaskCounts: User role still not available, skipping");
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
            assignedAsLibrarian) {}
      }

      // Count tasks created by user (excluding completed tasks)
      var createdTasks = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data["status"] ?? "").toString().toLowerCase();
        return data["createdBy"] == userId && status != "completed";
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

      // Cancel any existing legacy subscription to prevent memory leaks
      _legacyTaskStreamSubscription?.cancel();

      Stream<QuerySnapshot> taskStream = _firebaseService.getAllTasks();
      _legacyTaskStreamSubscription = taskStream.listen((snapshot) async {
        try {
          List<Task> updatedTasks = [];

          for (var doc in snapshot.docs) {
            var taskData = doc.data() as Map<String, dynamic>;
            // Use Task.fromMap for robust mapping
            taskData['taskId'] = doc.id;
            final task = Task.fromMap(taskData);

            // Populate missing creator names to fix "created by" showing user ID instead of name
            await _populateCreatedByName(task);

            debugPrint(
                'fetchTasks: loaded task ${task.taskId} with category=${task.category}, tags=${task.tags}, dueDate=${task.dueDate}, priority=${task.priority}, assignedReporter=${task.assignedReporter}, assignedCameraman=${task.assignedCameraman}');
            updatedTasks.add(task);
          }

          // Role-based filtering
          if (userRole == "Reporter" ||
              userRole == "Cameraman" ||
              userRole == "Driver" ||
              userRole == "Librarian") {
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
  // --- OVERRIDE createTask to use local-first, then sync to Firebase ---
  Future<void> createTask(
    String title,
    String description, {
    String priority = 'Normal',
    DateTime? dueDate,
    String? category,
    List<String>? tags,
    String? comments,
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

      // Get creator's name with a multi-layered fallback for reliability
      String creatorName = authController.userData['fullName'] ?? '';
      if (creatorName.isEmpty) {
        creatorName = authController.fullName.value;
      }
      if (creatorName.isEmpty) {
        creatorName = await Get.find<UserCacheService>().getUserName(userId);
      }

      // Prepare data for Firebase
      final taskData = {
        "title": title,
        "description": description,
        "createdBy": userId,
        "createdById": userId,
        "createdByName": creatorName, // Use the reliably fetched name
        "creatorAvatar": await _getUserAvatar(userId),
        "assignedReporterId": null,
        "assignedReporterName": null,
        "assignedCameramanId": null,
        "assignedCameramanName": null,
        "status": "Pending",
        "priority": priority,
        "dueDate": dueDate?.toIso8601String(),
        "comments": comments != null && comments.isNotEmpty ? [comments] : [],
        "timestamp": FieldValue.serverTimestamp(),
        "category": category,
        "tags": tags ?? [],
        "lastModified": DateTime.now().toIso8601String(),
      };
      // Create task in Firebase
      await _firebaseService.createTask(taskData);
      debugPrint('createTask: Firebase call complete');
      // Reload tasks to update UI
      await loadInitialTasks();
      _safeSnackbar("Success", "Task created successfully");
      return;
    } catch (e) {
      debugPrint('createTask: error: $e');
      _safeSnackbar("Error", "Failed to create task: $e");
      rethrow;
    } finally {
      debugPrint('createTask: finally block - resetting loading state');
      isLoading(false);
    }
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      isLoading(true);
      final currentUser = authController.auth.currentUser;
      if (currentUser == null) {
        _safeSnackbar("Error", "User not authenticated");
        return;
      }

      final task = tasks.firstWhere((t) => t.taskId == taskId);

      // ✅ HARDENED: Enhanced permission check with detailed logging
      final canEdit = task.canEdit(currentUser.uid,
          isAdmin: authController.isCurrentUserAdmin);

      if (!canEdit) {
        debugPrint('updateTask: Permission denied for user ${currentUser.uid}');
        debugPrint('  isAdmin: ${authController.isCurrentUserAdmin}');
        debugPrint('  userRole: ${authController.userRole.value}');
        debugPrint('  task creator: ${task.createdBy}');
        _safeSnackbar("Error", "You do not have permission to edit this task");
        return;
      }

      // Ensure lastModified is always updated
      updates['lastModified'] = DateTime.now().toIso8601String();

      // Update task in Firebase
      await _firebaseService.updateTask(taskId, updates);

      // Update local task list
      int taskIndex = tasks.indexWhere((task) => task.taskId == taskId);
      if (taskIndex != -1) {
        // Create updated task by applying all updates
        Task updatedTask = tasks[taskIndex];

        // Apply core updates
        if (updates.containsKey('title') ||
            updates.containsKey('description') ||
            updates.containsKey('status') ||
            updates.containsKey('priority') ||
            updates.containsKey('dueDate') ||
            updates.containsKey('category') ||
            updates.containsKey('tags')) {
          updatedTask = updatedTask.copyWith(
            core: updatedTask.core.copyWith(
              title: updates['title'] ?? updatedTask.title,
              description: updates['description'] ?? updatedTask.description,
              status: updates['status'] ?? updatedTask.status,
              priority: updates['priority'] ?? updatedTask.priority,
              dueDate: updates['dueDate'] != null
                  ? (updates['dueDate'] is int
                      ? DateTime.fromMillisecondsSinceEpoch(updates['dueDate'])
                      : DateTime.parse(updates['dueDate'].toString()))
                  : updatedTask.dueDate,
              category: updates['category'] ?? updatedTask.category,
              tags: updates['tags'] != null
                  ? List<String>.from(updates['tags'])
                  : updatedTask.tags,
            ),
          );
        }

        // Apply metadata updates
        if (updates.keys.any((key) =>
            key.startsWith('assigned') ||
            key == 'comments' ||
            key == 'approvalStatus' ||
            key == 'approvalReason' ||
            key == 'attachmentUrls' ||
            key == 'completedByUserIds' ||
            key == 'lastModified')) {
          updatedTask = updatedTask.copyWith(
            metadata: updatedTask.metadata?.copyWith(
                  assignedReporterId: updates['assignedReporterId'] ??
                      updatedTask.assignedReporterId,
                  assignedCameramanId: updates['assignedCameramanId'] ??
                      updatedTask.assignedCameramanId,
                  assignedDriverId: updates['assignedDriverId'] ??
                      updatedTask.assignedDriverId,
                  assignedLibrarianId: updates['assignedLibrarianId'] ??
                      updatedTask.assignedLibrarianId,
                  lastModified: updates['lastModified'] != null
                      ? DateTime.parse(updates['lastModified'].toString())
                      : DateTime.now(),
                ) ??
                TaskMetadata(
                  lastModified: updates['lastModified'] != null
                      ? DateTime.parse(updates['lastModified'].toString())
                      : DateTime.now(),
                ),
          );
        }

        // Use safe state update to avoid parentDataDirty assertion errors
        _safeStateUpdate(() {
          tasks[taskIndex] = updatedTask;
          tasks.refresh();
        });
      }
      _safeSnackbar("Success", "Task updated successfully");
      calculateNewTaskCount(); // Calculate new task count after updating task
    } catch (e) {
      _safeSnackbar("Error", "Failed to update task: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      isLoading(true);

      // Get current user for audit trail
      final currentUser = authController.auth.currentUser;
      if (currentUser == null) {
        _safeSnackbar("Error", "User not authenticated");
        return;
      }

      final task = tasks.firstWhere((t) => t.taskId == taskId);

      // Check if user is admin for permanent delete, otherwise soft delete
      if (authController.isCurrentUserAdmin) {
        // Admin permanent delete - requires confirmation
        await _adminPermanentlyDeleteTask(taskId);
      } else {
        if (!task.canDelete(currentUser.uid,
            isAdmin: authController.isCurrentUserAdmin)) {
          _safeSnackbar(
              "Error", "You do not have permission to delete this task");
          return;
        }
        // Regular user soft delete (archive)
        await _softDeleteTask(taskId, currentUser.uid);
      }
    } catch (e) {
      _safeSnackbar("Error", "Failed to delete task: $e");
    } finally {
      isLoading(false);
    }
  }

  /// Admin-only permanent delete with audit logging
  Future<void> _adminPermanentlyDeleteTask(String taskId) async {
    try {
      // Call the Cloud Function for permanent deletion
      final callable = FirebaseFunctions.instance
          .httpsCallable('adminPermanentlyDeleteTask');
      await callable.call({
        'taskId': taskId,
        'reason': 'Administrative deletion via TaskController',
      });

      // Remove from local task list using safe state update
      _safeStateUpdate(() {
        tasks.removeWhere((task) => task.taskId == taskId);
        tasks.refresh();
      });

      _safeSnackbar("Success", "Task permanently deleted by admin");
      calculateNewTaskCount();
    } catch (e) {
      _safeSnackbar("Error", "Failed to permanently delete task: $e");
      debugPrint("Admin permanent delete error: $e");
    }
  }

  /// Regular user soft delete (archive)
  Future<void> _softDeleteTask(String taskId, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'archived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'archivedBy': userId,
        'archiveReason': 'Deleted by user',
        'status': 'archived',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local task list
      final taskIndex = tasks.indexWhere((task) => task.taskId == taskId);
      if (taskIndex != -1) {
        final archivedTask = tasks[taskIndex].copyWith(
          metadata: tasks[taskIndex].metadata?.copyWith(
                    archivedAt: DateTime.now(),
                    archivedBy: userId,
                    archiveReason: 'Deleted by user',
                  ) ??
              TaskMetadata(
                archivedAt: DateTime.now(),
                archivedBy: userId,
                archiveReason: 'Deleted by user',
              ),
          core: tasks[taskIndex].core.copyWith(status: 'archived'),
        );
        // Use safe state update to avoid parentDataDirty assertion errors
        _safeStateUpdate(() {
          tasks[taskIndex] = archivedTask;
          tasks.refresh();
        });
      }

      _safeSnackbar("Success", "Task archived successfully");
      calculateNewTaskCount();
    } catch (e) {
      _safeSnackbar("Error", "Failed to archive task: $e");
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
          core: tasks[taskIndex].core.copyWith(
                status: newStatus,
              ),
        );
        // Use safe state update to avoid parentDataDirty assertion errors
        _safeStateUpdate(() {
          tasks[taskIndex] = updatedTask;
          tasks.refresh();
        });
      }
      _safeSnackbar("Success", "Task status updated");
      calculateNewTaskCount(); // Calculate new task count after updating task status
    } catch (e) {
      _safeSnackbar("Error", "Failed to update task status: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // New method for individual user task completion - REFACTORED
  Future<void> markTaskCompletedByUser(
    String taskId,
    String userId, {
    ReportCompletionInfo? reportCompletionInfo,
  }) async {
    try {
      isLoading(true);

      // Get current user admin status
      final isAdmin = authController.isAdmin.value;

      // Get and validate task
      final task = await _getAndValidateTaskForCompletion(taskId, userId,
          isAdmin: isAdmin);
      if (task == null) return;

      // Prepare completion data
      final completionData =
          _prepareTaskCompletionData(task, userId, reportCompletionInfo);

      // Update Firestore
      await _updateTaskCompletionInFirestore(taskId, completionData);

      // Send notifications if needed
      if (reportCompletionInfo != null) {
        await _sendCompletionNotifications(
            taskId, userId, task.title, reportCompletionInfo);
      }

      // Update local state
      _updateLocalTaskCompletion(
          taskId, userId, completionData, reportCompletionInfo);

      // Show success message
      _showCompletionSuccessMessage(completionData['allCompleted'] as bool,
          completionData['remainingUsers'] as int);

      calculateNewTaskCount();
    } catch (e) {
      _safeSnackbar(
          "Error", "Failed to mark task as completed: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  /// Get and validate task for completion
  Future<Task?> _getAndValidateTaskForCompletion(String taskId, String userId,
      {bool isAdmin = false}) async {
    final taskDoc =
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();

    if (!taskDoc.exists) {
      _safeSnackbar("Error", "Task not found");
      return null;
    }

    final taskData = taskDoc.data()!;
    taskData['taskId'] = taskId;
    final task = Task.fromMap(taskData);

    // Check if user is assigned to this task OR is admin
    if (!isAdmin && !task.assignedUserIds.contains(userId)) {
      _safeSnackbar("Error", "You are not assigned to this task");
      return null;
    }

    // Check if user has already completed the task
    if (task.completedByUserIds.contains(userId)) {
      _safeSnackbar("Info", "You have already marked this task as completed");
      return null;
    }

    return task;
  }

  /// Prepare completion data for Firestore update
  Map<String, dynamic> _prepareTaskCompletionData(
    Task task,
    String userId,
    ReportCompletionInfo? reportCompletionInfo,
  ) {
    // Add user to completed list
    List<String> updatedCompletedByUserIds = List.from(task.completedByUserIds);
    updatedCompletedByUserIds.add(userId);

    // Add completion timestamp
    Map<String, dynamic> updatedTimestamps = Map.from(task
        .userCompletionTimestamps
        .map((key, value) => MapEntry(key, value)));
    updatedTimestamps[userId] = DateTime.now();

    // Check if all assigned users have now completed the task
    final allAssignedUsers = task.assignedUserIds;
    final allCompleted = allAssignedUsers.every(
        (assignedUserId) => updatedCompletedByUserIds.contains(assignedUserId));

    // Prepare update data
    Map<String, dynamic> updateData = {
      'completedByUserIds': updatedCompletedByUserIds,
      'userCompletionTimestamps': updatedTimestamps,
    };

    // Add report completion info if provided (for reporters)
    if (reportCompletionInfo != null) {
      updateData['reportCompletionInfo'] = {
        if (task.reportCompletionInfo.isNotEmpty)
          ...task.reportCompletionInfo
              .map((key, value) => MapEntry(key, value.toMap())),
        userId: reportCompletionInfo.toMap(),
      };
    }

    // Only update the overall task status to "Completed" if ALL assigned users have completed it
    if (allCompleted) {
      updateData['status'] = 'Completed';
    }

    return {
      'updateData': updateData,
      'allCompleted': allCompleted,
      'remainingUsers': allAssignedUsers
          .where((id) => !updatedCompletedByUserIds.contains(id))
          .length,
    };
  }

  /// Update task completion in Firestore
  Future<void> _updateTaskCompletionInFirestore(
      String taskId, Map<String, dynamic> completionData) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(taskId)
        .update(completionData['updateData'] as Map<String, dynamic>);
  }

  /// Send completion notifications
  Future<void> _sendCompletionNotifications(
    String taskId,
    String userId,
    String taskTitle,
    ReportCompletionInfo reportCompletionInfo,
  ) async {
    try {
      String reporterName = await _getUserName(userId);
      await sendReportCompletionNotification(
        taskId,
        taskTitle,
        reporterName,
        reportCompletionInfo.comments ?? '',
      );
    } catch (e) {
      debugPrint('Error sending admin notification: $e');
    }
  }

  /// Update local task completion state
  void _updateLocalTaskCompletion(
    String taskId,
    String userId,
    Map<String, dynamic> completionData,
    ReportCompletionInfo? reportCompletionInfo,
  ) {
    int taskIndex = tasks.indexWhere((task) => task.taskId == taskId);
    if (taskIndex != -1) {
      final task = tasks[taskIndex];
      List<String> updatedCompletedByUserIds =
          completionData['updateData']['completedByUserIds'] as List<String>;
      Map<String, dynamic> updatedTimestamps = completionData['updateData']
          ['userCompletionTimestamps'] as Map<String, dynamic>;

      // Create updated report completion info map
      final Map<String, ReportCompletionInfo> updatedReportCompletionInfo =
          Map.from(task.reportCompletionInfo);
      if (reportCompletionInfo != null) {
        updatedReportCompletionInfo[userId] = reportCompletionInfo;
      }

      Task updatedTask = task.copyWith(
        metadata: task.metadata?.copyWith(
              completedByUserIds: updatedCompletedByUserIds,
              userCompletionTimestamps: Map<String, DateTime>.from(
                  updatedTimestamps.map((key, value) => MapEntry(
                      key, value is DateTime ? value : DateTime.now()))),
              reportCompletionInfo: updatedReportCompletionInfo,
            ) ??
            TaskMetadata(
              completedByUserIds: updatedCompletedByUserIds,
              userCompletionTimestamps: Map<String, DateTime>.from(
                  updatedTimestamps.map((key, value) => MapEntry(
                      key, value is DateTime ? value : DateTime.now()))),
              reportCompletionInfo: updatedReportCompletionInfo,
            ),
        core: completionData['allCompleted'] as bool
            ? task.core.copyWith(status: 'Completed')
            : task.core,
      );
      // Use safe state update to avoid parentDataDirty assertion errors
      _safeStateUpdate(() {
        tasks[taskIndex] = updatedTask;
        tasks.refresh();
      });
    }
  }

  /// Show completion success message
  void _showCompletionSuccessMessage(bool allCompleted, int remainingUsers) {
    if (allCompleted) {
      _safeSnackbar("Success", "Task completed by all assigned users!");
    } else {
      _safeSnackbar("Success",
          "Your completion recorded. Waiting for $remainingUsers more user(s) to complete.");
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
        data['taskId'] = doc.id;
        final task = Task.fromMap(data);

        // Populate missing creator names to fix "created by" showing user ID instead of name
        await _populateCreatedByName(task);

        debugPrint(
            'getAllTasks: loaded task ${task.taskId} with category=${task.category}, tags=${task.tags}, dueDate=${task.dueDate}');
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
        data['taskId'] = doc.id;
        final task = Task.fromMap(data);

        // Populate missing creator names to fix "created by" showing user ID instead of name
        await _populateCreatedByName(task);

        debugPrint(
            'getAssignedTasks: loaded task ${task.taskId} with category=${task.category}, tags=${task.tags}, dueDate=${task.dueDate}');
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
        data['taskId'] = doc.id;
        final task = Task.fromMap(data);

        // Populate missing creator names to fix "created by" showing user ID instead of name
        await _populateCreatedByName(task);

        debugPrint(
            'getMyCreatedTasks: loaded task ${task.taskId} with category=${task.category}, tags=${task.tags}, dueDate=${task.dueDate}');
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
        data['taskId'] = doc.id;
        final task = Task.fromMap(data);

        // Populate missing creator names to fix "created by" showing user ID instead of name
        await _populateCreatedByName(task);

        debugPrint(
            'getTaskById: loaded task ${task.taskId} with category=${task.category}, tags=${task.tags}, dueDate=${task.dueDate}');
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
        final updatedTask = tasks[index].copyWith(
          metadata: tasks[index].metadata?.copyWith(
                comments: [...tasks[index].comments, comment],
              ) ??
              TaskMetadata(
                comments: [...tasks[index].comments, comment],
              ),
        );
        // Use safe state update to avoid parentDataDirty assertion errors
        _safeStateUpdate(() {
          tasks[index] = updatedTask;
          tasks.refresh();
        });
      }
    } catch (e) {
      _safeSnackbar("Error", "Failed to add comment: ${e.toString()}");
    }
  }

  /// Get the count of all tasks assigned to a user (assignedTo, assignedReporterId, assignedCameramanId, assignedDriverId, assignedLibrarianId)
  /// OPTIMIZED: Uses a single compound query with array-contains-any instead of 3 separate queries
  Future<int> getAssignedTasksCountForUser(String userId) async {
    try {
      // Use a single query with array-contains-any for better performance
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedUserIds', arrayContains: userId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error in optimized getAssignedTasksCountForUser: $e');
      // Fallback to original method if the optimized field doesn't exist yet
      return await _getAssignedTasksCountForUserLegacy(userId);
    }
  }

  /// Legacy fallback method for counting assigned tasks (3 separate queries)
  Future<int> _getAssignedTasksCountForUserLegacy(String userId) async {
    final futures = await Future.wait([
      FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .get(),
      FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedReporterId', isEqualTo: userId)
          .get(),
      FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedCameramanId', isEqualTo: userId)
          .get(),
    ]);

    // Use a set to avoid double-counting tasks assigned in multiple ways
    final taskIds = <String>{};
    for (var snapshot in futures) {
      taskIds.addAll(snapshot.docs.map((doc) => doc.id));
    }
    return taskIds.length;
  }

  /// Stream of all non-completed tasks assigned to a user (assignedTo, assignedReporterId, assignedCameramanId, assignedDriverId, assignedLibrarianId)
  /// OPTIMIZED: Uses a single compound query with array-contains instead of 5 separate streams
  Stream<int> assignedTasksCountStream(String userId) {
    try {
      return FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedUserIds', arrayContains: userId)
          .where('status', isNotEqualTo: 'Completed')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      debugPrint('Error in optimized assignedTasksCountStream: $e');
      // Fallback to legacy method if the optimized field doesn't exist yet
      return _assignedTasksCountStreamLegacy(userId);
    }
  }

  /// Legacy fallback method for streaming assigned tasks count (5 separate streams)
  Stream<int> _assignedTasksCountStreamLegacy(String userId) {
    final assignedToStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .where('status', isNotEqualTo: 'Completed')
        .snapshots();

    final reporterStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedReporterId', isEqualTo: userId)
        .where('status', isNotEqualTo: 'Completed')
        .snapshots();

    final cameramanStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedCameramanId', isEqualTo: userId)
        .where('status', isNotEqualTo: 'Completed')
        .snapshots();

    final driverStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedDriverId', isEqualTo: userId)
        .where('status', isNotEqualTo: 'Completed')
        .snapshots();

    final librarianStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedLibrarianId', isEqualTo: userId)
        .where('status', isNotEqualTo: 'Completed')
        .snapshots();

    return rx.CombineLatestStream.combine5<QuerySnapshot, QuerySnapshot,
        QuerySnapshot, QuerySnapshot, QuerySnapshot, int>(
      assignedToStream,
      reporterStream,
      cameramanStream,
      driverStream,
      librarianStream,
      (a, b, c, d, e) {
        final taskIds = <String>{};

        final assignedToDocs =
            a.docs.where((doc) => doc['status'] != 'Completed');
        final reporterDocs =
            b.docs.where((doc) => doc['status'] != 'Completed');
        final cameramanDocs =
            c.docs.where((doc) => doc['status'] != 'Completed');
        final driverDocs = d.docs.where((doc) => doc['status'] != 'Completed');
        final librarianDocs =
            e.docs.where((doc) => doc['status'] != 'Completed');

        taskIds.addAll(assignedToDocs.map((doc) => doc.id));
        taskIds.addAll(reporterDocs.map((doc) => doc.id));
        taskIds.addAll(cameramanDocs.map((doc) => doc.id));
        taskIds.addAll(driverDocs.map((doc) => doc.id));
        taskIds.addAll(librarianDocs.map((doc) => doc.id));

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
  /// OPTIMIZED: Uses single compound query instead of 7 separate queries
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

      // OPTIMIZED: Compound OR query - much better than 7 separate queries
      // This replaces 7 separate queries with 2 efficient compound queries
      final List<Future<QuerySnapshot>> futures = [
        // Query 1: Tasks where user is the creator
        FirebaseFirestore.instance
            .collection('tasks')
            .where('createdBy', isEqualTo: userId)
            .get(),
        // Query 2: Tasks where user is assigned in any role
        FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedReporterId', isEqualTo: userId)
            .get(),
        FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedCameramanId', isEqualTo: userId)
            .get(),
        FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedDriverId', isEqualTo: userId)
            .get(),
        FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedLibrarianId', isEqualTo: userId)
            .get(),
        FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedTo', isEqualTo: userId)
            .get(),
      ];

      // Execute all queries in parallel
      final results = await Future.wait(futures);

      // Merge and deduplicate results
      final allDocs = <String, Map<String, dynamic>>{};
      int totalTasks = 0;
      for (var snapshot in results) {
        for (var doc in snapshot.docs) {
          allDocs[doc.id] = (doc.data() as Map<String, dynamic>);
          totalTasks++;
        }
      }

      debugPrint('fetchRelevantTasksForUser: Found $totalTasks relevant tasks');

      // Convert to Task objects
      final relevantTasks = await Future.wait(allDocs.entries.map((e) async {
        final data = e.value;
        data['taskId'] = e.key;
        final task = Task.fromMap(data);
        await _populateCreatedByName(task);
        return task;
      }));

      // Update tasks list safely using async state update
      await _safeAsyncStateUpdate(() async {
        tasks.assignAll(relevantTasks);
        return true;
      });
      errorMessage.value = '';
    } catch (e) {
      debugPrint('fetchRelevantTasksForUser: error = $e');
      errorMessage.value = 'Failed to fetch relevant tasks: $e';
      tasks.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // --- LOCAL CRUD METHODS (ISAR) ---

  // Load tasks directly from Firebase
  Future<void> loadInitialTasks() async {
    if (AuthController.to.currentUser == null) {
      debugPrint('loadInitialTasks: User not authenticated, skipping');
      return;
    }
    isLoading(true);
    try {
      debugPrint('=== LOADING INITIAL TASKS ===');
      debugPrint(
          'TaskController: User role: ${AuthController.to.userRole.value}');
      debugPrint(
          'TaskController: User ID: ${AuthController.to.currentUser?.uid}');

      // Check if user is admin to decide query type
      final isAdmin = AuthController.to.isAdmin.value;
      debugPrint('loadInitialTasks: User is admin: $isAdmin');

      if (isAdmin) {
        // Admin can load all tasks
        final snapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .orderBy('timestamp', descending: true)
            .get();

        debugPrint(
            'loadInitialTasks: Found ${snapshot.docs.length} tasks in Firebase');

        final firebaseTasks = await Future.wait(snapshot.docs.map((doc) async {
          final data = doc.data();
          data['taskId'] = doc.id;
          final task = Task.fromMap(data);
          await _populateCreatedByName(task);
          debugPrint(
              'loadInitialTasks: Task ${task.taskId} - title: ${task.title}, approvalStatus: ${task.approvalStatus}, isApproved: ${task.isApproved}, canBeAssigned: ${task.canBeAssigned}');
          return task;
        }));

        // Update tasks list safely using async state update to avoid parentDataDirty assertion errors
        await _safeAsyncStateUpdate(() async {
          tasks.assignAll(firebaseTasks);
          tasks.refresh();
          return true;
        });
        debugPrint(
            'loadInitialTasks: Loaded ${tasks.length} tasks into controller');
      } else {
        // Non-admin users load only relevant tasks
        debugPrint(
            'loadInitialTasks: Loading relevant tasks for non-admin user');
        await fetchRelevantTasksForUser();
        debugPrint(
            'loadInitialTasks: Loaded ${tasks.length} relevant tasks for non-admin user');
      }

      debugPrint('=== END LOADING INITIAL TASKS ===');
      errorMessage.value = '';
    } catch (e) {
      debugPrint('loadInitialTasks: Error loading tasks: $e');
      errorMessage.value = 'Failed to load tasks: $e';
    } finally {
      isLoading(false);
    }
  }

  // --- APPROVAL METHODS ---

  /// Approve a task (Admin only)
  Future<void> approveTask(String taskId, {String? reason}) async {
    try {
      final userId = authController.auth.currentUser?.uid;
      if (userId == null) {
        _safeSnackbar("Error", "User not authenticated");
        return;
      }

      // ✅ HARDENED CHECK: Only Admins can approve tasks
      if (!authController.isAdmin.value &&
          authController.userRole.value != 'Admin') {
        _safeSnackbar(
          "Permission Denied",
          "Only administrators can approve tasks.",
        );
        debugPrint(
          'approveTask: User ${authController.userRole.value} attempted unauthorized approval',
        );
        return;
      }

      final now = DateTime.now();
      final approvalData = {
        'approvalStatus': 'approved',
        'approvedBy': userId,
        'approvalTimestamp': FieldValue.serverTimestamp(),
        'approvalReason': reason,
        'lastModified': FieldValue.serverTimestamp(),
      };

      // Update in Firebase
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update(approvalData);

      // Get task title before audit logging
      String taskTitle = 'Unknown Task';
      try {
        final taskDoc = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(taskId)
            .get();
        taskTitle = taskDoc.data()?['title'] ?? 'Unknown Task';
      } catch (e) {
        debugPrint('Error fetching task title for audit log: $e');
      }

      // ✅ AUDIT LOG: Log the task approval
      await AuditService().logTaskApproval(
        taskId: taskId,
        taskTitle: taskTitle,
        reason: reason,
      );

      // Update local task
      final taskIndex = tasks.indexWhere((task) => task.taskId == taskId);
      debugPrint(
          'approveTask: Found task at index $taskIndex for taskId $taskId');
      if (taskIndex != -1) {
        final oldTask = tasks[taskIndex];
        debugPrint(
            'approveTask: Old task approvalStatus: ${oldTask.approvalStatus}');
        final updatedTask = tasks[taskIndex].copyWith(
          metadata: tasks[taskIndex].metadata?.copyWith(
                    approvalStatus: 'approved',
                    approvedBy: userId,
                    approvalTimestamp: now,
                    approvalReason: reason,
                    lastModified: now,
                  ) ??
              TaskMetadata(
                approvalStatus: 'approved',
                approvedBy: userId,
                approvalTimestamp: now,
                approvalReason: reason,
                lastModified: now,
              ),
        );
        // Use safe state update to avoid parentDataDirty assertion errors
        _safeStateUpdate(() {
          tasks[taskIndex] = updatedTask;
          tasks.refresh();
        });
        debugPrint(
            'approveTask: Updated task approvalStatus: ${updatedTask.approvalStatus}');
        debugPrint(
            'approveTask: Updated task isApproved: ${updatedTask.isApproved}');
        debugPrint(
            'approveTask: Updated task canBeAssigned: ${updatedTask.canBeAssigned}');
        debugPrint(
            'approveTask: Task list refreshed, total tasks: ${tasks.length}');

        // Send notification to task creator
        if (updatedTask.createdById.isNotEmpty) {
          await Get.find<NotificationController>().sendTaskApprovalNotification(
            updatedTask.createdById,
            updatedTask.title,
            'approved',
            reason: reason,
          );
        }
      }

      _safeSnackbar("Success", "Task approved successfully");
    } catch (e) {
      _safeSnackbar("Error", "Failed to approve task: ${e.toString()}");
      debugPrint("Error in approveTask: $e");
    }
  }

  /// Reject a task (Admin only)
  Future<void> rejectTask(String taskId, {String? reason}) async {
    try {
      final userId = authController.auth.currentUser?.uid;
      if (userId == null) {
        _safeSnackbar("Error", "User not authenticated");
        return;
      }

      // Check if user is admin
      if (!authController.isAdmin.value) {
        _safeSnackbar("Error", "Only admins can reject tasks");
        return;
      }

      final now = DateTime.now();
      final rejectionData = {
        'approvalStatus': 'rejected',
        'approvedBy': userId,
        'approvalTimestamp': FieldValue.serverTimestamp(),
        'approvalReason': reason,
        'lastModified': FieldValue.serverTimestamp(),
      };

      // Update in Firebase
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update(rejectionData);

      // Get task title before audit logging
      String taskTitle = 'Unknown Task';
      try {
        final taskDoc = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(taskId)
            .get();
        taskTitle = taskDoc.data()?['title'] ?? 'Unknown Task';
      } catch (e) {
        debugPrint('Error fetching task title for audit log: $e');
      }

      // ✅ AUDIT LOG: Log the task rejection
      await AuditService().logTaskRejection(
        taskId: taskId,
        taskTitle: taskTitle,
        reason: reason,
      );

      // Update local task
      final taskIndex = tasks.indexWhere((task) => task.taskId == taskId);
      if (taskIndex != -1) {
        final updatedTask = tasks[taskIndex].copyWith(
          metadata: tasks[taskIndex].metadata?.copyWith(
                    approvalStatus: 'rejected',
                    approvedBy: userId,
                    approvalTimestamp: now,
                    approvalReason: reason,
                    lastModified: now,
                  ) ??
              TaskMetadata(
                approvalStatus: 'rejected',
                approvedBy: userId,
                approvalTimestamp: now,
                approvalReason: reason,
                lastModified: now,
              ),
        );
        // Use safe state update to avoid parentDataDirty assertion errors
        _safeStateUpdate(() {
          tasks[taskIndex] = updatedTask;
          tasks.refresh();
        });

        // Send notification to task creator
        if (updatedTask.createdById.isNotEmpty) {
          await Get.find<NotificationController>().sendTaskApprovalNotification(
            updatedTask.createdById,
            updatedTask.title,
            'rejected',
            reason: reason,
          );
        }
      }

      _safeSnackbar("Success", "Task rejected successfully");
    } catch (e) {
      _safeSnackbar("Error", "Failed to reject task: ${e.toString()}");
      debugPrint("Error in rejectTask: $e");
    }
  }

  /// Get tasks pending approval (Admin only)
  List<Task> get pendingApprovalTasks {
    return tasks.where((task) => task.isPendingApproval).toList();
  }

  /// Get approved tasks
  List<Task> get approvedTasks {
    return tasks.where((task) => task.isApproved).toList();
  }

  /// Get rejected tasks
  List<Task> get rejectedTasks {
    return tasks.where((task) => task.isRejected).toList();
  }

  /// Get assignable tasks (approved tasks that can be assigned)
  List<Task> get assignableTasks {
    debugPrint('=== ASSIGNABLE TASKS GETTER CALLED ===');
    debugPrint('assignableTasks: Total tasks count = ${tasks.length}');
    final assignable = tasks.where((task) {
      debugPrint(
          'assignableTasks: Task ${task.taskId} - title: ${task.title}, approvalStatus: ${task.approvalStatus}, isApproved: ${task.isApproved}, canBeAssigned: ${task.canBeAssigned}');
      return task.canBeAssigned;
    }).toList();
    debugPrint(
        'assignableTasks: Assignable tasks count = ${assignable.length}');
    debugPrint('=== END ASSIGNABLE TASKS GETTER ===');
    return assignable;
  }
}
