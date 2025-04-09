// controllers/admin_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminController extends GetxController {
  // Admin Profile Data
  var adminName = "".obs; // Reactive variable for admin name
  var adminPhotoUrl = "".obs; // Reactive variable for admin profile photo

  // User Role for Role-Based Access Control
  var userRole = "".obs; // Reactive variable for user role (e.g., "Admin")

  // Loading Indicator
  var isLoading =
      false.obs; // Reactive variable to show/hide loading indicators

  // Statistics Data
  var totalUsers = 0.obs; // Total number of users
  var totalTasks = 0.obs; // Total number of tasks
  var completedTasks = 0.obs; // Number of completed tasks
  var pendingTasks = 0.obs; // Number of pending tasks

  // List of User and Task Names (for Details Dialog)
  var userNames = <String>[].obs; // List of user names
  var taskTitles = <String>[].obs; // List of task titles
  var completedTaskTitles = <String>[].obs; // List of completed task titles
  var pendingTaskTitles = <String>[].obs; // List of pending task titles

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    fetchAdminProfile(); // Load admin profile data
    fetchUserRole(); // Load user role
    fetchStatistics(); // Load initial statistics
  }

  // Fetch Admin Profile Data from Firestore
  Future<void> fetchAdminProfile() async {
    try {
      isLoading.value = true;
      // Fetch admin profile document from Firestore
      DocumentSnapshot adminDoc = await _firestore
          .collection('admins')
          .doc('adminId') // Replace with the actual admin document ID
          .get();

      if (adminDoc.exists) {
        adminName.value = adminDoc.get('name') ?? "Admin";
        adminPhotoUrl.value = adminDoc.get('photoUrl') ?? "";
      } else {
        adminName.value = "Admin"; // Fallback name
        adminPhotoUrl.value = ""; // Fallback photo
      }
    } catch (e) {
      print("Error fetching admin profile: $e");
      adminName.value = "Admin"; // Fallback name
      adminPhotoUrl.value = ""; // Fallback photo
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch User Role for Role-Based Access Control from Firestore
  Future<void> fetchUserRole() async {
    try {
      isLoading.value = true;
      // Fetch user role document from Firestore
      DocumentSnapshot roleDoc = await _firestore
          .collection('user_roles')
          .doc('adminId') // Replace with the actual user role document ID
          .get();

      if (roleDoc.exists) {
        userRole.value = roleDoc.get('role') ?? "Admin";
      } else {
        userRole.value = ""; // Fallback role
      }
    } catch (e) {
      print("Error fetching user role: $e");
      userRole.value = ""; // Fallback role
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch Statistics Data from Firestore
  Future<void> fetchStatistics() async {
    try {
      isLoading.value = true;

      // Fetch total users
      QuerySnapshot userQuery = await _firestore.collection('users').get();
      totalUsers.value = userQuery.docs.length;

      // Fetch total tasks
      QuerySnapshot taskQuery = await _firestore.collection('tasks').get();
      totalTasks.value = taskQuery.docs.length;

      // Fetch completed tasks
      QuerySnapshot completedTaskQuery = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: 'completed')
          .get();
      completedTasks.value = completedTaskQuery.docs.length;

      // Fetch pending tasks
      QuerySnapshot pendingTaskQuery = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: 'pending')
          .get();
      pendingTasks.value = pendingTaskQuery.docs.length;

      // Populate user names
      userNames.value = userQuery.docs
          .map((doc) => doc.get('name') as String) // Safely cast to String
          .toList();

      // Populate task titles
      taskTitles.value = taskQuery.docs
          .map((doc) => doc.get('title') as String) // Safely cast to String
          .toList();

      // Populate completed task titles
      completedTaskTitles.value = completedTaskQuery.docs
          .map((doc) => doc.get('title') as String) // Safely cast to String
          .toList();

      // Populate pending task titles
      pendingTaskTitles.value = pendingTaskQuery.docs
          .map((doc) => doc.get('title') as String) // Safely cast to String
          .toList();
    } catch (e) {
      print("Error fetching statistics: $e");
      // Fallback values
      totalUsers.value = 0;
      totalTasks.value = 0;
      completedTasks.value = 0;
      pendingTasks.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Logout Functionality
  Future<void> logout() async {
    try {
      isLoading.value = true;
      // Simulate API call or database logout process
      await Future.delayed(const Duration(seconds: 1)); // Simulated delay
      Get.offAllNamed("/login"); // Redirect to login screen
    } catch (e) {
      print("Error during logout: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
