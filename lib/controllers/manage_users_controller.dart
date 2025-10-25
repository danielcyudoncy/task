// controllers/manage_users_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/service/user_deletion_service.dart';
import 'package:task/utils/snackbar_utils.dart';
import 'package:task/controllers/auth_controller.dart';

class ManageUsersController extends GetxController {
  final UserDeletionService userDeletionService;

  ManageUsersController(this.userDeletionService);

  void _safeSnackbar(String title, String message) {
    SnackbarUtils.showSnackbar(title, message);
  }

  var isLoading = false.obs;
  var isDeletingUser = false.obs;
  var usersList = <Map<String, dynamic>>[].obs;
  var filteredUsersList = <Map<String, dynamic>>[].obs;
  var selectedRole = 'All'.obs;
  var currentSearchQuery = ''.obs;
  var tasksList = <Map<String, dynamic>>[].obs;
  var isHovered = <bool>[].obs;
  var assignedTasks = <String, List<String>>{}.obs;
  StreamSubscription<QuerySnapshot>? _usersStream;

  late ScrollController _scrollController;
  ScrollController get scrollController => _scrollController;

  @override
  void onInit() {
    super.onInit();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    isHovered.assignAll(List.filled(usersList.length, false));

    // Listen to auth state changes
    ever(AuthController.to.user, (User? user) {
      if (user != null) {
        _initUsersStream();
        fetchTasks();
      } else {
        // Cancel stream if exists
        _usersStream?.cancel();
        _usersStream = null;
        usersList.clear();
        filteredUsersList.clear();
      }
    });

    // Initialize if already authenticated
    if (AuthController.to.currentUser != null) {
      _initUsersStream();
      fetchTasks();
    }
  }

  @override
  void onClose() {
    _scrollController.dispose();
    super.onClose();
  }

  void _initUsersStream() {
    // Cancel existing stream if any
    _usersStream?.cancel();

    // Listen for real-time updates from Firestore
    _usersStream = FirebaseFirestore.instance.collection('users').snapshots().listen((snapshot) async {
      // Check if user is still authenticated
      if (AuthController.to.currentUser == null) {
        debugPrint('[ManageUsersController] User not authenticated, skipping update');
        return;
      }
      isLoading.value = true;
      debugPrint(
          '[ManageUsersController] Firestore user snapshot received: ${snapshot.docs.length} docs');
      final newUsers = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final photoUrl = data['photoUrl'] ??
            data['photoURL'] ??
            data['profilePic'] ??
            data['profile_pic'] ??
            data['avatarUrl'] ??
            data['avatar_url'] ??
            '';

        final assignedTasksSnapshot =
            await doc.reference.collection('assignedTasks').get();
        final taskIds =
            assignedTasksSnapshot.docs.map((taskDoc) => taskDoc.id).toList();
        assignedTasks[doc.id] = taskIds;

        debugPrint(
            '[ManageUsersController] User loaded: id=${doc.id}, name=${data['fullName'] ?? data['fullname']}, role=${data['role']}');

        return {
          'uid': doc.id,
          'id': doc.id,
          'fullName': data['fullName'] ?? data['fullname'] ?? 'Unknown User',
          'fullname': data['fullName'] ?? data['fullname'] ?? 'Unknown User',
          'role': data['role'] ?? 'No Role',
          'email': data['email'] ?? 'No Email',
          'photoUrl': photoUrl,
          'hasTask': taskIds.isNotEmpty,
        };
      }));

      final filteredNewUsers = newUsers
          .where(
              (user) => user['role'] != 'Librarian' && user['role'] != 'Admin')
          .toList();

      debugPrint(
          '[ManageUsersController] Filtered users count: ${filteredNewUsers.length}');
      usersList.value = filteredNewUsers;
      filteredUsersList.assignAll(usersList);
      isHovered.assignAll(List.filled(usersList.length, false));
      isLoading.value = false;
    });
  }

  Future<void> fetchTasks() async {
    if (AuthController.to.currentUser == null) {
      return; // Don't fetch if not authenticated
    }
    try {
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
    } catch (e) {
      _safeSnackbar('Error', 'Failed to fetch tasks: $e');
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
      _safeSnackbar('Success', 'Task assigned successfully');
    } catch (e) {
      _safeSnackbar('Error', 'Failed to assign task: ${e.toString()}');
    }
  }

  Future<bool> deleteUser(String userId) async {
    if (isDeletingUser.value) {
      _safeSnackbar('Warning', 'Another deletion is in progress');
      return false;
    }

    final userToDelete =
        usersList.firstWhereOrNull((user) => user['uid'] == userId);
    if (userToDelete == null) {
      _safeSnackbar('Error', 'User not found');
      return false;
    }

    bool? confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to delete ${userToDelete['fullName']}?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    final backupUsersList = List<Map<String, dynamic>>.from(usersList);
    final backupFilteredList =
        List<Map<String, dynamic>>.from(filteredUsersList);

    try {
      isDeletingUser.value = true;

      usersList.removeWhere((user) => user['uid'] == userId);
      filteredUsersList.removeWhere((user) => user['uid'] == userId);
      isHovered.assignAll(List.filled(usersList.length, false));

      await userDeletionService.deleteUserByAdmin(userId);

      _safeSnackbar(
        'Success',
        'User ${userToDelete['fullName']} deleted successfully',
      );
      return true;
    } catch (e) {
      usersList.assignAll(backupUsersList);
      filteredUsersList.assignAll(backupFilteredList);
      isHovered.assignAll(List.filled(usersList.length, false));

      String errorMessage = 'Failed to delete user';
      if (e.toString().contains('Insufficient permissions')) {
        errorMessage = 'You do not have permission to delete users';
      } else if (e.toString().contains('Cloud function')) {
        errorMessage = 'Server error: Unable to delete user account';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error: Please check your connection';
      }

      _safeSnackbar('Error', errorMessage);
      return false;
    } finally {
      isDeletingUser.value = false;
    }
  }

  Future<void> promoteToAdmin(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'role': 'admin'});
      _safeSnackbar('Success', 'User promoted to admin');
      int idx =
          usersList.indexWhere((u) => u['id'] == userId || u['uid'] == userId);
      if (idx != -1) {
        usersList[idx]['role'] = 'admin';
        filteredUsersList.assignAll(usersList);
      }
    } catch (e) {
      _safeSnackbar('Error', 'Promotion failed: ${e.toString()}');
    }
  }

  void searchUsers(String query) {
    currentSearchQuery.value = query;
    List<Map<String, dynamic>> baseList;

    // First apply role filter
    if (selectedRole.value == 'All') {
      baseList = usersList
          .where(
              (user) => user['role'] != 'Librarian' && user['role'] != 'Admin')
          .toList();
    } else {
      baseList = usersList
          .where((user) =>
              user['role'] == selectedRole.value &&
              user['role'] != 'Librarian' &&
              user['role'] != 'Admin')
          .toList();
    }

    // Then apply search filter on the role-filtered list
    if (query.isEmpty) {
      filteredUsersList.assignAll(baseList);
    } else {
      filteredUsersList.assignAll(
        baseList
            .where((user) =>
                user['fullname'].toLowerCase().contains(query.toLowerCase()) ||
                user['email'].toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );
    }
  }

  void updateHoverState(int index, bool value) {
    if (index >= 0 && index < isHovered.length) {
      isHovered[index] = value;
    }
  }

  Future<int> getTotalUserCount() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').count().get();
      return snapshot.count ?? usersList.length;
    } catch (e) {
      return usersList.length;
    }
  }

  void _scrollListener() {
    // Pagination is no longer needed; user list updates in real time via Firestore stream.
  }

  void filterByRole(String? role) {
    selectedRole.value = role ?? 'All';
    // Trigger search with current query to apply both role and search filters
    searchUsers(currentSearchQuery.value);
  }
}
