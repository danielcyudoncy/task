// controllers/user_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task/service/user_deletion_service.dart';
import '../controllers/auth_controller.dart';
// <-- Add this import

class UserController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authController = Get.find<AuthController>();
  final UserDeletionService userDeletionService; // <-- Inject the service

  UserController(
      this.userDeletionService); // <-- Require the service in constructor

  var reporters = <Map<String, dynamic>>[].obs;
  var cameramen = <Map<String, dynamic>>[].obs;
  var allUsers = <Map<String, dynamic>>[].obs;
  var isDeleting = false.obs; // <-- New: For UI feedback

  @override
  void onInit() {
    super.onInit();
    fetchReporters();
    fetchCameramen();
    fetchAllUsers();
  }

  @override
  void onClose() {
    super.onClose();
    reporters.clear();
    cameramen.clear();
    allUsers.clear();
  }

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
              "name": data["fullName"] ?? "Unknown",
            };
          }).toList();
        }),
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch reporters. Please try again.");
    }
  }

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
              "name": data["fullName"] ?? "Unknown",
            };
          }).toList();
        }),
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch cameramen. Please try again.");
    }
  }

  void fetchAllUsers() {
    try {
      String currentUserId = authController.auth.currentUser?.uid ?? "";
      String currentUserRole = authController.userRole.value;

      if (_isAdminOrEditor(currentUserRole)) {
        allUsers.bindStream(
          _firestore.collection("users").snapshots().map((snapshot) {
            return snapshot.docs
                .where((doc) => doc.id != currentUserId)
                .map((doc) {
              var data = doc.data();
              return {
                "id": doc.id,
                "name": data["fullName"] ?? "Unknown",
                "role": data["role"] ?? "Unknown",
              };
            }).toList();
          }),
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch users. Please try again.");
    }
  }

  bool _isAdminOrEditor(String role) {
    const validRoles = ["Admin", "Assignment Editor", "Head of Department"];
    return validRoles.contains(role);
  }

  // ------- NEW: User Deletion Method -------
  Future<void> deleteUser(String uid) async {
    isDeleting.value = true;
    try {
      await userDeletionService.deleteUserByAdmin(uid);
      // Optionally remove the user from the list for immediate UI update
      allUsers.removeWhere((user) => user["id"] == uid);
      Get.snackbar("Success", "User deleted!");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete user: $e");
    } finally {
      isDeleting.value = false;
    }
  }
}
