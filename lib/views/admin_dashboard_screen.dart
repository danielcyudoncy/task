// views/admin_dashboard_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/notification_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/utils/constants/app_strings.dart';
import 'package:task/widgets/app_drawer.dart';
import 'package:task/widgets/assign_task_dialog.dart';
import 'package:task/widgets/dashboard_cards_widget.dart';
import 'package:task/widgets/user_header.dart';
import 'package:task/widgets/user_nav_bar.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/manage_users_controller.dart';
import 'package:task/models/task_model.dart';
import 'package:task/widgets/task_card_widget.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AdminController adminController = Get.find<AdminController>();
  final AuthController authController = Get.find<AuthController>();
  final NotificationController notificationController = Get.find();
  final ManageUsersController manageUsersController =
      Get.find<ManageUsersController>();

  late TabController _tabController;
  String? selectedTaskTitle;
  final Map<String, Map<String, String>> userCache = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      adminController.fetchDashboardData();
      adminController.fetchStatistics();
      manageUsersController.fetchUsers();
    });
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
        WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
        return {"name": name, "role": role};
      }
    // ignore: empty_catches
    } catch (e) {}
    userCache[userId] = {"name": userId, "role": "Unknown"};
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
    return {"name": userId, "role": "Unknown"};
  }

  void _showAssignTaskDialog(Map<String, dynamic> user) async {
    Get.dialog(
      AssignTaskDialog(
        user: user,
        adminController: adminController,
      ),
    );
  }

  void _showManageUsersDialog() async {
    // Ensure users are fetched before showing dialog - fetch ALL users for dialog
    await manageUsersController.fetchUsers(fetchAll: true);
    
    final currentUserId = authController.user.value?.uid;
    debugPrint('Current user ID: $currentUserId');
    debugPrint('Total users in list: ${manageUsersController.usersList.length}');
    debugPrint('Users list: ${manageUsersController.usersList}');
    
    // Debug user photo URLs
    for (int i = 0; i < manageUsersController.usersList.length; i++) {
      final user = manageUsersController.usersList[i];
      debugPrint('User $i: ${user['fullName']} - photoUrl: "${user['photoUrl']}"');
    }
    
    final otherUsers = manageUsersController.usersList
        .where((user) => 
            user['uid'] != currentUserId && 
            user['id'] != currentUserId) // Check both uid and id fields
        .toList();
    
    debugPrint('Other users count: ${otherUsers.length}');

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
              // If no other users, show all users including current user
              final allUsers = manageUsersController.usersList;
              if (allUsers.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('no_users_available'.tr, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      'Total users in system: ${allUsers.length}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                );
              }
              return ListView.builder(
                itemCount: allUsers.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final user = allUsers[index];
                  final userName = user['fullName']?.toString().isNotEmpty == true
                      ? user['fullName']
                      : (user['fullname']?.toString().isNotEmpty == true
                          ? user['fullname']
                          : AppStrings.unknownUser);
                  final userRole = user['role'] ?? 'Unknown';
                  final userEmail = user['email'] ?? 'No email';
                  final isCurrentUser = user['uid'] == currentUserId || user['id'] == currentUserId;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isCurrentUser 
                          ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                          : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // User Avatar
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isCurrentUser 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: user['photoUrl'] != null && user['photoUrl'].toString().isNotEmpty
                                  ? Image.network(
                                      user['photoUrl'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: isCurrentUser 
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).colorScheme.secondary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: isCurrentUser 
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).colorScheme.secondary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: isCurrentUser 
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // User Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        userName + (isCurrentUser ? ' (You)' : ''),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentUser)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Current',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userRole,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Action Buttons
                          if (!isCurrentUser) ...[
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.assignment, color: Colors.blue),
                                  tooltip: 'Assign Task',
                                  onPressed: () {
                                    Get.find<SettingsController>().triggerFeedback();
                                    _showAssignTaskDialog(user);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete User',
                                  onPressed: () {
                                    Get.find<SettingsController>().triggerFeedback();
                                    _confirmUserDeletion(user);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            return ListView.builder(
              itemCount: otherUsers.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final user = otherUsers[index];
                final userName = user['fullName']?.toString().isNotEmpty == true
                    ? user['fullName']
                    : (user['fullname']?.toString().isNotEmpty == true
                        ? user['fullname']
                        : AppStrings.unknownUser);
                final userRole = user['role'] ?? 'Unknown';
                final userEmail = user['email'] ?? 'No email';
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // User Avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: user['photoUrl'] != null && user['photoUrl'].toString().isNotEmpty
                                ? Image.network(
                                    user['photoUrl'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('Image load error for ${user['fullName']}: $error');
                                      return Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.secondary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        debugPrint('Image loaded successfully for ${user['fullName']}');
                                        return child;
                                      }
                                      debugPrint('Loading image for ${user['fullName']}: ${loadingProgress.expectedTotalBytes != null ? '${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}' : 'Unknown size'}');
                                      return Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.secondary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      );
                                    },

                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userRole,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Action Buttons
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.assignment, color: Colors.blue),
                              tooltip: 'Assign Task',
                              onPressed: () {
                                Get.find<SettingsController>().triggerFeedback();
                                _showAssignTaskDialog(user);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete User',
                              onPressed: () {
                                Get.find<SettingsController>().triggerFeedback();
                                _confirmUserDeletion(user);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  void _navigateToChatUsers() async {
    Get.find<SettingsController>().triggerFeedback();
    
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      Get.back();
      Get.toNamed('/all-users-chat');
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Could not open chat: $e");
    }
  }

  void _confirmUserDeletion(Map<String, dynamic> user) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text(AppStrings.deleteUser),
        content: const Text(AppStrings.deleteUserConfirmation),
        actions: [
          TextButton(
            onPressed: () {
              Get.find<SettingsController>().triggerFeedback();
              Get.back(result: false);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.find<SettingsController>().triggerFeedback();
              Get.back(result: true);
            },
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

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(AppStrings.taskDetails),
        content: StatefulBuilder(
          builder: (context, setState) {
            final userInfo = userCache[creatorId];
            if (userInfo == null && creatorId != 'Unknown') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                getUserNameAndRole(creatorId, () => setState(() {}));
              });
            }
            final creatorName = userInfo?["name"] ?? creatorId;
            final creatorRole = userInfo?["role"] ?? "Unknown";
            return Column(
              mainAxisSize: MainAxisSize.min,
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
        actions: [
          TextButton(
            onPressed: () {
              Get.find<SettingsController>().triggerFeedback();
              Get.back();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              AppStrings.close,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  getUserNameAndRole(creatorId, () => setState(() {}));
                });
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
      onConfirm: () {
        Get.find<SettingsController>().triggerFeedback();
        Get.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      // Add safety check for build phase
      if (!mounted) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      
      if (adminController.isLoading.value ||
          adminController.isStatsLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        body: SafeArea(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).canvasColor
                  : Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserHeader(isDark: isDark, scaffoldKey: _scaffoldKey),
                
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          // --- DashboardCardsWidget ---
                          child: DashboardCardsWidget(
                            usersCount:
                                adminController.statistics['users'] ?? 0,
                            onlineUsersCount:
                                adminController.statistics['online'] ?? 0,
                            newsCount: adminController.statistics['news'] ?? 0,
                            tasksCount: adminController.statistics['pending'] ??
                                0, // Showing pending tasks here
                            onManageUsersTap: () => Get.toNamed('/manage-users'),
                            onTotalTasksTap: _showAllPendingTasksDialog,
                            onNewsFeedTap: () => Get.toNamed('/news'),
                            onOnlineUsersTap: _navigateToChatUsers,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.only(left: 24, bottom: 8),
                          child: Text(
                            "TASK",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'raleway',
                              fontSize: 16.sp,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
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
                                              ? Theme.of(context).colorScheme.onPrimary
                                              : const Color(0xFF3739B7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          size: 22.sp,
                                          color: isDark
                                              ? const Color(0xFF3739B7)
                                              : Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TabBar(
                                controller: _tabController,
                                indicatorColor: isDark
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.primary,
                                labelColor: isDark
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.primary,
                                unselectedLabelColor:
                                    isDark ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7) : Colors.black54,
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
  final Set<String> _loadingUsers = <String>{};

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        widget.isDark ? const Color(0xFF292B3A) : Theme.of(context).primaryColor;
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
          orElse: () => <String, dynamic>{},
        );
        if (doc.isEmpty) {
          return const SizedBox.shrink();
        }
        // Map doc to Task object
        final task = Task.fromMap(doc, doc['id'] ?? doc['taskId'] ?? '');
        return TaskCardWidget(
          task: task,
          isCompleted: task.status == 'Completed',
          isDark: widget.isDark,
        );
      },
    );
  }
}
