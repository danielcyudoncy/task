// controllers/admin_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AdminController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var totalUsers = 0.obs;
  var totalTasks = 0.obs;
  var completedTasks = 0.obs;
  var pendingTasks = 0.obs;

  final RxString adminName = "".obs;
  final RxString adminPhotoUrl = "".obs;
  final RxList<String> userNames = <String>[].obs;
  final RxList<String> taskTitles = <String>[].obs;
  final RxList<String> completedTaskTitles = <String>[].obs;
  final RxList<String> pendingTaskTitles = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAdminDetails(); // ✅ Fetch admin name & profile picture properly
    fetchDashboardStats(); // ✅ Fetch dashboard stats
  }

  // ✅ Fetch Admin's Full Name & Photo from Firestore
  void fetchAdminDetails() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot =
            await _firestore.collection('users').doc(user.uid).get();
        if (snapshot.exists && snapshot.data() != null) {
          adminName.value = snapshot['fullName']?.toString() ?? "Admin";
          adminPhotoUrl.value = snapshot['photoUrl']?.toString() ?? "";
        } else {
          adminName.value = "Admin"; // ✅ Fallback if no name found
        }

        // Debugging output to check if fullName updates
        if (kDebugMode) {
          print("Admin Name Updated: ${adminName.value}");
        } // 🔍 Debug
      } catch (e) {
        if (kDebugMode) {
          print("❌ Error fetching admin details: $e");
        }
      }
    }
  }

  // ✅ Fetch Dashboard Stats
  void fetchDashboardStats() async {
    try {
      // Fetch total users and their full names
      final userSnapshot = await _firestore.collection('users').get();
      totalUsers.value = userSnapshot.size;
      userNames.assignAll(userSnapshot.docs
          .map((doc) => doc.data()['fullName']?.toString() ?? "Unknown User")
          .toList());

      // Fetch total tasks
      final taskSnapshot = await _firestore.collection('tasks').get();
      totalTasks.value = taskSnapshot.size;
      taskTitles.assignAll(taskSnapshot.docs
          .map((doc) => doc.data()['title']?.toString() ?? "Untitled Task")
          .toList());

      // Fetch completed tasks
      await _fetchTasksByStatus('completed', completedTasks, completedTaskTitles);

      // Fetch pending tasks
      await _fetchTasksByStatus('pending', pendingTasks, pendingTaskTitles);
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error fetching dashboard stats: $e");
      }
    }
  }

  // Helper function to fetch tasks by status
  Future<void> _fetchTasksByStatus(String status, RxInt count, RxList<String> titles) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: status)
          .get();
      count.value = snapshot.size;
      titles.assignAll(snapshot.docs
          .map((doc) => doc.data()['title']?.toString() ?? "Unnamed Task")
          .toList());
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error fetching $status tasks: $e");
      }
    }
  }
}
