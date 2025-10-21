// controllers/admin_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/models/task.dart';
import 'package:task/utils/snackbar_utils.dart';
import 'package:task/service/fcm_service.dart';
import 'package:task/service/enhanced_notification_service.dart';
import 'package:task/service/user_cache_service.dart';

class AdminController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  var adminName = "".obs;
  var adminEmail = "".obs;
  var adminPhotoUrl = "".obs;
  var adminCreationDate = "".obs;
  var adminPrivileges = <String>[].obs;

  var totalUsers = 0.obs;
  var totalTasks = 0.obs;
  var completedTasks = 0.obs;
  var pendingTasks = 0.obs;
  var overdueTasks = 0.obs;
  var onlineUsers = 0.obs;
  var totalConversations = 0.obs;
  var newsCount = 0.obs;

  var userNames = <String>[].obs;
  var taskTitles = <String>[].obs;
  var completedTaskTitles = <String>[].obs;
  var pendingTaskTitles = <String>[].obs;
  var overdueTaskTitles = <String>[].obs;

  var isLoading = false.obs;
  var isProfileLoading = false.obs;
  var isStatsLoading = false.obs;
  var userList = <Map<String, String>>[].obs;

  var selectedUserName = ''.obs;
  var selectedTaskTitle = ''.obs;

  var taskSnapshotDocs = <Map<String, dynamic>>[].obs; // Store as Map

  // Add a statistics RxMap for dashboard compatibility
  final RxMap<String, dynamic> statistics = <String, dynamic>{}.obs;

  // Stream subscriptions for proper cleanup
  StreamSubscription<QuerySnapshot>? _dashboardMetricsSubscription;

  // Safe snackbar method
  void _safeSnackbar(String title, String message) {
    SnackbarUtils.showSnackbar(title, message);
  }

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
    startRealtimeUpdates();
    if (_auth.currentUser != null) {
      initializeAdminData();
    }
  }

  void startRealtimeUpdates() {
    // Cancel any existing subscription to prevent memory leaks
    _dashboardMetricsSubscription?.cancel();

    _dashboardMetricsSubscription = _firestore
        .collection('dashboard_metrics')
        .snapshots()
        .listen((snapshot) {
      try {
        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          totalUsers.value = data['totalUsers'] ?? totalUsers.value;
          totalTasks.value = data['tasks']?['total'] ?? totalTasks.value;
          completedTasks.value = data['tasks']?['completed'] ?? completedTasks.value;
          pendingTasks.value = data['tasks']?['pending'] ?? pendingTasks.value;
          overdueTasks.value = data['tasks']?['overdue'] ?? overdueTasks.value;

          // Update statistics map
          statistics['users'] = totalUsers.value;
          statistics['tasks'] = totalTasks.value;
          statistics['completed'] = completedTasks.value;
          statistics['pending'] = pendingTasks.value;
          statistics['overdue'] = overdueTasks.value;
        }
      } catch (e) {
        debugPrint('Error processing dashboard metrics snapshot: $e');
      }
    }, onError: (e) {
      debugPrint('Dashboard metrics stream error: $e');
    });
  }

  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('tasks').get();
      final allDocs = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Enrich with creatorName using global cache (persists across navigation)
      try {
        final userCacheService = Get.find<UserCacheService>();
        for (final data in allDocs) {
          final creatorId =
              (data['createdById'] ?? data['createdBy'] ?? '').toString();
          if (creatorId.isNotEmpty) {
            final name = userCacheService.getUserNameSync(creatorId);
            if (name != 'Unknown User') {
              data['createdByName'] = name;
              data['creatorName'] = name;
            }
          }
        }
      } catch (e) {
        // If cache service not available, skip enrichment.
      }

      taskSnapshotDocs.assignAll(allDocs);

      pendingTaskTitles.clear();
      completedTaskTitles.clear();

      for (var doc in allDocs) {
        final title = doc['title'] ?? '';
        final status = (doc['status'] ?? '').toString().toLowerCase();

        bool isTaskCompleted = false;
        if (status == 'completed') {
          // Check if all assigned users have completed the task
          final completedByUserIds =
              List<String>.from(doc['completedByUserIds'] ?? []);
          final assignedUserIds = <String>[];

          // Collect all assigned user IDs
          if (doc['assignedReporterId'] != null &&
              doc['assignedReporterId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedReporterId'].toString());
          }
          if (doc['assignedCameramanId'] != null &&
              doc['assignedCameramanId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedCameramanId'].toString());
          }
          if (doc['assignedDriverId'] != null &&
              doc['assignedDriverId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedDriverId'].toString());
          }
          if (doc['assignedLibrarianId'] != null &&
              doc['assignedLibrarianId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedLibrarianId'].toString());
          }

          // If no users are assigned, treat as completed (backward compatibility)
          if (assignedUserIds.isEmpty) {
            isTaskCompleted = true;
          } else if (completedByUserIds.isEmpty) {
            // If completedByUserIds is empty, it's using old logic, so count as completed
            isTaskCompleted = true;
          } else {
            // Check if all assigned users have completed the task
            isTaskCompleted = assignedUserIds
                .every((userId) => completedByUserIds.contains(userId));
          }
        }

        if (isTaskCompleted) {
          completedTaskTitles.add(title);
        } else {
          pendingTaskTitles.add(title);
        }
      }

      totalTasks.value = allDocs.length;
      completedTasks.value = completedTaskTitles.length;
      pendingTasks.value = pendingTaskTitles.length;

      // Update statistics map
      statistics['tasks'] = totalTasks.value;
      statistics['completed'] = completedTasks.value;
      statistics['pending'] = pendingTasks.value;
    } catch (e) {
      _safeSnackbar("Error", "Failed to load dashboard data: $e");
    }
    isLoading.value = false;
  }

  Future<void> initializeAdminData() async {
    try {
      isLoading(true);
      await _verifyAdminAccess();
      await Future.wait([
        fetchAdminProfile(),
        fetchStatistics(),
      ]);
      if (adminName.value.isNotEmpty) {
        Get.offAllNamed('/admin-dashboard');
      }
    } catch (e) {
      debugPrint("Admin initialization error: $e");
      // Delay the snackbar until the next frame to ensure context is available
      Future.delayed(Duration.zero, () {
        if (Get.context != null) {
          _safeSnackbar("Admin Error", "Failed to initialize admin data");
        }
      });
      await logout();
    } finally {
      isLoading(false);
    }
  }

  Future<void> _verifyAdminAccess() async {
    final authController = Get.find<AuthController>();
    if (authController.userRole.value != "Admin") {
      throw Exception("Not an admin user");
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("No authenticated user");

    final adminDoc = await _firestore.collection('admins').doc(userId).get();
    if (!adminDoc.exists) {
      await _createAdminProfileFromUser(userId);
    }
  }

  Future<void> _createAdminProfileFromUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        await createAdminProfile(
          userId: userId,
          fullName: userData?['fullName'] ?? "Administrator",
          email: userData?['email'] ?? "",
          photoUrl: userData?['photoUrl'] ?? "",
        );
      } else {
        throw Exception("User document not found");
      }
    } catch (e) {
      throw Exception("Failed to create admin profile: ${e.toString()}");
    }
  }

  // In AdminController, REPLACE your fetchStatistics function with this one

  Future<void> fetchStatistics() async {
    try {
      isStatsLoading(true);
      final now = DateTime.now();

      // First, get the user data since it's most critical
      final userSnapshot = await _firestore.collection('users').get()
          .timeout(const Duration(seconds: 10));
      
      // Update user counts immediately
      final userDocs = userSnapshot.docs;
      totalUsers.value = userDocs.where((doc) {
        final userData = doc.data();
        return userData['role'] != 'Librarian' && userData['role'] != 'Admin';
      }).length;

      // Then fetch tasks, online users, conversations and news sequentially
      final taskSnapshot = await _firestore.collection('tasks').get();
      final taskDocs = taskSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      taskSnapshotDocs.assignAll(taskDocs);

      // Assign statistics based on fetched data
      totalTasks.value = taskDocs.length;

      final onlineUsersSnapshot = await _firestore
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .get();
      onlineUsers.value = onlineUsersSnapshot.docs.length;

      final conversationsSnapshot = await _firestore.collection('conversations').get();
      totalConversations.value = conversationsSnapshot.docs.length;

      final newsSnapshot = await _firestore.collection('news').get();
      newsCount.value = newsSnapshot.docs.length;

      // Updated logic: Only count tasks as completed if ALL assigned users have completed them
      completedTasks.value = taskDocs.where((doc) {
        final status = (doc['status'] ?? '').toString().toLowerCase();
        if (status == 'completed') {
          // For backward compatibility, if it's marked as completed, check if it uses new logic
          final completedByUserIds =
              List<String>.from(doc['completedByUserIds'] ?? []);
          final assignedUserIds = <String>[];

          // Collect all assigned user IDs
          if (doc['assignedReporterId'] != null &&
              doc['assignedReporterId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedReporterId'].toString());
          }
          if (doc['assignedCameramanId'] != null &&
              doc['assignedCameramanId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedCameramanId'].toString());
          }
          if (doc['assignedDriverId'] != null &&
              doc['assignedDriverId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedDriverId'].toString());
          }
          if (doc['assignedLibrarianId'] != null &&
              doc['assignedLibrarianId'].toString().isNotEmpty) {
            assignedUserIds.add(doc['assignedLibrarianId'].toString());
          }

          // If no users are assigned, treat as completed (backward compatibility)
          if (assignedUserIds.isEmpty) return true;

          // If completedByUserIds is empty, it's using old logic, so count as completed
          if (completedByUserIds.isEmpty) return true;

          // Check if all assigned users have completed the task
          return assignedUserIds
              .every((userId) => completedByUserIds.contains(userId));
        }
        return false;
      }).length;

      pendingTasks.value = taskDocs
          .where((doc) =>
              (doc['status'] ?? '').toString().toLowerCase() != 'completed')
          .length;
      overdueTasks.value = taskDocs.where((doc) {
        final due = doc['dueDate'];
        return due is Timestamp &&
            due.toDate().isBefore(now) &&
            (doc['status'] ?? '').toString().toLowerCase() != 'completed';
      }).length;

      // ... your existing logic for userNames, taskTitles, etc. is fine ...
      userNames.value = userDocs
          .map((doc) => doc['fullName'] ?? "Unknown User")
          .cast<String>()
          .toList();
      taskTitles.value = taskDocs
          .map((doc) => doc['title'] ?? 'Untitled')
          .cast<String>()
          .toList();

      // --- MODIFIED: Update the statistics map with the new data ---
      statistics['users'] = totalUsers.value;
      statistics['online'] = onlineUsers.value; // NEW
      statistics['conversations'] = totalConversations.value; // NEW
      statistics['news'] = newsCount.value; // NEW
      statistics['tasks'] = totalTasks.value;
      statistics['completed'] = completedTasks.value;
      statistics['pending'] = pendingTasks.value;
      statistics['overdue'] = overdueTasks.value;
    } on TimeoutException {
      _safeSnackbar('Error', 'Fetching statistics timed out');
    } catch (e) {
      _safeSnackbar('Error', 'Failed to fetch statistics: ${e.toString()}');
    } finally {
      isStatsLoading(false);
    }
  }

  void filterTasksByUser(String fullName) {
    final userTasks = taskSnapshotDocs.where((doc) =>
        (doc['createdByName']?.toString().toLowerCase() ?? '') ==
        fullName.toLowerCase());

    final now = DateTime.now();

    completedTaskTitles.value = userTasks
        .where((doc) {
          final status = (doc['status'] ?? '').toString().toLowerCase();
          if (status == 'completed') {
            // Check if all assigned users have completed the task
            final completedByUserIds =
                List<String>.from(doc['completedByUserIds'] ?? []);
            final assignedUserIds = <String>[];

            // Collect all assigned user IDs
            if (doc['assignedReporterId'] != null &&
                doc['assignedReporterId'].toString().isNotEmpty) {
              assignedUserIds.add(doc['assignedReporterId'].toString());
            }
            if (doc['assignedCameramanId'] != null &&
                doc['assignedCameramanId'].toString().isNotEmpty) {
              assignedUserIds.add(doc['assignedCameramanId'].toString());
            }
            if (doc['assignedDriverId'] != null &&
                doc['assignedDriverId'].toString().isNotEmpty) {
              assignedUserIds.add(doc['assignedDriverId'].toString());
            }
            if (doc['assignedLibrarianId'] != null &&
                doc['assignedLibrarianId'].toString().isNotEmpty) {
              assignedUserIds.add(doc['assignedLibrarianId'].toString());
            }

            // If no users are assigned, treat as completed (backward compatibility)
            if (assignedUserIds.isEmpty) return true;

            // If completedByUserIds is empty, it's using old logic, so count as completed
            if (completedByUserIds.isEmpty) return true;

            // Check if all assigned users have completed the task
            return assignedUserIds
                .every((userId) => completedByUserIds.contains(userId));
          }
          return false;
        })
        .map((doc) => doc['title'] ?? '')
        .cast<String>()
        .toList();

    pendingTaskTitles.value = userTasks
        .where((doc) =>
            (doc['status'] ?? '').toString().toLowerCase() != 'completed')
        .map((doc) => doc['title'] ?? '')
        .cast<String>()
        .toList();

    overdueTaskTitles.value = userTasks
        .where((doc) {
          final due = doc['dueDate'];
          return due is Timestamp &&
              due.toDate().isBefore(now) &&
              (doc['status'] ?? '').toString().toLowerCase() != 'completed';
        })
        .map((doc) => doc['title'] ?? '')
        .cast<String>()
        .toList();

    completedTasks.value = completedTaskTitles.length;
    pendingTasks.value = pendingTaskTitles.length;
    overdueTasks.value = overdueTaskTitles.length;

    // Update statistics map
    statistics['completed'] = completedTasks.value;
    statistics['pending'] = pendingTasks.value;
    statistics['overdue'] = overdueTasks.value;
  }

  Future<void> createAdminProfile({
    required String userId,
    required String fullName,
    required String email,
    String photoUrl = "",
    List<String> privileges = const ["full_access"],
  }) async {
    try {
      isProfileLoading(true);
      await _firestore.collection('admins').doc(userId).set({
        "uid": userId,
        "fullName": fullName,
        "email": email,
        "photoUrl": photoUrl,
        "privileges": privileges,
        "createdAt": FieldValue.serverTimestamp(),
        "lastUpdated": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      adminName.value = fullName;
      adminEmail.value = email;
      adminPhotoUrl.value = photoUrl;
      adminPrivileges.value = privileges;
      adminCreationDate.value = DateFormat('MMMM d, y').format(DateTime.now());
    } catch (e) {
      _safeSnackbar("Error", "Failed to create admin profile: ${e.toString()}");
      rethrow;
    } finally {
      isProfileLoading(false);
    }
  }

  Future<void> fetchAdminProfile() async {
    try {
      isProfileLoading(true);
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("No authenticated user");

      final adminDoc = await _firestore.collection('admins').doc(userId).get();

      if (!adminDoc.exists) {
        throw Exception("Admin document not found");
      }

      final data = adminDoc.data() as Map<String, dynamic>;

      adminName.value = data['fullName'] ?? "Administrator";
      adminEmail.value = data['email'] ?? "";
      adminPhotoUrl.value = data['photoUrl'] ?? "";
      adminPrivileges.value = List<String>.from(data['privileges'] ?? []);

      if (data['createdAt'] != null) {
        final date = (data['createdAt'] as Timestamp).toDate();
        adminCreationDate.value = DateFormat('MMMM d, y').format(date);
      }
    } catch (e) {
      _safeSnackbar("Error", "Failed to fetch admin profile: ${e.toString()}");
      rethrow;
    } finally {
      isProfileLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      isLoading(true);
      await _auth.signOut();
      clearAdminData();
      Get.offAllNamed('/login');
    } catch (e) {
      _safeSnackbar("Error", "Logout failed: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  void clearAdminData() {
    adminName.value = "";
    adminEmail.value = "";
    adminPhotoUrl.value = "";
    adminCreationDate.value = "";
    adminPrivileges.clear();

    totalUsers.value = 0;
    totalTasks.value = 0;
    completedTasks.value = 0;
    pendingTasks.value = 0;
    overdueTasks.value = 0;
    newsCount.value = 0;

    userNames.clear();
    taskTitles.clear();
    completedTaskTitles.clear();
    pendingTaskTitles.clear();
    overdueTaskTitles.clear();

    selectedUserName.value = '';
    selectedTaskTitle.value = '';
    taskSnapshotDocs.clear();

    statistics.clear();
  }

  Future<void> deleteUser(String userId) async {
    try {
      isLoading(true);
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw 'User not found';

      await _firestore.runTransaction((transaction) async {
        transaction.delete(_firestore.collection('users').doc(userId));
        final tasks = await _firestore
            .collection('tasks')
            .where('createdBy', isEqualTo: userId)
            .get();
        for (final task in tasks.docs) {
          transaction.delete(task.reference);
        }
      });

      _safeSnackbar("Success", "User and their tasks deleted successfully");
      fetchStatistics();
    } catch (e) {
      _safeSnackbar("Error", "Delete failed: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTasks() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('tasks').get();
      var tasks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['taskId'] = doc.id;
        return Task.fromMap(data);
      }).toList();

      pendingTasks.value =
          tasks.where((task) => task.status == 'Pending').length;
      completedTasks.value =
          tasks.where((task) => task.status == 'Completed').length;
    } catch (e) {
      _safeSnackbar("Error", "Failed to fetch tasks: ${e.toString()}");
    }
  }

  /// Assign a task to a user and also store assignedName for easy display
  Future<void> assignTaskToUser({
    required String userId,
    required String assignedName,
    required String taskTitle,
    required String taskDescription,
    required DateTime dueDate,
    required String taskId,
  }) async {
    try {
      // Fetch the user's role
      final userDoc = await firestore.collection('users').doc(userId).get();
      final userRole = userDoc.data()?['role'] ?? '';
      final updateData = <String, dynamic>{
        'assignedTo': userId,
        'assignedName': assignedName,
        'assignedAt': FieldValue.serverTimestamp(),
      };
      // Set role-specific fields for robust UI updates
      if (userRole == 'Reporter') {
        updateData['assignedReporterId'] = userId;
        updateData['assignedReporterName'] = assignedName;
      } else if (userRole == 'Cameraman') {
        updateData['assignedCameramanId'] = userId;
        updateData['assignedCameramanName'] = assignedName;
      } else if (userRole == 'Driver') {
        updateData['assignedDriverId'] = userId;
        updateData['assignedDriverName'] = assignedName;
      } else if (userRole == 'Librarian') {
        updateData['assignedLibrarianId'] = userId;
        updateData['assignedLibrarianName'] = assignedName;
      }
      await firestore.collection('tasks').doc(taskId).update(updateData);

      // Format the due date
      final String formattedDate =
          DateFormat('yyyy-MM-dd – kk:mm').format(dueDate);

      // Add notification with message field
      await firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'task_assignment',
        'taskId': taskId,
        'title': taskTitle,
        'message': 'Description: $taskDescription\nDue: $formattedDate',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Send push notification via FCM
      await sendTaskNotification(userId, taskTitle);

      // Show local in-app notification
      try {
        final enhancedNotificationService =
            Get.find<EnhancedNotificationService>();
        enhancedNotificationService.showInfo(
          title: 'Task Assigned',
          message:
              'Task "$taskTitle" has been assigned to $assignedName\nDue: ${DateFormat('yyyy-MM-dd – kk:mm').format(dueDate)}',
          duration: const Duration(seconds: 5),
        );
      } catch (e) {
        // Enhanced notification service might not be initialized
      }

      // Refresh dashboard/task data so UI updates
      await fetchDashboardData();
    } catch (e) {
      _safeSnackbar("Error", "Failed to assign task or notify user: $e");
    }
  }

  /// Get tasks pending approval
  List<Map<String, dynamic>> get pendingApprovalTasks {
    return taskSnapshotDocs.where((task) {
      final approvalStatus = task['approvalStatus']?.toString().toLowerCase();
      return approvalStatus == null || approvalStatus == 'pending';
    }).toList();
  }

  /// Approve a task (delegates to TaskController)
  Future<void> approveTask(String taskId, {String? reason}) async {
    try {
      final taskController = Get.find<TaskController>();
      await taskController.approveTask(taskId, reason: reason);
      // Refresh dashboard data to update UI
      await fetchDashboardData();
    } catch (e) {
      _safeSnackbar("Error", "Failed to approve task: ${e.toString()}");
    }
  }

  /// Reject a task (delegates to TaskController)
  Future<void> rejectTask(String taskId, {String? reason}) async {
    try {
      final taskController = Get.find<TaskController>();
      await taskController.rejectTask(taskId, reason: reason);
      // Refresh dashboard data to update UI
      await fetchDashboardData();
    } catch (e) {
      _safeSnackbar("Error", "Failed to reject task: ${e.toString()}");
    }
  }

  @override
  void onClose() {
    // Cancel stream subscriptions to prevent memory leaks
    _dashboardMetricsSubscription?.cancel();
    _dashboardMetricsSubscription = null;

    debugPrint('AdminController: Properly disposed');
    super.onClose();
  }
}
