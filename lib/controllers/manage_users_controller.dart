// controllers/manage_users_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/service/user_deletion_service.dart';
import 'package:task/utils/snackbar_utils.dart';

class ManageUsersController extends GetxController {
  final UserDeletionService userDeletionService;

  ManageUsersController(this.userDeletionService);

  // Safe snackbar method
  void _safeSnackbar(String title, String message) {
    SnackbarUtils.showSnackbar(title, message);
  }

  // Observables
  var isLoading = false.obs;
  var isDeletingUser = false.obs; // Separate loading state for deletion
  var usersList = <Map<String, dynamic>>[].obs;
  var filteredUsersList = <Map<String, dynamic>>[].obs;
  var selectedRole = 'All'.obs;
  var tasksList = <Map<String, dynamic>>[].obs;
  DocumentSnapshot? lastDocument;
  var hasMoreUsers = true.obs;
  var isHovered = <bool>[].obs;
  final int usersLimit = 15;

  late ScrollController _scrollController;
  ScrollController get scrollController => _scrollController;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
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
  Future<void> fetchUsers({bool isNextPage = false, bool fetchAll = false}) async {
    if (!hasMoreUsers.value || isLoading.value) return;
    try {
      isLoading.value = true;
      Query query;
      bool ordered = false;
      // Try ordering by 'fullName', then 'fullname', then no order
      try {
        query = FirebaseFirestore.instance.collection('users').orderBy('fullName');
        await query.limit(1).get(); // test if field exists
        ordered = true;
        print('fetchUsers: ordering by fullName');
      } catch (_) {
        try {
          query = FirebaseFirestore.instance.collection('users').orderBy('fullname');
          await query.limit(1).get();
          ordered = true;
          print('fetchUsers: ordering by fullname');
        } catch (_) {
          query = FirebaseFirestore.instance.collection('users');
          print('fetchUsers: no ordering');
        }
      }

      // If fetching all users for dialog, don't use pagination
      if (!fetchAll) {
        query = query.limit(usersLimit);
        if (isNextPage && lastDocument != null) {
          query = query.startAfterDocument(lastDocument as DocumentSnapshot);
        }
      }

      QuerySnapshot snapshot = await query.get();
      print('fetchUsers: snapshot.docs.length =  [32m${snapshot.docs.length} [0m');
      for (var doc in snapshot.docs) {
        print('fetchUsers: user doc =  [32m${doc.data()} [0m');
      }

      if (snapshot.docs.isNotEmpty) {
        final newUsers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Try multiple possible field names for profile picture
          final photoUrl = data['photoUrl'] ?? 
                          data['photoURL'] ?? 
                          data['profilePic'] ?? 
                          data['profile_pic'] ?? 
                          data['avatarUrl'] ?? 
                          data['avatar_url'] ?? 
                          '';
          return {
            'uid': doc.id,
            'id': doc.id,
            'fullName': data['fullName'] ?? data['fullname'] ?? 'Unknown User',
            'fullname': data['fullName'] ?? data['fullname'] ?? 'Unknown User',
            'role': data['role'] ?? 'No Role',
            'email': data['email'] ?? 'No Email',
            'photoUrl': photoUrl,
          };
        }).toList();

        if (isNextPage && !fetchAll) {
          usersList.addAll(newUsers);
        } else {
          usersList.value = newUsers;
        }

        filteredUsersList.assignAll(usersList);
        isHovered.assignAll(List.filled(usersList.length, false));

        if (!fetchAll) {
          lastDocument = snapshot.docs.last;
          if (snapshot.docs.length < usersLimit) hasMoreUsers.value = false;
        }
      } else {
        hasMoreUsers.value = false;
      }
    } catch (e) {
      _safeSnackbar('Error', 'Failed to fetch users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch all tasks for assignment
  Future<void> fetchTasks() async {
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

  /// Assign a task to a user
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

  /// Enhanced delete user method with better error handling
  Future<bool> deleteUser(String userId) async {
    // Prevent multiple simultaneous deletions
    if (isDeletingUser.value) {
      _safeSnackbar('Warning', 'Another deletion is in progress');
      return false;
    }

    // Find user to delete
    final userToDelete =
        usersList.firstWhereOrNull((user) => user['uid'] == userId);
    if (userToDelete == null) {
      _safeSnackbar('Error', 'User not found');
      return false;
    }

    // Confirm deletion
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

    // Create backups
    final backupUsersList = List<Map<String, dynamic>>.from(usersList);
    final backupFilteredList =
        List<Map<String, dynamic>>.from(filteredUsersList);

    try {
      isDeletingUser.value = true;

      // Optimistic UI update
      usersList.removeWhere((user) => user['uid'] == userId);
      filteredUsersList.removeWhere((user) => user['uid'] == userId);
      isHovered.assignAll(List.filled(usersList.length, false));

      // Perform actual deletion
      await userDeletionService.deleteUserByAdmin(userId);

      _safeSnackbar(
        'Success',
        'User ${userToDelete['fullName']} deleted successfully',
      );
      return true;
    } catch (e) {
      // Restore from backup if deletion failed
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

      _safeSnackbar(
        'Error',
        errorMessage,
      );
      return false;
    } finally {
      isDeletingUser.value = false;
    }
  }

  /// Promote user to admin
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

  /// Search by name or email
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

  /// Update hover state
  void updateHoverState(int index, bool value) {
    if (index >= 0 && index < isHovered.length) {
      isHovered[index] = value;
    }
  }

  /// Get total user count for dashboard
  Future<int> getTotalUserCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .count()
          .get();
      return snapshot.count ?? usersList.length;
    } catch (e) {
      return usersList.length; // Fallback to current list length
    }
  }

  /// Infinite scroll listener
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      fetchUsers(isNextPage: true);
    }
  }

  void filterByRole(String? role) {
    if (role == null || role == 'All') {
      filteredUsersList.assignAll(usersList);
      selectedRole.value = 'All';
    } else {
      filteredUsersList.assignAll(
        usersList.where((user) => user['role'] == role).toList(),
      );
      selectedRole.value = role;
    }
  }
}
