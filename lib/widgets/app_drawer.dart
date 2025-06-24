// widgets/app_drawer.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../controllers/auth_controller.dart';
import '../controllers/task_controller.dart';
import '../models/task_model.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthController authController = Get.find<AuthController>();
  final TaskController taskController = Get.find<TaskController>();

  bool _logoutHovered = false;
  bool _showCalendar = false;
  DateTime _focusedDay = DateTime.now();
  List<Task> _userTasks = [];

  @override
  void initState() {
    super.initState();
    _loadUserTasks();
  }

  Future<void> _loadUserTasks() async {
    final assignedTasks = await taskController.getMyAssignedTasks();
    final createdTasks = await taskController.getMyCreatedTasks();

    final allTasks = [...assignedTasks, ...createdTasks];
    final uniqueTasks = <String, Task>{};
    for (var task in allTasks) {
      uniqueTasks[task.taskId] = task;
    }

    setState(() {
      _userTasks = uniqueTasks.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            /// Header
           Container(
              height: 200.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [Colors.grey[900]!, Colors.grey[800]!]
                      : [
                          Theme.of(context).primaryColor,
                          Colors.lightBlueAccent
                        ],
                ),
              ),
              child: Stack(
                children: [
                  // Radial Rings Anchored to Avatar
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ConcentricCirclePainter(
                        centerOffset:
                            Offset(70.w, 90.h), // match avatar position
                        ringColor: isDark
                            ? Colors.white54
                            : Colors.white,
                      ),
                    ),
                  ),

                  // Avatar + Name + Email Row
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 40.r,
                          backgroundImage: authController
                                  .profilePic.value.isNotEmpty
                              ? NetworkImage(authController.profilePic.value)
                              : null,
                          child: authController.profilePic.value.isEmpty
                              ? Text(
                                  authController.fullName.value.isNotEmpty
                                      ? authController.fullName.value[0]
                                          .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 28.sp,
                                    fontFamily: 'Raleway',
                                    color: Theme.of(context).primaryColor,
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authController.fullName.value,
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Raleway',
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                authController.currentUser?.email ?? '',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Raleway',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),





            /// Calendar Toggle
            /// Calendar Toggle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
                child: ListTile(
                  leading: Icon(Icons.calendar_today,
                      color: _showCalendar
                          ? Theme.of(context).primaryColor
                          : null),
                  title: Text(
                    _showCalendar ? 'Hide Calendar' : 'Show Calendar',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _showCalendar
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  onTap: () => setState(() => _showCalendar = !_showCalendar),
                ),
              ),
            ),


            if (_showCalendar)
              Container(
                height: screenHeight * 0.45,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: TableCalendar(
                        firstDay:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: Icon(Icons.chevron_left),
                          rightChevronIcon: Icon(Icons.chevron_right),
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() => _focusedDay = focusedDay);
                        },
                      ),
                    ),
                  ),
                ),
              ),

            /// Menu Section
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  _buildCardTile(Icons.home, 'Home', '/home'),
                  _buildCardTile(Icons.person, 'Profile', '/profile'),
                  _buildCardTile(Icons.settings, 'Settings', '/settings'),
                  _buildMyTasksCard(),
                  _buildDarkModeCard(isDark),
                ],
              ),
            ),

            /// Logout Button
            Padding(
              padding: EdgeInsets.all(16.w),
              child: MouseRegion(
                onEnter: (_) => setState(() => _logoutHovered = true),
                onExit: (_) => setState(() => _logoutHovered = false),
                child: Card(
                  elevation: 2,
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ListTile(
                    leading: AnimatedRotation(
                      turns: _logoutHovered ? 0.25 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.logout, color: Colors.red),
                    ),
                    title: const Text('Logout',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: _showLogoutConfirmation,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTile(IconData icon, String title, String route) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).iconTheme.color),
        title: Text(title,
            style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).textTheme.bodyLarge?.color)),
        onTap: () {
          Get.back();
          Get.toNamed(route);
        },
      ),
    );
  }

  Widget _buildMyTasksCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ExpansionTile(
        leading: Icon(Icons.task, color: Theme.of(context).iconTheme.color),
        title: Row(
          children: [
            Text('My Tasks',
                style: TextStyle(
                    fontSize: 16.sp,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            SizedBox(width: 8.w),
            if (taskController.newTaskCount.value > 0)
              Chip(
                label: Text(
                  taskController.newTaskCount.value.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
          ],
        ),
        children: _userTasks.isEmpty
            ? [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    'No tasks assigned',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
              ]
            : _userTasks.map((task) => _buildTaskItem(task)).toList(),
      ),
    );
  }

  Widget _buildDarkModeCard(bool isDark) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: SwitchListTile(
        title: Text('Dark Mode',
            style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).textTheme.bodyLarge?.color)),
        value: isDark,
        onChanged: (value) {
          Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
        },
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = task.status == 'Completed';

    return ListTile(
      leading: Icon(
        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isCompleted ? Colors.green : Theme.of(context).primaryColor,
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        'Due: ${_formatDate(task.timestamp)}\nStatus: ${task.status}',
        style: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      onTap: () {},
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No deadline';
    if (date is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(date.toDate());
    }
    return 'Invalid date';
  }

  Future<void> _showLogoutConfirmation() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Confirm Logout',
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text('Are you sure you want to sign out?',
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        backgroundColor: Theme.of(context).cardColor,
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel',
                style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authController.signOut();
      Get.offAllNamed('/login');
    }
  }
}

class ConcentricCirclePainter extends CustomPainter {
  final Offset centerOffset;
  final Color ringColor;

  ConcentricCirclePainter({
    required this.centerOffset,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final List<double> radii = [60, 100, 140]; // adjust as needed
    final List<double> opacities = [0.4, 0.25, 0.12]; // fading intensity

    for (int i = 0; i < radii.length; i++) {
      paint.color = ringColor.withOpacity(opacities[i]);
      canvas.drawCircle(centerOffset, radii[i], paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
