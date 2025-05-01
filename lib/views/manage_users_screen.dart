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
              color: Colors.white
            )),
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
                    child: ListTile(
                      title: Text(user['fullname']),
                      subtitle: Text(user['email']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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
                              Get.snackbar(
                                  'Success', 'User deleted successfully',
                                  snackPosition: SnackPosition.BOTTOM);
                            } else {
                              Get.snackbar('Error', 'Failed to delete user',
                                  snackPosition: SnackPosition.BOTTOM);
                            }
                          }
                        },
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
}
