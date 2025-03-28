// controllers/manage_users_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ManageUsersController extends GetxController {
  var isLoading = false.obs;
  var usersList = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void fetchUsers() async {
    isLoading.value = true;

    try {
      var snapshot = await FirebaseFirestore.instance.collection('users').get();

      usersList.value = snapshot.docs.map((doc) {
        var data = doc.data();

        return {
          'id': doc.id,
          'fullname': data.containsKey('fullname')
              ? data['fullname']
              : 'Unknown User', // ✅ Ensuring correct field
          'email': data['email'] ?? 'No Email'
        };
      }).toList();
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch users: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ Function to Delete User from Firestore
  void deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      usersList.removeWhere((user) => user['id'] == userId);
      Get.snackbar("Success", "User deleted successfully!");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete user: $e");
    }
  }
}
