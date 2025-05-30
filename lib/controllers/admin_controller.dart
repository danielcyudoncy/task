// controllers/admin_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/auth_controller.dart';

class AdminController extends GetxController {
  void startRealtimeUpdates() {
    // Implement real-time updates logic here
    // Example: Listen to Firestore changes
    _firestore.collection('dashboard_metrics').snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        totalUsers.value = data['totalUsers'] ?? 0;
        totalTasks.value = data['tasks']['total'] ?? 0;
        completedTasks.value = data['tasks']['completed'] ?? 0;
        pendingTasks.value = data['tasks']['pending'] ?? 0;
        overdueTasks.value = data['tasks']['overdue'] ?? 0;
      }
    });
  }
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

  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  

  List<QueryDocumentSnapshot> taskSnapshotDocs = [];

  @override
  void onInit() {
     fetchDashboardData();  // Initial load
     startRealtimeUpdates();
    super.onInit();
    if (_auth.currentUser != null) {
      initializeAdminData();
    }
  }
  

    Future<void> fetchDashboardData() async {  // Changed from _fetchDashboardData to make it public
    try {
      isLoading(true);
      final snapshot = await _firestore
          .collection('dashboard_metrics')
          .doc('summary')
          .get();
      
      if (snapshot.exists) {
        totalUsers.value = snapshot['totalUsers'] ?? 0;
        totalTasks.value = snapshot['tasks']['total'] ?? 0;
        completedTasks.value = snapshot['tasks']['completed'] ?? 0;
        pendingTasks.value = snapshot['tasks']['pending'] ?? 0;
        overdueTasks.value = snapshot['tasks']['overdue'] ?? 0;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load dashboard data');
    } finally {
      isLoading(false);
    }
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
    final taskDocs = taskSnapshot.docs;

    // Update total counts
    totalUsers.value = userDocs.length;
    totalTasks.value = taskDocs.length;

    taskSnapshotDocs = taskDocs;

    // Update task counts
    completedTasks.value =
        taskDocs.where((doc) => doc.data()['status'] == 'completed').length;
    pendingTasks.value =
        taskDocs.where((doc) => doc.data()['status'] == 'pending').length;
    overdueTasks.value = taskDocs.where((doc) {
      final data = doc.data();
      final dueTs = data['dueDate'] as Timestamp?;
      return dueTs != null &&
          dueTs.toDate().isBefore(now) &&
          data['status'] != 'completed';
    }).length;

    // Populate user names and debug the data
    userNames.value = userDocs.map((doc) {
      final data = doc.data();
      final fullName = data['fullName']?.toString() ?? "Unknown User";
        return fullName;
    }).toList();

    // Populate task titles
    taskTitles.value = taskDocs
        .map((doc) => doc.data()['title'] as String? ?? 'Untitled')
        .toList();

    completedTaskTitles.value = taskDocs
        .where((doc) => doc.data()['status'] == 'completed')
        .map((doc) => doc.data()['title'] as String? ?? '')
        .toList();

    pendingTaskTitles.value = taskDocs
        .where((doc) => doc.data()['status'] == 'pending')
        .map((doc) => doc.data()['title'] as String? ?? '')
        .toList();

    overdueTaskTitles.value = taskDocs
        .where((doc) {
          final data = doc.data();
          final dueTs = data['dueDate'] as Timestamp?;
          return dueTs != null &&
              dueTs.toDate().isBefore(now) &&
              data['status'] != 'completed';
        })
        .map((doc) => doc.data()['title'] as String? ?? '')
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
        (doc.data() as Map<String, dynamic>)['createdByName']?.toString().toLowerCase() ==
        fullName.toLowerCase());

    final now = DateTime.now();

    completedTaskTitles.value = userTasks
        .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'completed')
        .map((doc) => (doc.data() as Map<String, dynamic>)['title']?.toString() ?? '')
        .toList()
        .cast<String>();

    pendingTaskTitles.value = userTasks
        .where((doc) => (doc.data() as Map<String, dynamic>)['status'] != 'completed')
        .map((doc) => (doc.data() as Map<String, dynamic>)['title']?.toString() ?? '')
        .toList()
        .cast<String>();

    overdueTaskTitles.value = userTasks
        .where((doc) {
          final dueTs = (doc.data() as Map<String, dynamic>)['dueDate'] as Timestamp?;
          return dueTs != null &&
              dueTs.toDate().isBefore(now) &&
              (doc.data() as Map<String, dynamic>)['status'] != 'completed';
        })
        .map((doc) => (doc.data() as Map<String, dynamic>)['title']?.toString() ?? '')
        .toList()
        .cast<String>();

    completedTasks.value = completedTaskTitles.length;
    pendingTasks.value = pendingTaskTitles.length;
    overdueTasks.value = overdueTaskTitles.length;
  }  Future<void> createAdminProfile({    required String userId,
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

      DocumentSnapshot adminDoc =
          await _firestore.collection('admins').doc(userId).get();

      if (!adminDoc.exists) {
        throw Exception("Admin document not found");
      }

      final data = adminDoc.data() as Map<String, dynamic>? ?? {};

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
    adminPrivileges.value = [];

    totalUsers.value = 0;
    totalTasks.value = 0;
    completedTasks.value = 0;
    pendingTasks.value = 0;
    overdueTasks.value = 0;

    userNames.value = [];
    taskTitles.value = [];
    completedTaskTitles.value = [];
    pendingTaskTitles.value = [];
    overdueTaskTitles.value = [];

    selectedUserName.value = '';
    selectedTaskTitle.value = '';
  }

  Future<void> deleteUser(String userId) async {
    try {
      isLoading(true);

      // 1. Verify user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw 'Firestore user not found';
      }

      // 3. Execute deletion (with transaction for safety)
      await _firestore.runTransaction((transaction) async {
        // Delete user document
        transaction.delete(_firestore.collection('users').doc(userId));

        // Optional: Delete user's tasks or other related data
        final tasks = await _firestore
            .collection('tasks')
            .where('assignedTo', isEqualTo: userId)
            .get();

        for (final doc in tasks.docs) {
          transaction.delete(doc.reference);
        }
      });

      
      userList.removeWhere((user) => user['id'] == userId);
      Get.snackbar('Success', 'User deleted permanently');
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', _getAuthErrorMessage(e));
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'requires-recent-login':
        return 'Requires recent authentication. Please re-login.';
      case 'user-not-found':
        return 'User account not found';
      case 'insufficient-permissions':
        return 'Admin privileges required';
      default:
        return e.message ?? 'User deletion failed';
    }
  }
}
