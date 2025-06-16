// controllers/manage_users_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/service/user_deletion_service.dart';


class ManageUsersController extends GetxController {
  final UserDeletionService userDeletionService;

  ManageUsersController(this.userDeletionService);

  // Observables
  var isLoading = false.obs;
  var usersList = <Map<String, dynamic>>[].obs;
  var filteredUsersList = <Map<String, dynamic>>[].obs;
  var tasksList = <Map<String, dynamic>>[].obs;
  DocumentSnapshot? lastDocument; // For pagination
  var hasMoreUsers = true.obs;
  var isHovered = <bool>[].obs;
  final int usersLimit = 15; // Page size

  late ScrollController _scrollController;
  ScrollController get scrollController => _scrollController;

  @override
  void onInit() {
    super.onInit();
    fetchUsers(); // Initial page
    fetchTasks();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    isHovered.assignAll(List.filled(usersList.length, false));
  }

  @override
  void onClose() {
    _scrollController.dispose();
    super.onClose();
  }

  /// Fetch users with pagination.
  Future<void> fetchUsers({bool isNextPage = false}) async {
    if (!hasMoreUsers.value || isLoading.value) return;
    try {
      isLoading.value = true;

      Query query = FirebaseFirestore.instance
          .collection('users')
          .orderBy('fullName')
          .limit(usersLimit);

      if (isNextPage && lastDocument != null) {
        query = query.startAfterDocument(lastDocument as DocumentSnapshot);
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final newUsers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'uid': doc.id,
            'fullname': data['fullName'] ?? 'Unknown User',
            'role': data['role'] ?? 'No Role',
            'email': data['email'] ?? 'No Email',
          };
        }).toList();

        if (isNextPage) {
          usersList.addAll(newUsers);
        } else {
          usersList.value = newUsers;
        }

        // Keep filtered in sync
        filteredUsersList.assignAll(usersList);

        // Update isHovered for new items
        isHovered.assignAll(List.filled(usersList.length, false));

        lastDocument = snapshot.docs.last;
        if (snapshot.docs.length < usersLimit) hasMoreUsers.value = false;
      } else {
        hasMoreUsers.value = false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch all tasks for assignment
  Future<void> fetchTasks() async {
    try {
      isLoading.value = true;
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('tasks').get();
      if (snapshot.docs.isNotEmpty) {
        tasksList.value = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Untitled Task',
          };
        }).toList();
      } else {
        tasksList.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Assign a task to a user (creates/overwrites under assignedTasks)
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

  /// Remove user from Firestore and Auth (via service)
  Future<bool> deleteUser(String userId) async {
    try {
      await userDeletionService.deleteUserByAdmin(userId);
      usersList
          .removeWhere((user) => user['id'] == userId || user['uid'] == userId);
      filteredUsersList.assignAll(usersList);
      isHovered.assignAll(List.filled(usersList.length, false));
      Get.snackbar('Success', 'User deleted successfully');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete user: $e');
      return false;
    }
  }

  /// Promote user to admin (Firestore only; use Admin SDK for real custom claims)
  Future<void> promoteToAdmin(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'role': 'admin'});
      Get.snackbar('Success', 'User promoted to admin');
      int idx =
          usersList.indexWhere((u) => u['id'] == userId || u['uid'] == userId);
      if (idx != -1) {
        usersList[idx]['role'] = 'admin';
        filteredUsersList.assignAll(usersList);
      }
    } catch (e) {
      Get.snackbar('Error', 'Promotion failed: ${e.toString()}');
    }
  }

  /// Search by name or email in the current loaded users
  void searchUsers(String query) {
    if (query.isEmpty) {
      filteredUsersList.assignAll(usersList);
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

  /// Update hover state (useful for web/desktop UI)
  void updateHoverState(int index, bool value) {
    if (index >= 0 && index < isHovered.length) {
      isHovered[index] = value;
    }
  }

  /// Infinite scroll: loads next page if not loading/finished and scrolled near bottom
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      fetchUsers(isNextPage: true);
    }
  }
}
