// views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/widgets/app_drawer.dart';
import 'package:task/widgets/stats_section.dart';
import 'package:task/widgets/task_section.dart';
import '../controllers/auth_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/notification_controller.dart';
import '../widgets/user_nav_bar.dart';
import '../utils/constants/app_strings.dart';
import '../utils/constants/app_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();
  final TaskController taskController = Get.find<TaskController>();
  final NotificationController notificationController =
      Get.find<NotificationController>();
      final SettingsController settingsController = Get.find<SettingsController>();

  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  void _initializeData() {
    taskController.fetchTasks();
    taskController.fetchTaskCounts();
    notificationController.fetchNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181B2A) : Theme.of(context).colorScheme.primary,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // New Header Implementation
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  children: [
                    // First Row: Menu + Avatar with Notification
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu,
                              color: Colors.white, size: 28.sp),
                          onPressed: () {
                            settingsController.triggerFeedback();
                            if (_scaffoldKey.currentState != null) {
                              _scaffoldKey.currentState!.openDrawer();
                            }
                          },
                        ),
                        // Clickable Avatar with Notification Badge
                        GestureDetector(
                          onTap: () {
                            settingsController.triggerFeedback(); // 👈 Add this
                            Get.toNamed('/notifications');
                          },

                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Avatar
                                Obx(() {
                                  // Add safety check to ensure observables are initialized
                                  if (!Get.isRegistered<AuthController>()) {
                                    return CircleAvatar(
                                      radius: 20.sp,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        '?',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  return CircleAvatar(
                                    radius: 20.sp,
                                    backgroundColor: Colors.white,
                                    backgroundImage: authController.profilePic.value.isNotEmpty
                                        ? NetworkImage(authController.profilePic.value)
                                        : null,
                                    child: authController.profilePic.value.isEmpty
                                        ? Text(
                                            authController.fullName.value
                                                    .isNotEmpty
                                                ? authController
                                                    .fullName.value[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  );
                                }),
                                // Notification Badge
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Obx(
                                    () {
                                      // Add safety check to ensure controller is registered
                                      if (!Get.isRegistered<NotificationController>()) {
                                        return const SizedBox();
                                      }
                                      
                                      return notificationController
                                                  .unreadCount.value >
                                              0
                                          ? Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2),
                                              ),
                                              constraints: BoxConstraints(
                                                minWidth: 20.w,
                                                minHeight: 20.h,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  notificationController
                                                              .unreadCount.value >
                                                          9
                                                      ? '9+'
                                                      : '${notificationController.unreadCount.value}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Second Row: Greeting + Email
                    Padding(
                      padding: EdgeInsets.only(left: 8.w, top: 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "Hello, ${Get.isRegistered<AuthController>() ? authController.fullName.value : 'User'}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Raleway',
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Center(
                            child: Text(
                              authController.currentUser?.email ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              StatsSection(
                taskController: taskController,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  AppStrings.task,
                  style: AppStyles.sectionTitleStyle.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: TasksSection(
                  tabController: _tabController,
                  authController: authController,
                  taskController: taskController,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const UserNavBar(currentIndex: 0),
    );
  }
}
