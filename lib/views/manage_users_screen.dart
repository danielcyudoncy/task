// views/manage_users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/utils/constants/app_sizes.dart';
import 'package:task/widgets/empty_state_widget.dart';
import 'package:task/widgets/task_list_dialog.dart';
import 'package:task/widgets/user_hover_card.dart';
import 'package:task/widgets/user_skeleton_list.dart';
import '../controllers/manage_users_controller.dart';


class ManageUsersScreen extends StatelessWidget {
  final ManageUsersController manageUsersController = Get.find();

  ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Users',
          style: TextStyle(fontSize: AppSizes.titleNormal, 
          fontWeight: FontWeight.bold, 
          color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0B189B),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Semantics(
              label: "Search Users",
              textField: true,
              child: TextField(
                onChanged: (query) => manageUsersController.searchUsers(query),
                style: TextStyle(fontSize: 16.sp * textScale),
                decoration: const InputDecoration(
                  labelText: 'Search Users',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          // User List
          Expanded(
            child: Obx(() {
              
              if (manageUsersController.isLoading.value && manageUsersController.usersList.isEmpty) {
                return UserSkeletonList(isLargeScreen: isLargeScreen, textScale: textScale);
              }
              if (manageUsersController.usersList.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.group_outlined,
                  title: "No users found",
                  message: "Try a different search or check back later.",
                );
              }
              return ListView.builder(
                controller: manageUsersController.scrollController,
                itemCount: manageUsersController.usersList.length,
                itemBuilder: (context, index) {
                  final user = manageUsersController.usersList[index];
                  return UserHoverCard(
                    user: user,
                    index: index,
                    controller: manageUsersController,
                    textScale: textScale,
                    isLargeScreen: isLargeScreen,
                    onAssignTask: () => showDialog(
                      context: context,
                      builder: (_) => TaskListDialog(
                        controller: manageUsersController,
                        user: user,
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