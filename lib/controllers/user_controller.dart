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

  @override
  void onClose() {
    super.onClose();
    reporters.clear();
    cameramen.clear();
    allUsers.clear(); // ✅ Clear the lists when the controller is disposed
  }

  // ✅ Fetch all Reporters in real-time
  void fetchReporters() {
    try {
      reporters.bindStream(
        _firestore
            .collection("users")
            .where("role", isEqualTo: "Reporter")
            .snapshots()
            .map((snapshot) {
          return snapshot.docs.map((doc) {
            var data = doc.data();
            return {
              "id": doc.id,
              "name":
                  data["fullName"] ?? "Unknown", // ✅ Fallback for missing name
            };
          }).toList();
        }),
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch reporters. Please try again.");
      print("Error fetching reporters: $e");
    }
  }

  // ✅ Fetch all Cameramen in real-time
  void fetchCameramen() {
    try {
      cameramen.bindStream(
        _firestore
            .collection("users")
            .where("role", isEqualTo: "Cameraman")
            .snapshots()
            .map((snapshot) {
          return snapshot.docs.map((doc) {
            var data = doc.data();
            return {
              "id": doc.id,
              "name":
                  data["fullName"] ?? "Unknown", // ✅ Fallback for missing name
            };
          }).toList();
        }),
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch cameramen. Please try again.");
      print("Error fetching cameramen: $e");
    }
  }

  // ✅ Fetch all users (excluding self) for Admin, Editors & HoDs
  void fetchAllUsers() {
    try {
      String currentUserId = authController.auth.currentUser?.uid ?? "";
      String currentUserRole = authController.userRole.value;

      if (_isAdminOrEditor(currentUserRole)) {
        allUsers.bindStream(
          _firestore.collection("users").snapshots().map((snapshot) {
            return snapshot.docs
                .where((doc) => doc.id != currentUserId) // ✅ Exclude self
                .map((doc) {
              var data = doc.data();
              return {
                "id": doc.id,
                "name": data["fullName"] ??
                    "Unknown", // ✅ Fallback for missing name
                "role":
                    data["role"] ?? "Unknown", // ✅ Fallback for missing role
              };
            }).toList();
          }),
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch users. Please try again.");
      print("Error fetching users: $e");
    }
  }

  // ✅ Helper method to check if a role is Admin, Editor, or HoD
  bool _isAdminOrEditor(String role) {
    const validRoles = ["Admin", "Assignment Editor", "Head of Department"];
    return validRoles.contains(role);
  }
}
