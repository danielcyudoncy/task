// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:task/controllers/settings_controller.dart';

import 'package:task/widgets/app_drawer.dart';
import 'package:task/features/librarian/widgets/librarian_app_drawer.dart';
import 'package:task/widgets/task_section.dart';
import 'package:task/widgets/user_nav_bar.dart';
import '../controllers/auth_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/notification_controller.dart';
import 'package:task/widgets/user_dashboard_cards_widget.dart';
import 'package:task/screens/created_tasks_screen.dart';
import 'package:task/service/presence_service.dart' as ps;

import '../utils/constants/app_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AuthController authController;
  late final TaskController taskController;
  late final NotificationController notificationController;
  late final SettingsController settingsController;

  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize controllers safely
    _initializeControllers();

    // Add a small delay to ensure the screen is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeControllers() {
    // Safely get controllers, may return null if not registered yet
    authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : AuthController();
    taskController = Get.isRegistered<TaskController>()
        ? Get.find<TaskController>()
        : TaskController();
    notificationController = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : NotificationController();
    // SettingsController requires AudioPlayer parameter, so only use it if registered
    if (Get.isRegistered<SettingsController>()) {
      settingsController = Get.find<SettingsController>();
    }
  }

  void _initializeData() {
    // Use a small delay to ensure the screen is fully built before fetching data
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        try {
          // Only proceed if all controllers are properly initialized
          if (!Get.isRegistered<TaskController>() ||
              !Get.isRegistered<NotificationController>()) {
            debugPrint(
                'HomeScreen: Controllers not ready yet, will retry later');
            return;
          }

          final isAdmin = authController.isAdmin.value;
          if (isAdmin) {
            taskController.fetchTasks();
          } else {
            taskController.fetchRelevantTasksForUser();
          }
          taskController.fetchTaskCounts();

          notificationController.fetchNotifications();
        } catch (e) {
          // Error handling - could implement proper logging here
          debugPrint('HomeScreen: Error during initialization: $e');
        }
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
    final String userId = authController.currentUser?.uid ?? '';

    return Scaffold(
      key: _scaffoldKey,
      drawer: authController.userRole.value == 'Librarian'
          ? const LibrarianAppDrawer()
          : const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/create-task'),
        backgroundColor: isDark
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.add,
          color: isDark
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? [Colors.grey[900]!, Colors.grey[800]!]
                  .reduce((value, element) => value)
              : Theme.of(context).colorScheme.primary,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              _HomeHeader(
                authController: authController,
                notificationController: notificationController,
                settingsController: settingsController,
                scaffoldKey: _scaffoldKey,
                tabController: _tabController,
                isPortrait: isPortrait,
              ),
              // Scrollable content with pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Refresh all data
                    await Future.wait([
                      taskController.fetchRelevantTasksForUser(),
                      taskController.fetchTaskCounts(),
                      notificationController.fetchNotifications(),
                    ]);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 8.h),
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: Builder(
                              builder: (context) {
                                final presenceService =
                                    Get.isRegistered<ps.PresenceService>()
                                        ? Get.find<ps.PresenceService>()
                                        : Get.put(ps.PresenceService());
                                
                                return UserDashboardCardsWidget(
                                  assignedTasksCount: notificationController
                                      .taskAssignmentUnreadCount,
                                  onlineUsersStream: (() async* {
                                    yield presenceService.onlineUsersCount.value;
                                    yield* presenceService.onlineUsersCount.stream;
                                  })(),
                                  tasksCreatedStream: taskController
                                      .createdTasksCountStream(userId),
                                  newsFeedStream: Stream.value(3),
                                  onAssignedTasksTap: () {
                                    // Display-only card - no navigation needed
                                  },
                                  onOnlineUsersTap: () {
                                    final authController =
                                        Get.find<AuthController>();
                                    if (authController.userRole.value ==
                                        'Admin') {
                                      Get.toNamed('/admin-chat');
                                    } else {
                                      Get.toNamed('/user-chat-list');
                                    }
                                  },
                                  onTasksCreatedTap: () {
                                    Get.to(() => const CreatedTasksScreen());
                                  },
                                  onNewsFeedTap: () {
                                    Get.toNamed('/news');
                                  },
                                );
                              },
                            ),
                          ),
                        ),
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
                          height: 400,
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Theme.of(context).colorScheme.surface,
                                      Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Theme.of(context).colorScheme.surface,
                                      Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
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
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
              ),
              // UserNavBar at the bottom, outside scrollable area
              UserNavBar(),
            ],
          ),
        ),
      ),
    );
  }
}

// Extracted Header Widget for better code organization
class _HomeHeader extends StatelessWidget {
  final AuthController authController;
  final NotificationController notificationController;
  final SettingsController settingsController;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final TabController tabController;
  final bool isPortrait;

  const _HomeHeader({
    required this.authController,
    required this.notificationController,
    required this.settingsController,
    required this.scaffoldKey,
    required this.tabController,
    required this.isPortrait,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  if (scaffoldKey.currentState != null) {
                    scaffoldKey.currentState!.openDrawer();
                  }
                },
              ),
              // Clickable Avatar with Notification Badge
              GestureDetector(
                onTap: () {
                  settingsController.triggerFeedback();
                  Get.toNamed('/notifications');
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Avatar
                      Obx(() {
                        if (!Get.isRegistered<AuthController>()) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
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
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: isPortrait ? 20.sp : 16.sp,
                            backgroundColor: Colors.white,
                            child: profilePic.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: profilePic,
                                      width: isPortrait ? 40.sp : 32.sp,
                                      height: isPortrait ? 40.sp : 32.sp,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Text(
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
                                      ),
                                    ),
                                  )
                                : Text(
                                    fullName.isNotEmpty
                                        ? fullName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: isPortrait ? 20.sp : 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        );
                      }),
                      // Notification Badge
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Obx(() {
                          if (!Get.isRegistered<NotificationController>()) {
                            return const SizedBox();
                          }

                          final unreadCount =
                              notificationController.unreadCount.value;

                          return unreadCount > 0
                              ? Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      unreadCount > 9 ? '9+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox();
                        }),
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
    );
  }
}
