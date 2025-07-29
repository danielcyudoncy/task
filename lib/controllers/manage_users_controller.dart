// controllers/manage_users_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/service/user_deletion_service.dart';
import 'package:task/utils/snackbar_utils.dart';

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
  var tasksList = <Map<String, dynamic>>[].obs;
  DocumentSnapshot? lastDocument;
  var hasMoreUsers = true.obs;
  var isHovered = <bool>[].obs;
  final int usersLimit = 15;
  var isOrdered = false.obs;

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

  Future<bool> fetchUsers(
      {bool isNextPage = false, bool fetchAll = false}) async {
    if (!hasMoreUsers.value || isLoading.value) return false;
    bool ordered = false;

    try {
      isLoading.value = true;
      Query query;

      try {
        query =
            FirebaseFirestore.instance.collection('users').orderBy('fullName');
        await query.limit(1).get();
        ordered = true;
      } catch (_) {
        try {
          query = FirebaseFirestore.instance
              .collection('users')
              .orderBy('fullname');
          await query.limit(1).get();
          ordered = true;
        } catch (_) {
          query = FirebaseFirestore.instance.collection('users');
        }
      }

      isOrdered.value = ordered;

      if (!fetchAll) {
        query = query.limit(usersLimit);
        if (isNextPage && lastDocument != null) {
          query = query.startAfterDocument(lastDocument!);
        }
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final newUsers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
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

    return ordered;
  }

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
