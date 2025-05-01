// views/users_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/manage_users_controller.dart'; // Import ManageUsersController

class UserScreen extends StatelessWidget {
  UserScreen({super.key});

  final AuthController auth = Get.find<AuthController>();
  final UserController userController = Get.find<UserController>();
  final ManageUsersController manageUsersController =
      Get.find<ManageUsersController>(); // Initialize the controller

  final RxString selectedTask = ''.obs; // Track selected task
  final RxString selectedUser =
      ''.obs; // Track selected user (for task assignment)
  final RxString selectedManagedUser =
      ''.obs; // Track selected user (for manage users)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Screen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display User Info
            Text('Welcome, ${auth.fullNameController.text}'),

            const SizedBox(height: 20),

            // 1. **User Role Check for Assignment Editor**
            if (auth.userRole.value == 'Assignment Editor')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // **Task Dropdown**
                  DropdownButtonFormField<String>(
                    value: selectedTask.value.isEmpty
                        ? null
                        : selectedTask.value, // Dynamically bind task
                    items: [
                      'Task 1',
                      'Task 2',
                      'Task 3'
                    ] // Replace with actual task list
                        .map((task) {
                      return DropdownMenuItem<String>(
                        value: task,
                        child: Text(task),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: 'Select Task',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      selectedTask.value = value ?? ''; // Update selected task
                    },
                  ),
                  const SizedBox(height: 20),

                  // **User Dropdown**
                  Obx(() {
                    if (userController.allUsers.isEmpty) {
                      return const Text("No users available");
                    }
                    return DropdownButtonFormField<String>(
                      value: selectedUser.value.isEmpty
                          ? null
                          : selectedUser.value, // Dynamically bind user
                      items: userController.allUsers.map((user) {
                        return DropdownMenuItem<String>(
                          value: user['id'],
                          child: Text(user['name']),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Assign To',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        selectedUser.value =
                            value ?? ''; // Update selected user
                      },
                    );
                  }),
                  const SizedBox(height: 20),

                  // **Assign Task Button**
                  Obx(() => auth.isLoading.value
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () {
                            if (selectedTask.value.isNotEmpty &&
                                selectedUser.value.isNotEmpty) {
                              // Call assignTask method when button is clicked
                              auth.assignTask(selectedTask.value,
                                  selectedUser.value); // Use actual values
                            } else {
                              Get.snackbar(
                                  'Error', 'Please select a task and a user');
                            }
                          },
                          child: const Text('Assign Task'),
                        )),
                ],
              ),
            const SizedBox(height: 20),

            // 2. **Manage Users Section**
            Obx(() {
              if (manageUsersController.usersList.isEmpty) {
                return const Text('No users to display');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manage Users'),
                  const SizedBox(height: 10),

                  // **User Dropdown for Managing Users**
                  DropdownButtonFormField<String>(
                    value: selectedManagedUser.value.isEmpty
                        ? null
                        : selectedManagedUser.value, // Bind selected user
                    items: manageUsersController.usersList.map((user) {
                      return DropdownMenuItem<String>(
                        value: user['id'],
                        child: Text(user['fullname']),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: 'Select User',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      selectedManagedUser.value =
                          value ?? ''; // Update selected user
                    },
                  ),
                  const SizedBox(height: 20),

                  // **Manage User Actions**
                  Obx(() => ElevatedButton(
                        onPressed: () {
                          if (selectedManagedUser.value.isNotEmpty) {
                            // Perform action for the selected user
                            manageUsersController
                                .deleteUser(selectedManagedUser.value);
                            Get.snackbar(
                                'Success', 'User deleted successfully');
                          } else {
                            Get.snackbar(
                                'Error', 'Please select a user to manage');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Delete User'),
                      )),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
