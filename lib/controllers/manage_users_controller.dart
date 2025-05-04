// controllers/manage_users_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManageUsersController extends GetxController {
  var isLoading = false.obs;
  var usersList = <Map<String, dynamic>>[].obs;
  var filteredUsersList =
      <Map<String, dynamic>>[].obs; // Filtered list for search
  var lastDocument; // To store the last fetched document for pagination
  var hasMoreUsers = true.obs;

  ScrollController get scrollController => _scrollController;
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

  Future<void> fetchUsers() async {
  try {
    isLoading.value = true;
    print("Fetching users from Firebase...");

    // Fetch all user documents from Firestore
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    print("Fetched ${snapshot.docs.length} users from Firebase");

    if (snapshot.docs.isNotEmpty) {
      // Map each document to a user object with proper fallback values
      usersList.value = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Debug: Print the raw data fetched from Firestore
        print("User Data: $data");

        return {
          'id': doc.id,
          'fullname': data['fullName'] ?? 'Unknown User', // Correct field name
          'role': data['role'] ?? 'No Role',
          'email': data['email'] ?? 'No Email', // Added email for search
        };
      }).toList();

      // Set the filtered list to the full list initially
      filteredUsersList.assignAll(usersList);
    } else {
      print("No users found in Firebase");
      usersList.clear();
      filteredUsersList.clear();
    }
  } catch (e) {
    print("Error fetching users: $e");
  } finally {
    isLoading.value = false;
  }
}
  // ✅ Delete a user from Firestore
  Future<bool> deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      usersList.removeWhere((user) => user['id'] == userId);
      filteredUsersList.removeWhere(
          (user) => user['id'] == userId); // Remove from filtered list

      return true;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }

  // ✅ Search users
  void searchUsers(String query) {
    if (query.isEmpty) {
      filteredUsersList
          .assignAll(usersList); // Reset to full list if query is empty
    } else {
      filteredUsersList.assignAll(
        usersList
            .where((user) =>
                user['fullname'].toLowerCase().contains(query.toLowerCase()) ||
                user['email'].toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );
    }
  }

  // Handle the scroll to trigger fetch more users when reaching the bottom
  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      fetchUsers(); // Fetch more users when scrolled to the bottom
    }
  }

  // manage_users_controller.dart
Future<void> promoteToAdmin(String userId) async {
  try {
    // 1. Set admin claim
    // Setting custom claims is not supported in FirebaseAuth for Flutter.
    // This operation should be handled on the server side using Firebase Admin SDK.
    print('Custom claims must be set using Firebase Admin SDK on the server.');

    // 2. Update Firestore role
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'role': 'admin'});

    Get.snackbar('Success', 'User promoted to admin');
  } catch (e) {
    Get.snackbar('Error', 'Promotion failed: ${e.toString()}');
  }
}
}
