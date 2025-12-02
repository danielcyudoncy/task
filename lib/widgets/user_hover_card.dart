// widgets/user_hover_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import '../../controllers/manage_users_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
          margin: EdgeInsets.symmetric(
              vertical: isLargeScreen ? 12.h : 8.h,
              horizontal: isLargeScreen ? 32.w : 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (isHovered)
                BoxShadow(
                  color: Colors.grey.withAlpha((1.0 * 255).round()),
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
            ],
          ),
          child: ListTile(
            leading: Semantics(
              label: 'User Avatar',
              excludeSemantics: true,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.onPrimary
                        : Colors.white,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    _getInitials(user['fullname']),
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize:
                          isLargeScreen ? 18.sp * textScale : 14.sp * textScale,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              user['fullname'],
              style: TextStyle(
                  fontSize: 16.sp * textScale, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Role: ${user['role']}",
              style: TextStyle(
                  fontSize: 14.sp * textScale,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: "Assign Task",
                  button: true,
                  excludeSemantics: true,
                  child: IconButton(
                    icon: const Icon(Icons.assignment, color: Colors.blue),
                    onPressed: onAssignTask,
                  ),
                ),
                Semantics(
                  label: "Delete User",
                  button: true,
                  excludeSemantics: true,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      Get.find<SettingsController>().triggerFeedback();
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
      return names[0].substring(0, 1).toUpperCase() +
          names[1].substring(0, 1).toUpperCase();
    }
  }
}
