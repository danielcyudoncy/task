// views/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task/utils/constants/app_strings.dart';
import 'package:task/utils/constants/app_styles.dart';
import 'package:task/widgets/assign_task_dialog.dart';
import 'package:task/widgets/dashboard_cards_widget.dart';
import 'package:task/widgets/header_widget.dart';
import 'package:task/widgets/manage_users_dialog.dart';
import 'package:task/widgets/task_details_dialog.dart';
import 'package:task/widgets/task_tab.dart';
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

  void _showAssignTaskDialog([Map<String, dynamic>? user]) {
    showDialog(
      context: context,
      builder: (_) => AssignTaskDialog(
        user: user,
        adminController: adminController,
      ),
    );
  }

  void _showManageUsersDialog() {
    showDialog(
      context: context,
      builder: (_) => ManageUsersDialog(
        manageUsersController: manageUsersController,
        onAssignTap: _showAssignTaskDialog,
      ),
    );
  }

  void _showTaskDetailDialog(String title) {
    showDialog(
      context: context,
      builder: (_) => TaskDetailsDialog(
        title: title,
        adminController: adminController,
      ),
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
                            style: AppStyles.sectionTitleStyle.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF3739B7),
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
                            onTotalTasksTap: () {}, // Add a dialog if needed
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
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF3739B7),
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
                                    TasksTab(
                                      tasks: adminController.pendingTaskTitles,
                                      taskDocs:
                                          adminController.taskSnapshotDocs,
                                      onTaskTap: _showTaskDetailDialog,
                                      isDark: isDark,
                                    ),
                                    TasksTab(
                                      tasks:
                                          adminController.completedTaskTitles,
                                      taskDocs:
                                          adminController.taskSnapshotDocs,
                                      onTaskTap: _showTaskDetailDialog,
                                      isDark: isDark,
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
