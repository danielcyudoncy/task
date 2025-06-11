// views/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  // --- Assign Task Dialog (with null safety)
  void _showAssignTaskDialog(Map<String, dynamic> user) async {
    String? selectedTaskTitle;
    await Get.defaultDialog(
      title: "Assign Task to ${user['fullname']}",
      content: Obx(() {
        final tasks = adminController.taskTitles;
        if (tasks.isEmpty) {
          return const Text("No tasks available");
        }
        return StatefulBuilder(
          builder: (context, setState) => DropdownButton<String>(
            value: selectedTaskTitle,
            hint: const Text("Select Task"),
            items: tasks
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (val) => setState(() => selectedTaskTitle = val),
          ),
        );
      }),
      textConfirm: "Assign",
      onConfirm: () async {
        if (selectedTaskTitle == null) {
          Get.snackbar("Error", "Please select a task");
          return;
        }
        // Correction: Accept both 'uid' and fallback to 'id'
        final userId = user['uid'] ?? user['id'];
        if (userId == null) {
          Get.snackbar("Error", "User ID is missing");
          return;
        }
        try {
          await adminController.assignTaskToUser(userId, selectedTaskTitle!);
          Get.back(); // Close dialog
          Get.snackbar("Success", "Task assigned to ${user['fullname']}");
        } catch (e) {
          Get.snackbar("Error", "Failed to assign task: $e");
        }
      },
    );
  }
  // --- END: Assign Task Dialog

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

    return Obx(() {
      if (adminController.isLoading.value ||
          adminController.isStatsLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeaderWidget(authController: authController),
                      const SizedBox(height: 30),
                      Text(
                        AppStrings.dailyAssignments,
                        style: AppStyles.sectionTitleStyle.copyWith(
                          color:
                              isDark ? Colors.white : const Color(0xFF3739B7),
                        ),
                      ),
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
                            fontSize: 16.sp,
                            color:
                                isDark ? Colors.white : const Color(0xFF3739B7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () => Get.toNamed('/create-task'),
                                child: Container(
                                  width: 34.w,
                                  height: 34.h,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF3739B7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 22.sp,
                                    color: isDark
                                        ? const Color(0xFF3739B7)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TabBar(
                          controller: _tabController,
                          indicatorColor:
                              isDark ? Colors.white : const Color(0xFF3739B7),
                          labelColor:
                              isDark ? Colors.white : const Color(0xFF3739B7),
                          unselectedLabelColor:
                              isDark ? Colors.white70 : Colors.black54,
                          labelStyle: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 15),
                          tabs: const [
                            Tab(text: "Not Completed"),
                            Tab(text: "Completed"),
                          ],
                        ),
                        const SizedBox(height: 8),
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
          height: 500.h,
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
                final userName = user['fullname']?.toString().isNotEmpty == true
                    ? user['fullname']
                    : AppStrings.unknownUser;
                return ListTile(
                  title: Text(userName),
                  subtitle: Text("Role: ${user['role'] ?? 'Unknown'}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.assignment, color: Colors.blue),
                        onPressed: () => _showAssignTaskDialog(user),
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
      final userId = user['uid'] ?? user['id'];
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
    final doc = adminController.taskSnapshotDocs
        .firstWhereOrNull((d) => d['title'] == title);
    Get.defaultDialog(
      title: AppStrings.taskDetails,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Title: $title"),
          const SizedBox(height: 6),
          Text("Status: ${_getTaskStatus(title)}"),
          const SizedBox(height: 6),
          Text("Created by: ${doc?['createdByName'] ?? AppStrings.unknown}"),
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
}

// Only the _TasksTab widget, showing assigned user name

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
    const Color subTextColor = Colors.white70;
    final Color emptyListColor = isDark ? Colors.white70 : Colors.black54;

    if (tasks.isEmpty) {
      return Center(
        child: Text("No tasks.", style: TextStyle(color: emptyListColor)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final title = tasks[index];
        final doc = taskDocs.firstWhereOrNull((d) => d['title'] == title);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doc != null &&
                            doc is Map<String, dynamic> &&
                            doc.containsKey('details')
                        ? doc['details']?.toString() ??
                            "Task details not available."
                        : "Task details not available.",
                    style: const TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // This line shows the assigned user name (or Unassigned)
                    "Assigned to: ${doc?['assignedName'] ?? 'Unassigned'}",
                    style: const TextStyle(color: subTextColor, fontSize: 13),
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
