// controllers/manage_users_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManageUsersController extends GetxController {
  var isLoading = false.obs;
  var usersList = <Map<String, dynamic>>[].obs;
  var lastDocument; // To store the last fetched document for pagination
  var hasMoreUsers = true.obs;

  late ScrollController _scrollController;

  @override
  void onInit() {
    super.onInit();
    fetchUsers(); // Fetch users when the controller is initialized
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    _scrollController
        .dispose(); // Dispose the controller when it's no longer needed
    super.onClose();
  }

  // ✅ Fetch users from Firestore with pagination
  Future<void> fetchUsers({bool isNewSearch = false}) async {
    if (isLoading.value || !hasMoreUsers.value)
      return; // Prevent fetching if already loading or no more users

    isLoading.value = true;

    try {
      // Build query
      Query query = FirebaseFirestore.instance
          .collection('users')
          .orderBy('fullname') // You can change this to any field you prefer
          .limit(20); // Fetch 20 users per query

      // If there's a last document, start fetching after it
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      var snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        // Update the last document for the next fetch
        lastDocument = snapshot.docs.last;

        // Add fetched users to the list
        usersList.addAll(snapshot.docs.map((doc) {
          var data = doc.data()
              as Map<String, dynamic>?; // Safe cast to Map<String, dynamic>

          // Ensure data is not null and handle missing fields
          return {
            'id': doc.id,
            'fullname': data?['fullname'] ?? 'Unknown User',
            'email': data?['email'] ?? 'No Email',
          };
        }).toList());
      } else {
        hasMoreUsers.value = false; // No more users to fetch
      }
    } catch (e) {
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
      Get.snackbar("Error", "Failed to delete user. Please try again.");
      print("Error deleting user: $e");
    }
  }

  // Handle the scroll to trigger fetch more users when reaching the bottom
  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      fetchUsers(); // Fetch more users when scrolled to the bottom
    }
  }
}
