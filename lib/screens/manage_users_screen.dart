// screens/manage_users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:task/utils/constants/app_sizes.dart';
import 'package:task/widgets/empty_state_widget.dart';
import 'package:task/widgets/assign_task_dialog.dart';
import 'package:task/widgets/user_skeleton_list.dart';
import '../controllers/manage_users_controller.dart';
import 'package:task/utils/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';

class ManageUsersScreen extends StatelessWidget {
  final ManageUsersController manageUsersController =
      Get.put(ManageUsersController(Get.find()));

  ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final currentUserId = Get.find<AuthController>().auth.currentUser?.uid;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? [Colors.grey[900]!, Colors.grey[800]!]
              .reduce((value, element) => value)
          : Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: const Text(
          'Manage Users',
          style: TextStyle(
              fontSize: AppSizes.titleNormal,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? [Colors.grey[900]!, Colors.grey[800]!]
                .reduce((value, element) => value)
            : Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar and Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (query) =>
                        manageUsersController.searchUsers(query),
                    style: TextStyle(
                        fontSize: 16.sp * textScale,
                        color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Search Users',
                      prefixIcon: Icon(Icons.search,
                          color: theme.colorScheme.onSurface),
                      labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() => DropdownButton<String>(
                      value: manageUsersController.selectedRole.value,
                      items: <String>[
                        'All',
                        'Admin',
                        'Reporter',
                        'Cameraman',
                        'Driver'
                      ]
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role,
                                    style: TextStyle(
                                        color: theme.colorScheme.onPrimary)),
                              ))
                          .toList(),
                      onChanged: (role) =>
                          manageUsersController.filterByRole(role),
                      underline: const SizedBox(),
                      style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                      dropdownColor: theme.colorScheme.primary,
                    )),
              ],
            ),
          ),
          // User List
          Expanded(
            child: Obx(() {
              if (manageUsersController.isLoading.value &&
                  manageUsersController.usersList.isEmpty) {
                return UserSkeletonList(
                    isLargeScreen: isLargeScreen, textScale: textScale);
              }
              if (manageUsersController.usersList.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.group_outlined,
                  title: "No users found",
                  message: "Try a different search or check back later.",
                );
              }
              final users = manageUsersController.filteredUsersList;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = isLargeScreen ? 2 : 1;
                  return GridView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isLargeScreen ? 2.5 : 1.8,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userId = user['id'] ?? user['uid'] ?? '';
                      final userName =
                          user['fullName'] ?? user['fullname'] ?? 'No name';
                      final userEmail = user['email'] ?? 'No email';
                      final userRole = user['role'] ?? 'Unknown';
                      final userPhoto = user['photoUrl'] ?? '';
                      final isCurrentUser = userId == currentUserId;
                      final hasTask = user['hasTask'] ?? false;
                      return InkWell(
                          onTap: () => showDialog(
                                context: context,
                                builder: (context) => AssignTaskDialog(
                                    user: user,
                                    adminController:
                                        Get.find<AdminController>()),
                              ),
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            color: theme.brightness == Brightness.dark
                                ? theme.colorScheme.surface
                                : AppColors.primaryColor,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        theme.brightness == Brightness.dark
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onPrimary,
                                    child: userPhoto.isNotEmpty
                                        ? ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: userPhoto,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                              errorWidget:
                                                  (context, url, error) => Icon(
                                                Icons.person,
                                                color: theme.brightness ==
                                                        Brightness.dark
                                                    ? theme
                                                        .colorScheme.onPrimary
                                                    : theme.colorScheme.primary,
                                                size: 28,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            color: theme.brightness ==
                                                    Brightness.dark
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme.primary,
                                            size: 28,
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  // User info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                userName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16.sp * textScale,
                                                  color: theme.brightness ==
                                                          Brightness.dark
                                                      ? theme
                                                          .colorScheme.onSurface
                                                      : theme.colorScheme
                                                          .onPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            if (isCurrentUser)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 6.0),
                                                child: Chip(
                                                  label: const Text('You'),
                                                  backgroundColor:
                                                      theme.brightness ==
                                                              Brightness.dark
                                                          ? theme.colorScheme
                                                              .secondary
                                                          : theme.colorScheme
                                                              .onPrimary
                                                              .withAlpha(45),
                                                  labelStyle: TextStyle(
                                                    color: theme.brightness ==
                                                            Brightness.dark
                                                        ? theme.colorScheme
                                                            .onSecondary
                                                        : theme.colorScheme
                                                            .primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                              ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 6.0),
                                              child: Icon(
                                                hasTask
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: hasTask
                                                    ? Colors.green
                                                    : Colors.red,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          userEmail,
                                          style: TextStyle(
                                            color: theme.brightness ==
                                                    Brightness.dark
                                                ? theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.7)
                                                : theme.colorScheme.onPrimary
                                                    .withValues(alpha: 0.85),
                                            fontSize: 11.sp * textScale,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Chip(
                                                label: Text(
                                                  userRole,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                backgroundColor:
                                                    theme.colorScheme.primary,
                                                labelStyle: TextStyle(
                                                  color: theme.brightness ==
                                                          Brightness.dark
                                                      ? theme
                                                          .colorScheme.onPrimary
                                                      : theme.colorScheme
                                                          .onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Action buttons
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.assignment_ind,
                                          color: theme.brightness ==
                                                  Brightness.dark
                                              ? theme.colorScheme.secondary
                                              : theme.colorScheme.onPrimary,
                                        ),
                                        tooltip: 'Assign Task',
                                        onPressed: () => showDialog(
                                          context: context,
                                          builder: (context) =>
                                              AssignTaskDialog(
                                                  user: user,
                                                  adminController: Get.find<
                                                      AdminController>()),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: theme.colorScheme.error),
                                        tooltip: 'Delete User',
                                        onPressed: () => manageUsersController
                                            .deleteUser(userId),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ));
                    },
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
