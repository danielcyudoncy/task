// views/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/utils/constants/app_strings.dart';
import 'package:task/utils/constants/app_styles.dart';
import 'package:task/widgets/dashboard_cards_widget.dart';
import 'package:task/widgets/header_widget.dart';
import 'package:task/widgets/tab_bar_widget.dart';
import 'package:task/widgets/task_list_widget.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/manage_users_controller.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AdminController adminController = Get.find<AdminController>();
  final AuthController authController = Get.find<AuthController>();
  final ManageUsersController manageUsersController =
      Get.find<ManageUsersController>();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    adminController.fetchStatistics();
    adminController.fetchDashboardData();
    manageUsersController.fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (adminController.isLoading.value ||
          adminController.isStatsLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        body: Container(
          decoration:
              const BoxDecoration(gradient: AppStyles.gradientBackground),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Using HeaderWidget
                  HeaderWidget(authController: authController),

                  const SizedBox(height: 30),

                  const Text(AppStrings.dailyAssignments,
                      style: AppStyles.sectionTitleStyle),

                  const SizedBox(height: 20),

                  // Using DashboardCardsWidget
                  DashboardCardsWidget(
                    adminController: adminController,
                    onManageUsersTap: _showManageUsersDialog,
                    onTaskSelected: (value) {
                      if (value != null && value.isNotEmpty) {
                        _showTaskDetailDialog(value);
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Task Section
                  _buildTaskSection(),

                  const SizedBox(height: 16),

                  // Using TabBarWidget
                  TabBarWidget(
                    tabController: _tabController,
                    tabTitles: const [
                      AppStrings.notCompleted,
                      AppStrings.completed
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Using TaskListWidget inside TabBarView
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        TaskListWidget(
                          tasks: adminController.pendingTaskTitles,
                          showCompleted: false,
                          onTaskTap: (task) => _showTaskDetailDialog(task),
                        ),
                        TaskListWidget(
                          tasks: adminController.completedTaskTitles,
                          showCompleted: true,
                          onTaskTap: (task) => _showTaskDetailDialog(task),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTaskSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(AppStrings.task, style: AppStyles.sectionTitleStyle),
        GestureDetector(
          onTap: () => Get.toNamed('/task-creation'),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF0B189B),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showManageUsersDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          height: 500,
          child: Obx(() {
            if (manageUsersController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (manageUsersController.usersList.isEmpty) {
              return const Center(child: Text('No users available.'));
            }
            return ListView.builder(
              itemCount: manageUsersController.usersList.length,
              itemBuilder: (context, index) {
                final user = manageUsersController.usersList[index];
                final userName = user['fullname']?.isNotEmpty == true
                    ? user['fullname']
                    : AppStrings.unknownUser;
                return ListTile(
                  title: Text(userName),
                  subtitle: Text("Role: ${user['role']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.assignment, color: Colors.blue),
                        onPressed: () => Get.snackbar(
                            "Assign Task", "Task assigned to $userName"),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmUserDeletion(user),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  void _confirmUserDeletion(Map<String, dynamic> user) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text(AppStrings.deleteUser),
        content: const Text(AppStrings.deleteUserConfirmation),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      final userId = user['uid'];
      if (userId != null) {
        await manageUsersController.deleteUser(userId);
        Get.snackbar("Success", "User deleted successfully",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar("Error", "User ID is missing",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  void _showTaskDetailDialog(String title) {
    Get.defaultDialog(
      title: AppStrings.taskDetails,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Title: $title"),
          const SizedBox(height: 6),
          Text("Status: ${_getTaskStatus(title)}"),
          const SizedBox(height: 6),
          Text("Created by: ${_getCreatedBy(title)}"),
        ],
      ),
      textConfirm: AppStrings.close,
      onConfirm: () => Get.back(),
    );
  }

  String _getTaskStatus(String title) {
    if (adminController.completedTaskTitles.contains(title)) {
      return AppStrings.completed;
    } else if (adminController.pendingTaskTitles.contains(title)) {
      return AppStrings.notCompleted;
    } else {
      return AppStrings.unknown;
    }
  }

  String _getCreatedBy(String title) {
    final task = adminController.taskSnapshotDocs
        .firstWhereOrNull((doc) => doc['title'] == title);
    return task?['createdByName'] ?? AppStrings.unknown;
  }
}
