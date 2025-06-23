// views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
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

  late TabController _tabController;

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
      drawer: AppDrawer(),
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: const Text(''),
        
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Theme.of(context).colorScheme.primary,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Your existing header section here
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Obx(() {
                      final user = authController.currentUser;
                      final userName = authController.fullName.value.isNotEmpty
                          ? authController.fullName.value
                          : AppStrings.unknownUser;
                      final photoUrl = user?.photoURL;

                      return CircleAvatar(
                        radius: 20.sp,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      );
                    }),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() {
                        final userName =
                            authController.fullName.value.isNotEmpty
                                ? authController.fullName.value
                                : AppStrings.unknownUser;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.welcome,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'raleway',
                                fontSize: 24.sp,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                    ),
                    Container(
                      width: 30.w,
                      height: 30.h,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/png/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Obx(() {
                      int unread = notificationController.unreadCount.value;
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              Get.toNamed('/notifications');
                            },
                            tooltip: "Notifications",
                          ),
                          if (unread > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 16.w,
                                  minHeight: 16.h,
                                ),
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                    IconButton(
                      icon: const Icon(Icons.logout,
                          color: Colors.white, size: 28),
                      onPressed: () async {
                        await authController.logout();
                        Get.offAllNamed("/login");
                      },
                      tooltip: "Logout",
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
