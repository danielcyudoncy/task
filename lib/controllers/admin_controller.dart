// controllers/admin_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminController extends GetxController {
  // Admin details
  var adminName = ''.obs;
  var adminPhotoUrl = ''.obs;

  // Loading indicator
  var isLoading = true.obs;

  // Statistics
  var totalUsers = 0.obs;
  var totalTasks = 0.obs;
  var completedTasks = 0.obs;
  var pendingTasks = 0.obs;

  // Lists for detail dialogs
  var userNames = <String>[].obs;
  var taskTitles = <String>[].obs;
  var completedTaskTitles = <String>[].obs;
  var pendingTaskTitles = <String>[].obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    fetchAdminProfile();
    fetchDashboardData();
  }

  // Fetch Admin Profile
  Future<void> fetchAdminProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _firestore.collection('users').doc(user.uid).get();

        if (snapshot.exists) {
          adminName.value = snapshot.data()?['name'] ?? 'Admin';
          adminPhotoUrl.value = snapshot.data()?['photoUrl'] ?? '';
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load profile: $e');
    }
  }

  // Fetch Statistics Data
  Future<void> fetchDashboardData() async {
    isLoading.value = true;

    try {
      QuerySnapshot<Map<String, dynamic>> userSnapshot =
          await _firestore.collection('users').get();
      QuerySnapshot<Map<String, dynamic>> taskSnapshot =
          await _firestore.collection('tasks').get();

      totalUsers.value = userSnapshot.size;
      totalTasks.value = taskSnapshot.size;

      userNames.value = userSnapshot.docs
          .map((doc) => doc.data()['name'] as String? ?? '')
          .toList();

      taskTitles.value = taskSnapshot.docs
          .map((doc) => doc.data()['title'] as String? ?? '')
          .toList();

      completedTasks.value = taskSnapshot.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      pendingTasks.value = taskSnapshot.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .length;

      completedTaskTitles.value = taskSnapshot.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .map((doc) => doc.data()['title'] as String? ?? '')
          .toList();

      pendingTaskTitles.value = taskSnapshot.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .map((doc) => doc.data()['title'] as String? ?? '')
          .toList();
    } catch (e) {
      print('Error fetching dashboard data: $e');
      Get.snackbar('Error', 'Failed to fetch data');
    }

    isLoading.value = false;
  }

  // Logout Logic
  Future<void> logout() async {
    try {
      await _auth.signOut();
      Get.offAllNamed('/login'); // Navigate to Login screen after logout
    } catch (e) {
      Get.snackbar('Error', 'Failed to logout: $e');
    }
  }
}
