// views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/widgets/app_drawer.dart';
import 'package:task/widgets/stats_section.dart';
import 'package:task/widgets/task_section.dart';
import 'package:task/widgets/user_nav_bar.dart';
import '../controllers/auth_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/notification_controller.dart';
import 'package:task/widgets/user_dashboard_cards_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    
    // Add a small delay to ensure the screen is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    debugPrint("HomeScreen: Initializing data");
    // Use a small delay to ensure the screen is fully built before fetching data
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        debugPrint("HomeScreen: Fetching data");
        try {
          taskController.fetchTasks();
          taskController.fetchTaskCounts();
          notificationController.fetchNotifications();
          debugPrint("HomeScreen: Data fetching initiated");
        } catch (e) {
          debugPrint("HomeScreen: Error initializing data: $e");
        }
      } else {
        debugPrint("HomeScreen: Widget not mounted, skipping data fetch");
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("HomeScreen: Building widget");
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate the number of tasks assigned to the user (matches notification logic)
    final String userId = authController.currentUser?.uid ?? '';

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: SizedBox.expand(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).canvasColor
                : Theme.of(context).colorScheme.primary,
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (menu, avatar, greeting, email)
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
                                      return Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Theme.of(context).colorScheme.onPrimary
                                                : Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 20.sp,
                                          backgroundColor: Colors.white,
                                          child: Text(
                                            '?',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    final profilePic = authController.profilePic.value;
                                    final fullName = authController.fullName.value;
                                    debugPrint('HomeScreen: Using profilePic for user: \\${authController.currentUser?.uid} pic: \\$profilePic');
                                    return Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Theme.of(context).colorScheme.onPrimary
                                              : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 20.sp,
                                        backgroundColor: Colors.white,
                                        backgroundImage: profilePic.isNotEmpty
                                            ? NetworkImage(profilePic)
                                            : null,
                                        child: profilePic.isEmpty
                                            ? Text(
                                                fullName.isNotEmpty
                                                    ? fullName[0].toUpperCase()
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
                                      ),
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
                                        
                                        final unreadCount = notificationController.unreadCount.value;
                                        
                                        return unreadCount > 0
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
                                                    unreadCount > 9
                                                        ? '9+'
                                                        : '$unreadCount',
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
                            Obx(() => Center(
                              child: Text(
                                "Hello, ${authController.fullName.value.isNotEmpty ? authController.fullName.value : 'User'}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Raleway',
                                ),
                              ),
                            )),
                            SizedBox(height: 4.h),
                            Obx(() => Center(
                              child: Text(
                                authController.currentUser?.email ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .where('isOnline', isEqualTo: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              int onlineUsersCount = 0;
                              if (snapshot.hasData) {
                                onlineUsersCount = snapshot.data!.docs.length;
                              }
                              return StreamBuilder<int>(
                                stream: taskController.assignedTasksCountStream(userId),
                                builder: (context, assignedSnapshot) {
                                  debugPrint('Assigned tasks stream (all statuses): \\${assignedSnapshot.data}');
                                  final assignedTasksToday = assignedSnapshot.data ?? 0;
                                  return UserDashboardCardsWidget(
                                    assignedTasksToday: assignedTasksToday,
                                    onlineUsersCount: onlineUsersCount,
                                    tasksCreatedCount: 0, // TODO: Replace with actual count
                                    newsFeedCount: 0, // TODO: Replace with actual count
                                    onAssignedTasksTap: () {
                                      _tabController.animateTo(1);
                                    },
                                    onOnlineUsersTap: () {
                                      Get.toNamed('/all-users-chat');
                                    },
                                    onTasksCreatedTap: () {
                                      // TODO: Implement navigation or action for Task Created
                                    },
                                    onNewsFeedTap: () {
                                      // TODO: Implement navigation or action for News Feed
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        StatsSection(
                          taskController: taskController,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.only(left: 24, bottom: 8),
                          child: Text(
                            AppStrings.task,
                            style: AppStyles.sectionTitleStyle.copyWith(
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
                          child: TasksSection(
                            tabController: _tabController,
                            authController: authController,
                            taskController: taskController,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // UserNavBar at the bottom, outside scrollable area
                const UserNavBar(
                  currentIndex: 0, // Home screen is index 0
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
