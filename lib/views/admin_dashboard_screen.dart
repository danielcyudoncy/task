// views/admin_dashboard_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? selectedTaskTitle;
  final Map<String, Map<String, String>> userCache = {};

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

  Future<Map<String, String>> getUserNameAndRole(
      String userId, VoidCallback refresh) async {
    if (userCache.containsKey(userId)) {
      return userCache[userId]!;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final name = data['fullName'] ?? userId;
        final role = data['role'] ?? "Unknown";
        userCache[userId] = {"name": name, "role": role};
        refresh();
        return {"name": name, "role": role};
      }
    // ignore: empty_catches
    } catch (e) {}
    userCache[userId] = {"name": userId, "role": "Unknown"};
    refresh();
    return {"name": userId, "role": "Unknown"};
  }

  void _showAssignTaskDialog(Map<String, dynamic> user) async {
    selectedTaskTitle = null;
    await Get.defaultDialog(
      title:
          "Assign Task to ${user['fullName'] ?? user['fullname'] ?? "Unknown"}",
      content: Obx(() {
        final tasks = adminController.taskTitles;
        if (tasks.isEmpty) {
          return const Text("No tasks available");
        }
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Text(
                    "Select Task: ",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedTaskTitle,
                        dropdownColor: Theme.of(context).cardColor,
                        hint: Text(
                          "Select Task",
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        icon: Icon(Icons.arrow_drop_down,
                            color: Theme.of(context).iconTheme.color),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 16,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        items: tasks
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedTaskTitle = val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            );
          },
        );
      }),
      textConfirm: "Assign",
      onConfirm: () async {
        if (selectedTaskTitle == null) {
          Get.snackbar("Error", "Please select a task");
          return;
        }
        final userId = user['uid'] ?? user['id'];
        if (userId == null) {
          Get.snackbar("Error", "User ID is missing");
          return;
        }
        final selectedTaskDoc = adminController.taskSnapshotDocs
            .firstWhere((d) => d['title'] == selectedTaskTitle);

        final String taskId =
            selectedTaskDoc['id'] ?? selectedTaskDoc['taskId'];
        final String taskDescription = selectedTaskDoc['description'] ?? "";
        final DateTime dueDate = (selectedTaskDoc['dueDate'] is Timestamp)
            ? (selectedTaskDoc['dueDate'] as Timestamp).toDate()
            : DateTime.tryParse(selectedTaskDoc['dueDate']?.toString() ?? "") ??
                DateTime.now();

        try {
          await adminController.assignTaskToUser(
            userId: userId,
            assignedName: user['fullName'] ?? user['fullname'] ?? "Unknown",
            taskTitle: selectedTaskTitle!,
            taskDescription: taskDescription,
            dueDate: dueDate,
            taskId: taskId,
          );
          Get.back();
          Get.snackbar("Success",
              "Task assigned to ${user['fullName'] ?? user['fullname'] ?? "Unknown"}");
        } catch (e) {
          Get.snackbar("Error", "Failed to assign task: $e");
        }
      },
    );
  }

  void _showManageUsersDialog() {
    final currentUserId = authController.user.value?.uid;
    final otherUsers = manageUsersController.usersList
        .where((user) => user['uid'] != currentUserId)
        .toList();

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
            if (otherUsers.isEmpty) {
              return const Center(child: Text('No users available.'));
            }
            return ListView.builder(
              itemCount: otherUsers.length,
              itemBuilder: (context, index) {
                final user = otherUsers[index];
                final userName = user['fullName']?.toString().isNotEmpty == true
                    ? user['fullName']
                    : (user['fullname']?.toString().isNotEmpty == true
                        ? user['fullname']
                        : AppStrings.unknownUser);
                final userRole = user['role'] ?? 'Unknown';
                return ListTile(
                  title: Text(userName),
                  subtitle: Text("Role: $userRole"),
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

    final creatorId = doc?['createdBy'] ?? 'Unknown';
    String dateStr = 'Unknown';
    if (doc?['timestamp'] != null) {
      final createdAt = doc?['timestamp'];
      DateTime dt;
      if (createdAt is Timestamp) {
        dt = createdAt.toDate();
      } else if (createdAt is DateTime) {
        dt = createdAt;
      } else {
        dt = DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
      }
      dateStr =
          "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }

    Get.defaultDialog(
      title: AppStrings.taskDetails,
      content: StatefulBuilder(
        builder: (context, setState) {
          final userInfo = userCache[creatorId];
          if (userInfo == null && creatorId != 'Unknown') {
            getUserNameAndRole(creatorId, () => setState(() {}));
          }
          final creatorName = userInfo?["name"] ?? creatorId;
          final creatorRole = userInfo?["role"] ?? "Unknown";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Title: $title"),
              const SizedBox(height: 6),
              Text("Status: ${_getTaskStatus(title)}"),
              const SizedBox(height: 6),
              Text("Created by: $creatorName"),
              Text("Role: $creatorRole"),
              Text("Date: $dateStr"),
            ],
          );
        },
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

  void _showAllPendingTasksDialog() {
    final tasks = adminController.pendingTaskTitles;
    final docs = adminController.taskSnapshotDocs;
    if (tasks.isEmpty) {
      Get.snackbar("No Tasks", "There are no tasks to display.");
      return;
    }

    Get.defaultDialog(
      title: "Pending Tasks",
      content: SizedBox(
        width: 300, // or whatever width you want
        height: MediaQuery.of(context).size.height * 0.5, // fixed height!
        child: StatefulBuilder(
          builder: (ctx, setState) => ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final title = tasks[index];
              final doc = docs.firstWhereOrNull((d) => d['title'] == title);

              final creatorId = doc?['createdBy'] ?? 'Unknown';
              final userInfo = userCache[creatorId];
              if (userInfo == null && creatorId != 'Unknown') {
                getUserNameAndRole(creatorId, () => setState(() {}));
              }
              final creatorName = userInfo?["name"] ?? creatorId;
              final creatorRole = userInfo?["role"] ?? "Unknown";

              String dateStr = 'Unknown';
              final createdAt = doc?['timestamp'];
              if (createdAt != null) {
                DateTime dt;
                if (createdAt is Timestamp) {
                  dt = createdAt.toDate();
                } else if (createdAt is DateTime) {
                  dt = createdAt;
                } else {
                  dt =
                      DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
                }
                dateStr =
                    "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
              }

              return ListTile(
                title: Text(title),
                subtitle: Text(
                    "Created by: $creatorName\nRole: $creatorRole\nDate: $dateStr"),
                onTap: () {
                  Get.back();
                  _showTaskDetailDialog(title);
                },
              );
            },
          ),
        ),
      ),
      textConfirm: "Close",
      onConfirm: () => Get.back(),
    );
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
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: HeaderWidget(authController: authController),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                       Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            AppStrings.dailyAssignments,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DashboardCardsWidget(
                            usersCount:
                                adminController.statistics['users'] ?? 0,
                            tasksCount:
                                adminController.statistics['tasks'] ?? 0,
                            onManageUsersTap: _showManageUsersDialog,
                            onTotalTasksTap: _showAllPendingTasksDialog,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.only(left: 24, bottom: 8),
                          child: Text(
                            "TASK",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
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
                                indicatorColor: isDark
                                    ? Colors.white
                                    : const Color(0xFF3739B7),
                                labelColor: isDark
                                    ? Colors.white
                                    : const Color(0xFF3739B7),
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
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.48,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _TasksTab(
                                      tasks: adminController.pendingTaskTitles,
                                      taskDocs:
                                          adminController.taskSnapshotDocs,
                                      onTaskTap: _showTaskDetailDialog,
                                      isDark: isDark,
                                      userCache: userCache,
                                      getUserNameAndRole: getUserNameAndRole,
                                    ),
                                    _TasksTab(
                                      tasks:
                                          adminController.completedTaskTitles,
                                      taskDocs:
                                          adminController.taskSnapshotDocs,
                                      onTaskTap: _showTaskDetailDialog,
                                      isDark: isDark,
                                      userCache: userCache,
                                      getUserNameAndRole: getUserNameAndRole,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
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
}

class _TasksTab extends StatefulWidget {
  final List<dynamic> tasks;
  final List<dynamic> taskDocs;
  final void Function(String title) onTaskTap;
  final bool isDark;
  final Map<String, Map<String, String>> userCache;
  final Future<Map<String, String>> Function(String, VoidCallback)
      getUserNameAndRole;

  const _TasksTab({
    required this.tasks,
    required this.taskDocs,
    required this.onTaskTap,
    required this.isDark,
    required this.userCache,
    required this.getUserNameAndRole,
  });

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        widget.isDark ? const Color(0xFF292B3A) : const Color(0xFF171FA0);
    const Color textColor = Colors.white;
    const Color subTextColor = Colors.white70;
    final Color emptyListColor =
        widget.isDark ? Colors.white70 : Colors.black54;

    if (widget.tasks.isEmpty) {
      return Center(
        child: Text("No tasks.", style: TextStyle(color: emptyListColor)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: widget.tasks.length,
      itemBuilder: (context, index) {
        final title = widget.tasks[index];
        final Map<String, dynamic> doc = widget.taskDocs.firstWhere(
          (d) => d['title'] == title,
          orElse: () => <String, dynamic>{}, // Return an empty map if not found
        );

        final creatorId =
            doc.isNotEmpty ? (doc['createdBy'] ?? 'Unknown') : 'Unknown';
        final userInfo = widget.userCache[creatorId];
        if (userInfo == null && creatorId != 'Unknown') {
          widget.getUserNameAndRole(creatorId, () => setState(() {}));
        }
        final creatorName = userInfo?["name"] ?? creatorId;
        final creatorRole = userInfo?["role"] ?? "Unknown";

        String dateStr = 'Unknown';
        if (doc.isNotEmpty && doc['timestamp'] != null) {
          final createdAt = doc['timestamp'];
          DateTime dt;
          if (createdAt is Timestamp) {
            dt = createdAt.toDate();
          } else if (createdAt is DateTime) {
            dt = createdAt;
          } else {
            dt = DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
          }
          dateStr =
              "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: GestureDetector(
            onTap: () => widget.onTaskTap(title),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDark
                        ? Colors.black38
                        : const Color(0x22000000),
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
                    doc.isNotEmpty && doc.containsKey('description')
                        ? doc['description']?.toString() ??
                            "Task details not available."
                        : "Task details not available.",
                    style: const TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Assigned to: ${doc.isNotEmpty ? (doc['assignedName'] ?? 'Unassigned') : 'Unassigned'}",
                    style: const TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Created by: $creatorName",
                    style: const TextStyle(color: subTextColor, fontSize: 12),
                  ),
                  Text(
                    "Role: $creatorRole",
                    style: const TextStyle(color: subTextColor, fontSize: 12),
                  ),
                  Text(
                    "Date: $dateStr",
                    style: const TextStyle(color: subTextColor, fontSize: 12),
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
