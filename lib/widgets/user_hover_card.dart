import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/manage_users_controller.dart';

class UserHoverCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final int index;
  final ManageUsersController controller;
  final double textScale;
  final bool isLargeScreen;
  final VoidCallback onAssignTask;
  const UserHoverCard({
    required this.user,
    required this.index,
    required this.controller,
    required this.textScale,
    required this.isLargeScreen,
    required this.onAssignTask,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => controller.updateHoverState(index, true),
      onExit: (event) => controller.updateHoverState(index, false),
      child: Obx(() {
        final isHovered = controller.isHovered[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(vertical: isLargeScreen ? 12 : 8, horizontal: isLargeScreen ? 32 : 16),
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
            leading: Semantics(
              label: 'User Avatar',
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  _getInitials(user['fullname']),
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: isLargeScreen ? 18 * textScale : 14 * textScale,
                  ),
                ),
              ),
            ),
            title: Text(
              user['fullname'],
              style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Role: ${user['role']}",
              style: TextStyle(fontSize: 14 * textScale, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: "Assign Task",
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.assignment, color: Colors.blue),
                    onPressed: onAssignTask,
                  ),
                ),
                Semantics(
                  label: "Delete User",
                  button: true,
                  child: IconButton(
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
                        final success = await controller.deleteUser(user['id']);
                        if (success) {
                          controller.usersList.removeAt(index);
                          Get.snackbar('Success', 'User deleted successfully',
                              snackPosition: SnackPosition.BOTTOM);
                        } else {
                          Get.snackbar('Error', 'Failed to delete user',
                              snackPosition: SnackPosition.BOTTOM);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
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