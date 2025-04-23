// controllers/admin_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/auth_controller.dart';

class AdminController extends GetxController {
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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<QueryDocumentSnapshot> taskSnapshotDocs = [];

  @override
  void onInit() {
    super.onInit();
    if (_auth.currentUser != null) {
      initializeAdminData();
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

      totalUsers.value = userDocs.length;
      totalTasks.value = taskDocs.length;

      taskSnapshotDocs = taskDocs;

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

      userNames.value = userDocs
          .map((doc) => doc.data()['fullName'] as String? ?? "Unknown")
          .toList();

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
}
