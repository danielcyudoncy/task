// widgets/manage_users_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import '../../controllers/manage_users_controller.dart';
import '../../utils/constants/app_strings.dart';

class ManageUsersDialog extends StatelessWidget {
  final ManageUsersController manageUsersController;
  final void Function(Map<String, dynamic> user) onAssignTap;

  const ManageUsersDialog({
    super.key,
    required this.manageUsersController,
    required this.onAssignTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryBlue = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: isDark ? theme.colorScheme.surface : primaryBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        height: 500,
        child: Obx(() {
          if (manageUsersController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (manageUsersController.usersList.isEmpty) {
            return Center(
              child: Text(
                'No users available.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.white,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: manageUsersController.usersList.length,
            itemBuilder: (context, index) {
              final user = manageUsersController.usersList[index];
              final userName = (user['fullName']?.toString().isNotEmpty == true)
                  ? user['fullName']
                  : (user['fullname']?.toString().isNotEmpty == true)
                      ? user['fullname']
                      : AppStrings.unknownUser;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 7.0, horizontal: 2.0),
                child: Material(
                  color: Colors.transparent,
                  child: Card(
                    elevation: isDark ? 1.5 : 3.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: isDark
                            ? Colors.grey[800]!
                            : Colors.white,
                        width: 1,
                      ),
                    ),
                    color: isDark ? theme.cardColor : Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? theme.colorScheme.onPrimary
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              isDark ? primaryBlue.withAlpha(128) : primaryBlue.withAlpha(204),
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : "?",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        userName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : primaryBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        "Role: ${user['role'] ?? 'Unknown'}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: "Assign Task",
                            child: IconButton(
                              icon: Icon(
                                Icons.assignment_outlined,
                                color: theme.colorScheme.secondary,
                              ),
                              onPressed: () {
                                Get.find<SettingsController>().triggerFeedback();
                                onAssignTap(user);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
