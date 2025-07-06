// views/users_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/widgets/user_nav_bar.dart';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/manage_users_controller.dart';

class UserScreen extends StatelessWidget {
  UserScreen({super.key});

  final AuthController auth = Get.find<AuthController>();
  final UserController userController = Get.find<UserController>();
  final ManageUsersController manageUsersController =
      Get.find<ManageUsersController>();

  final RxString selectedTask = ''.obs;
  final RxString selectedUser = ''.obs;
  final RxString selectedManagedUser = ''.obs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('User Screen')),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Theme.of(context).colorScheme.primary,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Welcome, ${auth.fullNameController.text}',
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              if (auth.userRole.value == 'Assignment Editor')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedTask.value.isEmpty
                          ? null
                          : selectedTask.value,
                      items: ["Task 1", "Task 2", "Task 3"].map((task) {
                        return DropdownMenuItem<String>(
                          value: task,
                          child: Text(
                            task,
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Select Task',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      onChanged: (value) {
                        selectedTask.value = value ?? '';
                      },
                    ),
                    const SizedBox(height: 20),
                    Obx(() {
                      if (!Get.isRegistered<UserController>()) {
                        return const Text(
                          "No users available",
                          style: TextStyle(color: Colors.white),
                        );
                      }
                      
                      if (userController.allUsers.isEmpty) {
                        return const Text(
                          "No users available",
                          style: TextStyle(color: Colors.white),
                        );
                      }
                      return DropdownButtonFormField<String>(
                        value: selectedUser.value.isEmpty
                            ? null
                            : selectedUser.value,
                        items: userController.allUsers.map((user) {
                          return DropdownMenuItem<String>(
                            value: user['id'],
                            child: Text(
                              user['name'],
                              style: const TextStyle(color: Colors.black),
                            ),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: 'Assign To',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        onChanged: (value) {
                          selectedUser.value = value ?? '';
                        },
                      );
                    }),
                    const SizedBox(height: 20),
                    Obx(() {
                      if (!Get.isRegistered<AuthController>()) {
                        return ElevatedButton(
                          onPressed: () {},
                          child: const Text('Assign Task'),
                        );
                      }
                      
                      return auth.isLoading.value
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () {
                                if (selectedTask.value.isNotEmpty &&
                                    selectedUser.value.isNotEmpty) {
                                  auth.assignTask(
                                      selectedTask.value, selectedUser.value);
                                } else {
                                  Get.snackbar(
                                      'Error', 'Please select a task and a user');
                                }
                              },
                              child: const Text('Assign Task'),
                            );
                    }),
                  ],
                ),
              const SizedBox(height: 20),
              Obx(() {
                if (!Get.isRegistered<ManageUsersController>()) {
                  return const Text(
                    'No users to display',
                    style: TextStyle(color: Colors.white),
                  );
                }
                
                if (manageUsersController.usersList.isEmpty) {
                  return const Text(
                    'No users to display',
                    style: TextStyle(color: Colors.white),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage Users',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedManagedUser.value.isEmpty
                          ? null
                          : selectedManagedUser.value,
                      items: manageUsersController.usersList.map((user) {
                        return DropdownMenuItem<String>(
                          value: user['id'],
                          child: Text(
                            user['fullname'],
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Select User',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      onChanged: (value) {
                        selectedManagedUser.value = value ?? '';
                      },
                    ),
                    const SizedBox(height: 20),
                    Obx(() {
                      if (!Get.isRegistered<ManageUsersController>()) {
                        return ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete User'),
                        );
                      }
                      
                      return ElevatedButton(
                        onPressed: () {
                          if (selectedManagedUser.value.isNotEmpty) {
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
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const UserNavBar(currentIndex: 2),
    );
  }
}
