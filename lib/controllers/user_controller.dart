// controllers/user_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';

class UserController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authController = Get.find<AuthController>();

  var reporters = <Map<String, dynamic>>[].obs;
  var cameramen = <Map<String, dynamic>>[].obs;
  var allUsers = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchReporters();
    fetchCameramen();
    fetchAllUsers(); // ✅ Fetch all users for admin & editors
  }

  // ✅ Fetch all Reporters in real-time
  void fetchReporters() {
    reporters.bindStream(
      _firestore
          .collection("users")
          .where("role", isEqualTo: "Reporter")
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return {
            "id": doc.id,
            "name": doc["fullName"] ?? "Unknown",
          };
        }).toList();
      }),
    );
  }

  // ✅ Fetch all Cameramen in real-time
  void fetchCameramen() {
    cameramen.bindStream(
      _firestore
          .collection("users")
          .where("role", isEqualTo: "Cameraman")
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return {
            "id": doc.id,
            "name": doc["fullName"] ?? "Unknown",
          };
        }).toList();
      }),
    );
  }

  // ✅ Fetch all users (excluding self) for Admin, Editors & HoDs
  void fetchAllUsers() {
    String currentUserId = authController.auth.currentUser!.uid;
    String currentUserRole = authController.userRole.value;

    if (currentUserRole == "Admin" ||
        currentUserRole == "Assignment Editor" ||
        currentUserRole == "Head of Department") {
      allUsers.bindStream(
        _firestore.collection("users").snapshots().map((snapshot) {
          return snapshot.docs
              .where((doc) => doc.id != currentUserId) // ✅ Exclude self
              .map((doc) {
            return {
              "id": doc.id,
              "name": doc["fullName"] ?? "Unknown",
              "role": doc["role"] ?? "Unknown",
            };
          }).toList();
        }),
      );
    }
  }
}
