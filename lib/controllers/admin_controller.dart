// controllers/admin_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    fetchDashboardStats(); // ✅ Fetch real-time dashboard stats
  }

  // ✅ Fetch Admin's Full Name & Photo from Firestore
  void fetchAdminDetails() {
    final User? user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          adminName.value = snapshot['fullName']?.toString() ??
              "Admin"; // ✅ Ensure correct type
          adminPhotoUrl.value = snapshot['photoUrl']?.toString() ?? "";
        } else {
          adminName.value = "Admin"; // ✅ Fallback if no name found
        }

        // Debugging output to check if fullName updates
        print("Admin Name Updated: ${adminName.value}"); // 🔍 Debug
      });
    }
  }

  // ✅ Fetch Real-Time Dashboard Stats
  void fetchDashboardStats() {
    // Fetch total users and their full names
    _firestore.collection('users').snapshots().listen((snapshot) {
      totalUsers.value = snapshot.size;

      // ✅ Fix: Explicitly cast fullName to String
      userNames.assignAll(snapshot.docs
          .map((doc) => doc['fullName']?.toString() ?? "Unknown User")
          .toList());
    });

    // Fetch total tasks
    _firestore.collection('tasks').snapshots().listen((snapshot) {
      totalTasks.value = snapshot.size;
      taskTitles.assignAll(snapshot.docs
          .map((doc) => doc['title']?.toString() ?? "Untitled Task")
          .toList());
    });

    // Fetch completed tasks
    _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snapshot) {
      completedTasks.value = snapshot.size;
      completedTaskTitles.assignAll(snapshot.docs
          .map((doc) => doc['title']?.toString() ?? "Unnamed Task")
          .toList());
    });

    // Fetch pending tasks
    _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      pendingTasks.value = snapshot.size;
      pendingTaskTitles.assignAll(snapshot.docs
          .map((doc) => doc['title']?.toString() ?? "Unnamed Task")
          .toList());
    });
  }
}
