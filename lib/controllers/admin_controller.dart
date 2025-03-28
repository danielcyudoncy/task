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
    fetchAdminDetails(); // Fetch admin name & profile picture
    fetchDashboardStats(); // Fetch real-time dashboard stats
  }

  // ✅ Fetch Admin's Name & Photo from Firestore
  void fetchAdminDetails() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentSnapshot adminSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (adminSnapshot.exists) {
        adminName.value = adminSnapshot['name'] ?? "Admin";
        adminPhotoUrl.value = adminSnapshot['photoUrl'] ?? "";
      }
    }
  }

  // ✅ Fetch Real-Time Dashboard Stats
  void fetchDashboardStats() {
    // Total Users Count
    _firestore.collection('users').snapshots().listen((snapshot) {
      totalUsers.value = snapshot.size;
    });

    // Total Tasks Count
    _firestore.collection('tasks').snapshots().listen((snapshot) {
      totalTasks.value = snapshot.size;
      taskTitles.assignAll(snapshot.docs.map((doc) => doc['title'].toString()));
    });

    // Completed Tasks Count
    _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snapshot) {
      completedTasks.value = snapshot.size;
      completedTaskTitles
          .assignAll(snapshot.docs.map((doc) => doc['title'].toString()));
    });

    // Pending Tasks Count
    _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      pendingTasks.value = snapshot.size;
      pendingTaskTitles
          .assignAll(snapshot.docs.map((doc) => doc['title'].toString()));
    });
  }
}
