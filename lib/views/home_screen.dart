// views/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/utils/constants/app_colors.dart';
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
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Theme.of(context).colorScheme.primary,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                constraints:  BoxConstraints(
                                  minWidth: 16.w,
                                  minHeight: 16.h,
                                ),
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  style:  TextStyle(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(() => _statCard(
                            icon: Icons.create,
                            label: AppStrings.taskCreated,
                            value: taskController.totalTaskCreated.value
                                .toString(),
                            color: isDark
                                ? Colors.white
                                : AppColors.secondaryColor,
                          )),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(() => _statCard(
                            iconWidget: Stack(
                              children: [
                                Icon(Icons.assignment,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.secondaryColor,
                                    size: 32),
                                if (taskController.newTaskCount.value > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
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
                                        taskController.newTaskCount.value > 9
                                            ? '9+'
                                            : '${taskController.newTaskCount.value}',
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
                            ),
                            icon: Icons.assignment,
                            label: AppStrings.taskAssigned,
                            value: taskController.taskAssigned.value.toString(),
                            color: isDark
                                ? const Color(0xFF9FA8DA)
                                : AppColors.secondaryColor,
                          )),
                    ),
                  ],
                ),
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
                                width: 34.w,
                                height: 34.h,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: isDark
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TabBar(
                        controller: _tabController,
                        isScrollable: false,
                        indicatorColor: isDark
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        indicatorWeight: 2.5,
                        labelColor: isDark
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
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
                    Expanded(
  child: Obx(() {
    final userId = authController.auth.currentUser?.uid ?? "";
    final tasks = taskController.tasks;

    final taskMap = { for (var task in tasks) task.taskId : task };

    final notCompletedTasks = taskMap.values.where((t) {
      return (t.status != "Completed") &&
          (t.createdById == userId ||
              t.assignedTo == userId ||
              t.assignedReporterId == userId ||
              t.assignedCameramanId == userId);
    }).toList();

    final completedTasks = taskMap.values
        .where((t) =>
            t.status == "Completed" &&
            (t.createdById == userId ||
                t.assignedTo == userId ||
                t.assignedReporterId == userId ||
                t.assignedCameramanId == userId))
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
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 100,
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.saveColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          iconWidget ??
              Icon(
                icon,
                color: color,
                size: 32,
              ),
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
    );
  }
}

class _TaskListTab extends StatelessWidget {
  final bool isCompleted;
  final bool isDark;
  final List<dynamic> tasks;
  const _TaskListTab({
    required this.isCompleted,
    required this.isDark,
    required this.tasks,
  });

  void _editTask(BuildContext context, dynamic task) {
    final TextEditingController titleController =
        TextEditingController(text: task.title);
    final TextEditingController descriptionController =
        TextEditingController(text: task.description);
    String status = task.status ?? "Pending";
    final taskController = Get.find<TaskController>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Task"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: "Status"),
                items: ['Pending', 'In Progress', 'Completed']
                    .map((String value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) status = newValue;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await taskController.updateTask(
                task.taskId,
                titleController.text,
                descriptionController.text,
                status,
              );
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              Get.snackbar("Success", "Task updated successfully",
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteTask(dynamic task) async {
    final taskController = Get.find<TaskController>();
    await taskController.deleteTask(task.taskId);
    Get.snackbar("Success: Success", "Task deleted",
        snackPosition: SnackPosition.BOTTOM);
  }

  void _completeTask(dynamic task) async {
    final taskController = Get.find<TaskController>();
    await taskController.updateTaskStatus(task.taskId, "Completed");
    Get.snackbar("Success", "Task marked as completed",
        snackPosition: SnackPosition.BOTTOM);
  }

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
        return Dismissible(
          key: ValueKey(t.taskId ?? t.hashCode),
          background: !isCompleted
              ? Container(
                  color: Colors.green,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Row(
                    children: [
                      Icon(Icons.check, color: Colors.white),
                      SizedBox(width: 8),
                      Text("Complete", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                )
              : Container(),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 8),
                Text("Delete", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd && !isCompleted) {
              _completeTask(t);
              return false;
            } else if (direction == DismissDirection.endToStart) {
              return await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Delete Task"),
                  content:
                      const Text("Are you sure you want to delete this task?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text("Delete",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            }
            return false;
          },
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              _deleteTask(t);
            }
          },
          child: Padding(
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
                  Text(t.title ?? "", style: AppStyles.cardTitleStyle),
                  const SizedBox(height: 7),
                  Text(
                    t.description ?? AppStrings.taskDetails,
                    style: AppStyles.cardValueStyle.copyWith(
                      color: subTextColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Due Date ${t.timestamp != null ? DateFormat('yyyy-MM-dd').format(t.timestamp!.toDate()) : 'N/A'}",
                    style: AppStyles.cardValueStyle.copyWith(
                      color: subTextColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(
                      icon: const Icon(Icons.edit_note_rounded,
                          color: textColor, size: 22),
                      onPressed: () => _editTask(context, t),
                      tooltip: "Edit Task",
                    ),
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
