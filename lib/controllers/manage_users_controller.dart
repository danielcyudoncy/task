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

  // ✅ Fetch users from Firestore with pagination
  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      print("Fetching users from Firebase...");

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(
              'users') // Ensure this matches your Firebase collection name
          .get();

      print("Fetched ${snapshot.docs.length} users from Firebase");

      if (snapshot.docs.isNotEmpty) {
        usersList.value = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          print("User Data: ${data}"); // Debug print
          return {
            'id': doc.id,
            'fullname': data['fullname'] ?? 'Unknown User',
            'role': data['role'] ?? 'No Role',
          };
        }).toList();
      } else {
        print("No users found in Firebase");
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
}
