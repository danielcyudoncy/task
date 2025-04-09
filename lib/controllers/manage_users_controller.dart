// controllers/manage_users_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ManageUsersController extends GetxController {
  var isLoading = false.obs;
  var usersList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers(); // Fetch users when the controller is initialized
  }

  @override
  void onClose() {
    super.onClose();
    usersList.clear(); // Clear users list when the controller is closed
  }

  // ✅ Fetch users from Firestore
  void fetchUsers() async {
    isLoading.value = true;

    try {
      // Fetch all users from the "users" collection
      var snapshot = await FirebaseFirestore.instance.collection('users').get();

      // Map Firestore documents to user data
      usersList.value = snapshot.docs.map((doc) {
        var data = doc.data();

        return {
          'id': doc.id,
          'fullname': data.containsKey('fullname')
              ? data['fullname']
              : 'Unknown User', // ✅ Fallback for missing fullname
          'email': data['email'] ?? 'No Email', // ✅ Fallback for missing email
        };
      }).toList();
    } catch (e) {
      // Log error and show user-friendly message
      Get.snackbar("Error", "Failed to fetch users. Please try again.");
      print("Error fetching users: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ Delete a user from Firestore
  void deleteUser(String userId) async {
    try {
      // Delete user document from Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // Update the local users list
      usersList.removeWhere((user) => user['id'] == userId);

      Get.snackbar("Success", "User deleted successfully.");
    } catch (e) {
      // Log error and show user-friendly message
      Get.snackbar("Error", "Failed to delete user. Please try again.");
      print("Error deleting user: $e");
    }
  }
}
