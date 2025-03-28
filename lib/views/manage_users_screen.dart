// views/manage_users_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manage_users_controller.dart';

class ManageUsersScreen extends StatelessWidget {
  final ManageUsersController controller = Get.put(ManageUsersController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.usersList.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        return ListView.builder(
          itemCount: controller.usersList.length,
          itemBuilder: (context, index) {
            var user = controller.usersList[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(user['fullname'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text(user['email']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => controller.deleteUser(user['id']),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
