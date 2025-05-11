import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManageUsersController extends GetxController {
  var isLoading = false.obs;
  var usersList = <Map<String, dynamic>>[].obs;
  var filteredUsersList = <Map<String, dynamic>>[].obs; // Filtered list for search
  var tasksList = <Map<String, dynamic>>[].obs; // Task list for assigning tasks
  var lastDocument; // To store the last fetched document for pagination
  var hasMoreUsers = true.obs;
  var isHovered = <bool>[].obs;

  ScrollController get scrollController => _scrollController;
  late ScrollController _scrollController;

  @override
  void onInit() {
    super.onInit();
    fetchUsers(); // Fetch users when the controller is initialized
    fetchTasks(); // Fetch tasks when the controller is initialized
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    isHovered.assignAll(List.filled(usersList.length, false));
  }

  @override
  void onClose() {
    _scrollController.dispose(); // Dispose the controller when it's no longer needed
    super.onClose();
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      print("Fetching users from Firebase...");

      // Fetch all user documents from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();

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

        // Initialize `isHovered` with the correct length
        isHovered.assignAll(List.filled(usersList.length, false));
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

  // New: Fetch tasks from Firestore
  Future<void> fetchTasks() async {
    try {
      isLoading.value = true;
      print("Fetching tasks from Firebase...");

      // Fetch all task documents from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('tasks').get();

      print("Fetched ${snapshot.docs.length} tasks from Firebase");

      if (snapshot.docs.isNotEmpty) {
        // Map each document to a task object
        tasksList.value = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Debug: Print the raw task data fetched from Firestore
          print("Task Data: $data");

          return {
            'id': doc.id,
            'title': data['title'] ?? 'Untitled Task',
          };
        }).toList();
      } else {
        print("No tasks found in Firebase");
        tasksList.clear();
      }
    } catch (e) {
      print("Error fetching tasks: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> assignTaskToUser(String userId, String taskId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('assignedTasks')
          .doc(taskId)
          .set({'taskId': taskId});

      Get.snackbar('Success', 'Task assigned successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to assign task: ${e.toString()}');
    }
  }

  void updateHoverState(int index, bool value) {
    if (index >= 0 && index < isHovered.length) {
      isHovered[index] = value;
      print("isHovered[$index] = $value");
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      usersList.removeWhere((user) => user['id'] == userId);
      filteredUsersList.removeWhere((user) => user['id'] == userId); // Remove from filtered list

      return true;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      filteredUsersList.assignAll(usersList); // Reset to full list if query is empty
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

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      fetchUsers(); // Fetch more users when scrolled to the bottom
    }
  }

  Future<void> promoteToAdmin(String userId) async {
    try {
      print('Custom claims must be set using Firebase Admin SDK on the server.');

      // Update Firestore role
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'role': 'admin'});

      Get.snackbar('Success', 'User promoted to admin');
    } catch (e) {
      Get.snackbar('Error', 'Promotion failed: ${e.toString()}');
    }
  }
}