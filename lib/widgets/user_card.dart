// widgets/user_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import '../../controllers/manage_users_controller.dart';

class UserCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final ManageUsersController controller;

  const UserCard({
    super.key,
    required this.user,
    required this.controller,
  });

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool showTaskDropdown = false;
  String? selectedTaskId;

  @override
  Widget build(BuildContext context) {
    final tasks = widget.controller.tasksList;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
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
                    child: Text(_getInitials(widget.user['fullname'])),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user['fullname'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Role: ${widget.user['role']}", 
                style: TextStyle(
                  fontSize: 14, 
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[400] 
                    : Colors.grey[600]
                )
              ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.assignment_turned_in, color: Colors.green),
                  tooltip: 'Assign Task',
                  onPressed: () {
                    Get.find<SettingsController>().triggerFeedback();
                    setState(() => showTaskDropdown = !showTaskDropdown);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete User',
                  onPressed: () async {
                    Get.find<SettingsController>().triggerFeedback();
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
                      final success = await widget.controller.deleteUser(widget.user['id']);
                      if (success) {
                        Get.snackbar('Success', 'User deleted successfully', 
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Get.theme.colorScheme.primary,
                          colorText: Get.theme.colorScheme.onPrimary,
                        );
                      } else {
                        Get.snackbar('Error', 'Failed to delete user', 
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Get.theme.colorScheme.error,
                          colorText: Get.theme.colorScheme.onError,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            if (showTaskDropdown)
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 40, right: 8),
                child: DropdownButton<String>(
                  value: selectedTaskId,
                  isExpanded: true,
                  hint: const Text("Select a task"),
                  items: tasks.map((task) {
                    return DropdownMenuItem<String>(
                      value: task['id'],
                      child: Text(task['title']),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setState(() => selectedTaskId = value);
                    if (value != null) {
                      await widget.controller.assignTaskToUser(widget.user['id'], value);
                      setState(() => showTaskDropdown = false);
                      Get.snackbar('Success', 'Task assigned successfully', 
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Get.theme.colorScheme.primary,
                        colorText: Get.theme.colorScheme.onPrimary,
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String? fullname) {
    if (fullname == null || fullname.isEmpty) return "?";
    final names = fullname.split(" ");
    return names.length == 1
        ? names.first.substring(0, 1).toUpperCase()
        : names[0][0].toUpperCase() + names[1][0].toUpperCase();
  }
}