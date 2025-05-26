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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sectionTitleColor =
        isDark ? Colors.white : const Color(0xFF3739B7);
    final Color tabSelectedColor =
        isDark ? Colors.white : const Color(0xFF3739B7);
    final Color tabUnselectedColor = isDark ? Colors.white70 : Colors.black54;
    final Color addBtnColor = isDark ? Colors.white : const Color(0xFF3739B7);
    final Color addIconColor = isDark ? const Color(0xFF3739B7) : Colors.white;

    return Obx(() {
      if (adminController.isLoading.value ||
          adminController.isStatsLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [Colors.black, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : AppStyles.gradientBackground,
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header, dashboard, etc. remain with padding
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeaderWidget(authController: authController),
                      const SizedBox(height: 30),
                      Text(AppStrings.dailyAssignments,
                          style: AppStyles.sectionTitleStyle.copyWith(
                            color: sectionTitleColor,
                          )),
                      const SizedBox(height: 20),
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
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          "TASK",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: sectionTitleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // White/dark container is edge-to-edge (no left/right margin)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(26),
                        topRight: Radius.circular(26),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add button row (with left and right padding for button only)
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
                                  decoration: BoxDecoration(
                                    color: addBtnColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add,
                                      color: addIconColor, size: 22),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tab Bar (edge-to-edge)
                        TabBar(
                          controller: _tabController,
                          indicatorColor: tabSelectedColor,
                          indicatorWeight: 2.5,
                          labelColor: tabSelectedColor,
                          unselectedLabelColor: tabUnselectedColor,
                          labelStyle: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 15),
                          tabs: const [
                            Tab(text: "Not Completed"),
                            Tab(text: "Completed"),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // TabBarView with task cards (edge-to-edge)
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _TasksTab(
                                tasks: adminController.pendingTaskTitles,
                                taskDocs: adminController.taskSnapshotDocs,
                                onTaskTap: _showTaskDetailDialog,
                                isDark: isDark,
                              ),
                              _TasksTab(
                                tasks: adminController.completedTaskTitles,
                                taskDocs: adminController.taskSnapshotDocs,
                                onTaskTap: _showTaskDetailDialog,
                                isDark: isDark,
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
  final bool isDark;

  const _TasksTab({
    required this.tasks,
    required this.taskDocs,
    required this.onTaskTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        isDark ? const Color(0xFF292B3A) : const Color(0xFF171FA0);
    const Color textColor = Colors.white;
    final Color subTextColor = Colors.white.withOpacity(0.87);
    final Color emptyListColor = isDark ? Colors.white70 : Colors.black54;

    if (tasks.isEmpty) {
      return Center(
          child: Text("No tasks.", style: TextStyle(color: emptyListColor)));
    }
    return ListView.builder(
      // Remove left/right padding so task cards go edge-to-edge (minus card padding)
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final title = tasks[index];
        final doc = taskDocs.firstWhereOrNull((d) => d['title'] == title);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 7.0),
          child: GestureDetector(
            onTap: () => onTaskTap(title),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black38 : const Color(0x22000000),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
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
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    doc?['details'] ?? "Task Details",
                    style: TextStyle(
                        color: subTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Assigned Name", // Replace with actual logic if available
                    style: TextStyle(
                        color: subTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Due Date ${doc?['dueDate'] ?? 'N/A'}",
                    style: TextStyle(
                        color: subTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.edit_note_rounded,
                        color: textColor, size: 22),
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
