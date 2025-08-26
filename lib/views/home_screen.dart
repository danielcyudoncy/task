// views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';

import 'package:task/widgets/app_drawer.dart';
import 'package:task/features/librarian/widgets/librarian_app_drawer.dart';
import 'package:task/widgets/task_section.dart';
import 'package:task/widgets/user_nav_bar.dart';
import '../controllers/auth_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/notification_controller.dart';
import 'package:task/widgets/user_dashboard_cards_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
    // Use a small delay to ensure the screen is fully built before fetching data
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        try {
          final isAdmin = authController.isAdmin.value;
          if (isAdmin) {
            taskController.fetchTasks();
          } else {
            taskController.fetchRelevantTasksForUser();
          }
          taskController.fetchTaskCounts();
          
          notificationController.fetchNotifications();
        } catch (e) {
          // debugPrint("HomeScreen: Error initializing data: $e");
        }
      } else {
        // debugPrint("HomeScreen: Widget not mounted, skipping data fetch");
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    // Calculate the number of tasks assigned to the user (matches notification logic)
    final String userId = authController.currentUser?.uid ?? '';

    return Scaffold(
      key: _scaffoldKey,
      drawer: authController.userRole.value == 'Librarian' ? const LibrarianAppDrawer() : const AppDrawer(),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w, 
                    vertical: isPortrait ? 16.h : 8.h,
                  ),
                  child: Column(
                    children: [
                      // First Row: Menu + Avatar with Notification
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.menu,
                              color: Colors.white, 
                              size: isPortrait ? 28.sp : 24.sp,
                            ),
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
                                        radius: isPortrait ? 20.sp : 16.sp,
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
                                                  fontSize: isPortrait ? 20.sp : 16.sp,
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
                        padding: EdgeInsets.only(
                          left: 8.w, 
                          top: isPortrait ? 8.h : 4.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() => Center(
                              child: Text(
                                "${'hello'.tr}, ${authController.fullName.value.isNotEmpty ? authController.fullName.value : 'user'.tr}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isPortrait ? 20.sp : 16.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Raleway',
                                ),
                              ),
                            )),
                            SizedBox(height: isPortrait ? 4.h : 2.h),
                            Obx(() => Center(
                              child: Text(
                                authController.currentUser?.email ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isPortrait ? 14.sp : 12.sp,
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
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .where('isOnline', isEqualTo: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .where('isOnline', isEqualTo: true)
                                      .snapshots(),
                                  builder: (context, onlineSnapshot) {
                                    final onlineUsersCount = onlineSnapshot.data?.docs.length ?? 0;
                                    return StreamBuilder<int>(
                                      stream: taskController.assignedTasksCountStream(userId),
                                      builder: (context, createdSnapshot) {
                                        return UserDashboardCardsWidget(
                                          assignedTasksCount: notificationController.taskAssignmentUnreadCount,
                                          onlineUsersStream: Stream.value(onlineUsersCount),
                                          tasksCreatedStream: taskController.createdTasksCountStream(userId),
                                          newsFeedStream: Stream.value(3), // Static for now, can be replaced with a real stream
                                          onAssignedTasksTap: () {
                                            _tabController.animateTo(0);
                                            setState(() {
                                              _tabController.index = 0;
                                            });
                                          },
                                          onOnlineUsersTap: () {
                                            Get.toNamed('/all-users-chat');
                                          },
                                          onTasksCreatedTap: () {
                                            _tabController.animateTo(1);
                                            setState(() {
                                              _tabController.index = 1;
                                            });
                                          },
                                          onNewsFeedTap: () {
                                            Get.toNamed('/news');
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        // const SizedBox(height: 18),
                        // StatsSection(
                        //   taskController: taskController,
                        //   isDark: isDark,
                        // ),
                        // const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.only(left: 24, bottom: 8),
                          child: Text(
                            'task'.tr,
                            style: AppStyles.sectionTitleStyle.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 400, // Add explicit height constraint
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Theme.of(context).colorScheme.surface,
                                      Theme.of(context).colorScheme.surfaceVariant
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Theme.of(context).colorScheme.surface,
                                      Theme.of(context).colorScheme.surfaceVariant
                                    ],
                                  ),
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
