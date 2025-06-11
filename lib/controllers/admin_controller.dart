// controllers/admin_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/models/task_model.dart';

class AdminController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  @override
  void onInit() {
    fetchDashboardData();
    startRealtimeUpdates();
    super.onInit();
    if (_auth.currentUser != null) {
      initializeAdminData();
    }
  }

  void startRealtimeUpdates() {
    _firestore.collection('dashboard_metrics').snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        totalUsers.value = data['totalUsers'] ?? 0;
        totalTasks.value = data['tasks']?['total'] ?? 0;
        completedTasks.value = data['tasks']?['completed'] ?? 0;
        pendingTasks.value = data['tasks']?['pending'] ?? 0;
        overdueTasks.value = data['tasks']?['overdue'] ?? 0;
      }
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
      taskSnapshotDocs.assignAll(allDocs);

      pendingTaskTitles.clear();
      completedTaskTitles.clear();

      for (var doc in allDocs) {
        final title = doc['title'] ?? '';
        final status = (doc['status'] ?? '').toString().toLowerCase();

        if (status == 'completed') {
          completedTaskTitles.add(title);
        } else {
          pendingTaskTitles.add(title);
        }
      }

      totalTasks.value = allDocs.length;
      completedTasks.value = completedTaskTitles.length;
      pendingTasks.value = pendingTaskTitles.length;
    } catch (e) {
      Get.snackbar("Error", "Failed to load dashboard data: $e");
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
      Get.snackbar("Admin Error", "Failed to initialize admin data");
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

  Future<void> fetchStatistics() async {
    try {
      isStatsLoading(true);
      final now = DateTime.now();

      final userSnapshot = await _firestore
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 10));
      final taskSnapshot = await _firestore
          .collection('tasks')
          .get()
          .timeout(const Duration(seconds: 10));

      final userDocs = userSnapshot.docs;
      final taskDocs = taskSnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
      taskSnapshotDocs.assignAll(taskDocs);

      totalUsers.value = userDocs.length;
      totalTasks.value = taskDocs.length;
      completedTasks.value = taskDocs
          .where((doc) =>
              (doc['status'] ?? '').toString().toLowerCase() == 'completed')
          .length;
      pendingTasks.value = taskDocs
          .where((doc) =>
              (doc['status'] ?? '').toString().toLowerCase() == 'pending')
          .length;
      overdueTasks.value = taskDocs.where((doc) {
        final due = doc['dueDate'];
        return due is Timestamp &&
            due.toDate().isBefore(now) &&
            (doc['status'] ?? '').toString().toLowerCase() != 'completed';
      }).length;

      userNames.value = userDocs
          .map((doc) => doc['fullName'] ?? "Unknown User")
          .cast<String>()
          .toList();
      taskTitles.value = taskDocs
          .map((doc) => doc['title'] ?? 'Untitled')
          .cast<String>()
          .toList();

      completedTaskTitles.value = taskDocs
          .where((doc) =>
              (doc['status'] ?? '').toString().toLowerCase() == 'completed')
          .map((doc) => doc['title'] ?? '')
          .cast<String>()
          .toList();

      pendingTaskTitles.value = taskDocs
          .where((doc) =>
              (doc['status'] ?? '').toString().toLowerCase() != 'completed')
          .map((doc) => doc['title'] ?? '')
          .cast<String>()
          .toList();

      overdueTaskTitles.value = taskDocs
          .where((doc) {
            final due = doc['dueDate'];
            return due is Timestamp &&
                due.toDate().isBefore(now) &&
                (doc['status'] ?? '').toString().toLowerCase() != 'completed';
          })
          .map((doc) => doc['title'] ?? '')
          .cast<String>()
          .toList();
    } on TimeoutException {
      Get.snackbar('Error', 'Fetching statistics timed out');
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch statistics: ${e.toString()}');
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
        .where((doc) =>
            (doc['status'] ?? '').toString().toLowerCase() == 'completed')
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
      Get.snackbar("Error", "Failed to create admin profile: ${e.toString()}");
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
      Get.snackbar("Error", "Failed to fetch admin profile: ${e.toString()}");
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
      Get.snackbar("Error", "Logout failed: ${e.toString()}");
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

    userNames.clear();
    taskTitles.clear();
    completedTaskTitles.clear();
    pendingTaskTitles.clear();
    overdueTaskTitles.clear();

    selectedUserName.value = '';
    selectedTaskTitle.value = '';
    taskSnapshotDocs.clear();
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

      Get.snackbar("Success", "User and their tasks deleted successfully");
      fetchStatistics();
    } catch (e) {
      Get.snackbar("Error", "Delete failed: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTasks() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('tasks').get();
      var tasks =
          snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).toList();

      pendingTasks.value =
          tasks.where((task) => task.status == 'Pending').length;
      completedTasks.value =
          tasks.where((task) => task.status == 'Completed').length;
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }

  /// Assign a task to a user and also store assignedName for easy display
  Future<void> assignTaskToUser(String userId, String taskTitle) async {
    final firestore = FirebaseFirestore.instance;
    final tasks = await firestore
        .collection('tasks')
        .where('title', isEqualTo: taskTitle)
        .get();

    if (tasks.docs.isEmpty) {
      throw Exception("Task not found.");
    }
    final taskDoc = tasks.docs.first.reference;

    // Fetch user's display name for assignment
    final userSnapshot = await firestore.collection('users').doc(userId).get();
    final userData = userSnapshot.data();
    final assignedName = userData?['fullName'] ?? 'Unknown';

    await taskDoc.update({
      'assignedTo': userId,
      'assignedName': assignedName,
      'assignedAt': FieldValue.serverTimestamp(), // <-- Add this line
    });

    await firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'type': 'task_assignment',
      'title': taskTitle,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}
