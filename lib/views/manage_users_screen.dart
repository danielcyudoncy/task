// views/manage_users_screen.dart
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
        title: const Text('Manage Users',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: const Color(0xFF0B189B),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (query) {
                manageUsersController
                    .searchUsers(query); // Implement search logic
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
              // Show loading spinner if loading and no users are available
              if (manageUsersController.isLoading.value &&
                  manageUsersController.usersList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Show message if no users are available
              if (manageUsersController.usersList.isEmpty) {
                return const Center(child: Text('No users available'));
              }

              // Build the list of users
              return ListView.builder(
                controller: manageUsersController.scrollController,
                itemCount: manageUsersController.usersList.length,
                itemBuilder: (context, index) {
                  final user = manageUsersController.usersList[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['fullname'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(user['email']),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B189B),
                                ),
                                onPressed: () {
                                  _showTaskListDialog(context, user);
                                },
                                child: const Text(
                                  'Assign Task',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  // Confirm before deleting the user
                                  final confirm = await Get.defaultDialog<bool>(
                                    title: "Delete User",
                                    middleText:
                                        "Are you sure you want to delete this user?",
                                    textCancel: "Cancel",
                                    textConfirm: "Delete",
                                    confirmTextColor: Colors.white,
                                    onConfirm: () => Get.back(result: true),
                                    onCancel: () => Get.back(result: false),
                                  );

                                  if (confirm == true) {
                                    final success = await manageUsersController
                                        .deleteUser(user['id']);
                                    if (success) {
                                      Get.snackbar('Success',
                                          'User deleted successfully',
                                          snackPosition: SnackPosition.BOTTOM);
                                    } else {
                                      Get.snackbar(
                                          'Error', 'Failed to delete user',
                                          snackPosition: SnackPosition.BOTTOM);
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // Function to show task list dialog
  void _showTaskListDialog(BuildContext context, Map<String, dynamic> user) {
    final tasks =
        manageUsersController.tasksList; // List of tasks from the controller

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Task'),
          content: SizedBox(
            height: 300,
            width: 300,
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
                            manageUsersController.assignTaskToUser(
                                user['id'], task['id']);
                            Navigator.pop(context); // Close the dialog
                            Get.snackbar(
                                'Success', 'Task assigned successfully',
                                snackPosition: SnackPosition.BOTTOM);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B189B),
                          ),
                          child: const Text('Assign',
                              style: TextStyle(color: Colors.white)),
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
}
