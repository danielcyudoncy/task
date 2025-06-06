// views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart';
import '../controllers/task_controller.dart';
import '../widgets/user_nav_bar.dart';
import '../utils/constants/app_colors.dart';
import '../utils/constants/app_strings.dart';
import '../utils/constants/app_styles.dart';
import '../utils/themes/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();
  final TaskController taskController = Get.find<TaskController>();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    taskController.fetchTasks();
    taskController.fetchTaskCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getGradient(context),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user avatar, welcome, name, logo and logout button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Obx(() {
                      final user = authController.currentUser;
                      final userName = authController.fullName.value.isNotEmpty
                          ? authController.fullName.value
                          : AppStrings.unknownUser;
                      final photoUrl = user?.photoURL;
                      return CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            isDark ? AppColors.white : AppColors.primaryColor,
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
                                  color: isDark
                                      ? AppColors.primaryColor
                                      : Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      );
                    }),
                    const SizedBox(width: 12),
                    Obx(() {
                      final userName = authController.fullName.value.isNotEmpty
                          ? authController.fullName.value
                          : AppStrings.unknownUser;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.welcome,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            userName,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      );
                    }),
                    const Spacer(),
                    // Circular Logo
                    Container(
                      width: 40,
                      height: 40,
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
                          'assets/png/logo.png', // <-- Replace with your logo asset path
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout,
                          color: Colors.white, size: 28),
                      onPressed: () {
                        // Add your logout logic here
                        Get.offAllNamed("/login");
                      },
                      tooltip: "Logout",
                    ),
                  ],
                ),
              ),
              // Section Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  AppStrings.dailyAssignments,
                  style: AppStyles.sectionTitleStyle.copyWith(
                    color: Colors.white, // Always white
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Stat cards row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Obx(() => _statCard(
                          icon: Icons.create,
                          label: AppStrings.totalTaskCreated,
                          value:
                              taskController.totalTaskCreated.value.toString(),
                          color: const Color(0xFF9FA8DA),
                        )),
                    const SizedBox(width: 16),
                    Obx(() => _statCard(
                          icon: Icons.assignment,
                          label: AppStrings.taskAssigned,
                          value: taskController.taskAssigned.value.toString(),
                          color: const Color(0xFF9FA8DA),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  AppStrings.task,
                  style: AppStyles.sectionTitleStyle.copyWith(
                    color: isDark ? AppColors.white : const Color(0xFF3739B7),
                  ),
                ),
              ),
              // White (or dark) container with task tabs and cards
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Add button row
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 18,
                          left: 16,
                          right: 16,
                          bottom: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () => Get.toNamed('/create-task'),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.white
                                      : const Color(0xFF3739B7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: isDark
                                      ? const Color(0xFF3739B7)
                                      : Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tabs
                      TabBar(
                        controller: _tabController,
                        indicatorColor:
                            isDark ? AppColors.white : const Color(0xFF3739B7),
                        indicatorWeight: 2.5,
                        labelColor:
                            isDark ? AppColors.white : const Color(0xFF3739B7),
                        unselectedLabelColor:
                            isDark ? Colors.white70 : Colors.black54,
                        labelStyle: AppStyles.tabSelectedStyle.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        unselectedLabelStyle: AppStyles.tabUnselectedStyle,
                        tabs: const [
                          Tab(text: AppStrings.notCompleted),
                          Tab(text: AppStrings.completed),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // TabBarView for not completed and completed tasks
                      Expanded(
                        child: Obx(() {
                          final notCompletedTasks = taskController.tasks
                              .where((t) => t.status != "Completed")
                              .toList();
                          final completedTasks = taskController.tasks
                              .where((t) => t.status == "Completed")
                              .toList();

                          return TabBarView(
                            controller: _tabController,
                            children: [
                              _TaskListTab(
                                isCompleted: false,
                                isDark: isDark,
                                tasks: notCompletedTasks,
                              ),
                              _TaskListTab(
                                isCompleted: true,
                                isDark: isDark,
                                tasks: completedTasks,
                              ),
                            ],
                          );
                        }),
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
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 110,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          gradient: AppStyles.cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppStyles.cardTitleStyle,
            ),
            Text(
              value,
              style: AppStyles.cardValueStyle,
            ),
          ],
        ),
      ),
    );
  }
}

// Task list tab widget
class _TaskListTab extends StatelessWidget {
  final bool isCompleted;
  final bool isDark;
  final List<dynamic> tasks;
  const _TaskListTab({
    required this.isCompleted,
    required this.isDark,
    required this.tasks,
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
        child: Text(
          "No tasks.",
          style: TextStyle(color: emptyListColor),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final t = tasks[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 7.0),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title ?? "",
                  style: AppStyles.cardTitleStyle,
                ),
                const SizedBox(height: 7),
                Text(
                  t.description ?? AppStrings.taskDetails,
                  style: AppStyles.cardValueStyle.copyWith(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
               Text(
                  "Due Date ${t.timestamp != null ? DateFormat('yyyy-MM-dd').format(t.timestamp!.toDate()) : 'N/A'}",
                  style: AppStyles.cardValueStyle.copyWith(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
               
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.bottomRight,
                  child:
                      Icon(Icons.edit_note_rounded, color: textColor, size: 22),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
