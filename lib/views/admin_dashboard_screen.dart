// views/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/utils/constants/app_strings.dart';
import 'package:task/utils/constants/app_styles.dart';
import 'package:task/widgets/dashboard_cards_widget.dart';
import 'package:task/widgets/header_widget.dart';
import 'package:task/widgets/user_nav_bar.dart';
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

                  // ===== NEW UI: TASK label is OUTSIDE the white container =====
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      "TASK",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF3739B7),
                      ),
                    ),
                  ),

                  // ===== White rounded container blends with bottom navbar =====
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(26),
                          topRight: Radius.circular(26),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row with Add button only (TASK label is now above container)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 18,
                              left: 16,
                              right: 16,
                              bottom: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () => Get.toNamed('/task-creation'),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF3739B7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add,
                                        color: Colors.white, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Tab Bar
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TabBar(
                              controller: _tabController,
                              indicatorColor: const Color(0xFF3739B7),
                              indicatorWeight: 2.5,
                              labelColor: const Color(0xFF3739B7),
                              unselectedLabelColor: Colors.black54,
                              labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 15),
                              tabs: const [
                                Tab(text: "Not Completed"),
                                Tab(text: "Completed"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // TabBarView with task cards
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _TasksTab(
                                  tasks: adminController.pendingTaskTitles,
                                  taskDocs: adminController.taskSnapshotDocs,
                                  onTaskTap: _showTaskDetailDialog,
                                ),
                                _TasksTab(
                                  tasks: adminController.completedTaskTitles,
                                  taskDocs: adminController.taskSnapshotDocs,
                                  onTaskTap: _showTaskDetailDialog,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const UserNavBar(currentIndex: 0),
      );
    });
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

// ---- Custom TaskList for the Cards ----
class _TasksTab extends StatelessWidget {
  final List<dynamic> tasks;
  final List<dynamic> taskDocs;
  final void Function(String title) onTaskTap;

  const _TasksTab({
    required this.tasks,
    required this.taskDocs,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
          child: Text("No tasks.", style: TextStyle(color: Colors.black54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 20, left: 8, right: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final title = tasks[index];
        final doc = taskDocs.firstWhereOrNull((d) => d['title'] == title);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: GestureDetector(
            onTap: () => onTaskTap(title),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF171FA0),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    doc?['details'] ?? "Task Details",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Assigned Name", // Replace with actual logic if available
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Due Date ${doc?['dueDate'] ?? 'N/A'}",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.edit_note_rounded,
                        color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
