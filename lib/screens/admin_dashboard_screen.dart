// screens/admin_dashboard_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/notification_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/utils/devices/app_devices.dart';
import 'package:task/widgets/app_drawer.dart';
import 'package:task/widgets/enhanced_dashboard_cards.dart';

import '../controllers/performance_controller.dart';
import 'package:task/widgets/user_performance_tab.dart';
import 'package:task/widgets/user_header.dart';
import 'package:task/widgets/user_nav_bar.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/manage_users_controller.dart';

// Extracted components
import '../widgets/dialogs/task_detail_dialog.dart';
import '../widgets/dialogs/pending_tasks_dialog.dart';
import '../widgets/tabs/admin_tabs.dart';
import '../widgets/tabs/task_approval_tab.dart' as approval_tab;

class AdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminController>(() => AdminController());
    Get.lazyPut<PerformanceController>(() => PerformanceController());
  }
}

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
  late final PerformanceController performanceController;

  late TabController _tabController;
  String? selectedTaskTitle;
  final Map<String, Map<String, String>> userCache = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);

    // Initialize performance controller
    performanceController = Get.find<PerformanceController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      adminController.fetchDashboardData();
      adminController.fetchStatistics();
      // No need to manually fetch users; ManageUsersController now uses a real-time stream.
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
        final imageUrl = data['imageUrl'] ?? "";
        userCache[userId] = {"name": name, "role": role, "imageUrl": imageUrl};
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            refresh();
          }
        });
        return {"name": name, "role": role};
      }
    } catch (e) {
      debugPrint('Failed to fetch user data for $userId: $e');
      // Continue with fallback data
    }
    userCache[userId] = {"name": userId, "role": "Unknown"};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        refresh();
      }
    });
    return {"name": userId, "role": "Unknown"};
  }

  void _showTaskDetailDialog(String title) {
    TaskDetailDialog.show(
      context: context,
      title: title,
      taskSnapshotDocs: adminController.taskSnapshotDocs,
      userCache: userCache,
      getUserNameAndRole: getUserNameAndRole,
    );
  }

  void _showAllPendingTasksDialog() {
    PendingTasksDialog.show(
      context: context,
      userCache: userCache,
      getUserNameAndRole: getUserNameAndRole,
      onTaskTap: _showTaskDetailDialog,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = AppDevices.isTablet(context);
    AppDevices.getScreenWidth(context);

    return GetX<AdminController>(
      builder: (adminController) {
        if (adminController.isLoading.value ||
            adminController.isStatsLoading.value) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          key: _scaffoldKey,
          drawer: const AppDrawer(),
          body: SafeArea(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? [Colors.grey[900]!, Colors.grey[800]!]
                        .reduce((value, element) => value)
                    : Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserHeader(isDark: isDark, scaffoldKey: _scaffoldKey),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 32.0 : 16.0,
                            ),
                            // --- Enhanced Dashboard Cards ---
                            child: EnhancedDashboardCardsWidget(
                              onManageUsersTap: () {
                                Get.find<SettingsController>()
                                    .triggerFeedback();
                                Get.toNamed('/manage-users');
                              },
                              onTotalTasksTap: () {
                                Get.find<SettingsController>()
                                    .triggerFeedback();
                                _showAllPendingTasksDialog();
                              },
                              onNewsFeedTap: () {
                                Get.find<SettingsController>()
                                    .triggerFeedback();
                                Get.toNamed('/news');
                              },
                              onOnlineUsersTap: () {
                                Get.find<SettingsController>()
                                    .triggerFeedback();
                                Get.toNamed('/admin-chat');
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: EdgeInsets.only(
                              left: isTablet ? 32.0 : 24.0,
                              bottom: 8,
                            ),
                            child: Text(
                              "TASK",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontFamily: 'raleway',
                                fontSize: isTablet ? 18.sp : 16.sp,
                                color:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: isDark
                                  ? LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.grey[900]!,
                                        Colors.grey[800]!
                                      ],
                                    )
                                  : LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.grey[50]!,
                                        Colors.grey[100]!
                                      ],
                                    ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(26),
                                topRight: Radius.circular(26),
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 32.0 : 16.0,
                                      vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            Get.toNamed('/create-task'),
                                        child: Container(
                                          width: 34.w,
                                          height: 34.h,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                : const Color(0xFF3739B7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            size: 22.sp,
                                            color: isDark
                                                ? const Color(0xFF3739B7)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            Get.toNamed('/manage-users'),
                                        child: Container(
                                          width: 34.w,
                                          height: 34.h,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                : const Color(0xFF3739B7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.people,
                                            size: 22.sp,
                                            color: isDark
                                                ? const Color(0xFF3739B7)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () =>
                                            Get.toNamed('/admin-chat'),
                                        child: Container(
                                          width: 34.w,
                                          height: 34.h,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                : const Color(0xFF3739B7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.chat,
                                            size: 22.sp,
                                            color: isDark
                                                ? const Color(0xFF3739B7)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.48,
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      TasksTab(
                                        userCache: userCache,
                                        getUserNameAndRole:
                                            getUserNameAndRole,
                                        showTaskDetailDialog:
                                            _showTaskDetailDialog,
                                        taskType: 'pending',
                                      ),
                                      TasksTab(
                                        userCache: userCache,
                                        getUserNameAndRole:
                                            getUserNameAndRole,
                                        showTaskDetailDialog:
                                            _showTaskDetailDialog,
                                        taskType: 'completed',
                                      ),
                                      approval_tab.TaskApprovalTab(
                                        userCache: userCache,
                                        getUserNameAndRole:
                                            getUserNameAndRole,
                                      ),
                                      const UserPerformanceTab(),
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
          bottomNavigationBar: UserNavBar(currentIndex: 0),
        );
      },
    );
  }
}