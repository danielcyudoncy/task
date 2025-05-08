import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manage_users_controller.dart';

class ManageUsersScreen extends StatelessWidget {
  final ManageUsersController manageUsersController = Get.find();

  ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Users',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0B189B),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (query) {
                manageUsersController.searchUsers(query);
              },
              decoration: const InputDecoration(
                labelText: 'Search Users',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // User List
          Expanded(
            child: Obx(() {
              if (manageUsersController.isLoading.value && manageUsersController.usersList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (manageUsersController.usersList.isEmpty) {
                return const Center(child: Text('No users available'));
              }
              return ListView.builder(
                controller: manageUsersController.scrollController,
                itemCount: manageUsersController.usersList.length,
                itemBuilder: (context, index) {
                  final user = manageUsersController.usersList[index];
                  return _buildHoverCard(context, user, index);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHoverCard(BuildContext context, Map<String, dynamic> user, int index) {
    return MouseRegion(
      onEnter: (event) => manageUsersController.updateHoverState(index, true),
      onExit: (event) => manageUsersController.updateHoverState(index, false),
      child: Obx(() {
        final isHovered = manageUsersController.isHovered[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (isHovered)
                const BoxShadow(
                  color: Colors.grey,
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: Text(
                _getInitials(user['fullname']),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              user['fullname'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Role: ${user['role']}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.assignment, color: Colors.blue),
                  onPressed: () {
                    _showTaskListDialog(context, user);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await Get.defaultDialog<bool>(
                      title: "Delete User",
                      middleText: "Are you sure you want to delete this user?",
                      textCancel: "Cancel",
                      textConfirm: "Delete",
                      confirmTextColor: Colors.white,
                      onConfirm: () => Get.back(result: true),
                      onCancel: () => Get.back(result: false),
                    );
                    if (confirm == true) {
                      final success = await manageUsersController.deleteUser(user['id']);
                      if (success) {
                        manageUsersController.usersList.removeAt(index);
                        Get.snackbar('Success', 'User deleted successfully',
                            snackPosition: SnackPosition.BOTTOM);
                      } else {
                        Get.snackbar('Error', 'Failed to delete user',
                            snackPosition: SnackPosition.BOTTOM);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

void _showTaskListDialog(BuildContext context, Map<String, dynamic> user) {
  final tasks = manageUsersController.tasksList;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        scrollable: true,
        title: const Text('Assign Task'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: tasks.isEmpty
              ? const Center(child: Text('No tasks available'))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      title: Text(task['title']),
                      trailing: ElevatedButton(
                        onPressed: () {
                          manageUsersController.assignTaskToUser(user['id'], task['id']);
                          Navigator.pop(context);
                          Get.snackbar('Success', 'Task assigned successfully',
                              snackPosition: SnackPosition.BOTTOM);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B189B),
                        ),
                        child: const Text('Assign', style: TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}


  String _getInitials(String fullname) {
    if (fullname.isEmpty) return "?";
    final names = fullname.split(" ");
    if (names.length == 1) {
      return names.first.substring(0, 1).toUpperCase();
    } else {
      return names[0].substring(0, 1).toUpperCase() + names[1].substring(0, 1).toUpperCase();
    }
  }
}