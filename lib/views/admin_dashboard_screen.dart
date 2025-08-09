// views/admin_dashboard_screen.dart
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/notification_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/utils/constants/app_strings.dart';
import 'package:task/utils/devices/app_devices.dart';
import 'package:task/widgets/app_drawer.dart';
import 'package:task/widgets/enhanced_dashboard_cards.dart';
import 'package:task/widgets/user_performance_tab.dart';
import '../controllers/performance_controller.dart';
import 'package:task/widgets/user_header.dart';
import 'package:task/widgets/user_nav_bar.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/manage_users_controller.dart';
import 'package:task/models/task_model.dart';
import 'package:task/widgets/task_card_widget.dart';


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
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize performance controller
    performanceController = Get.put(PerformanceController());
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      adminController.fetchDashboardData();
      adminController.fetchStatistics();
      manageUsersController.fetchUsers();
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
        userCache[userId] = {"name": name, "role": role};
        WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
        return {"name": name, "role": role};
      }
    // ignore: empty_catches
    } catch (e) {}
    userCache[userId] = {"name": userId, "role": "Unknown"};
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
    return {"name": userId, "role": "Unknown"};
  }



  void _navigateToChatUsers() async {
    Get.find<SettingsController>().triggerFeedback();
    
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      Get.back();
      Get.toNamed('/all-users-chat');
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Could not open chat: $e");
    }
  }


  void _showTaskDetailDialog(String title) {
    final doc = adminController.taskSnapshotDocs
        .firstWhereOrNull((d) => d['title'] == title);

    final creatorId = doc?['createdBy'] ?? 'Unknown';
    String dateStr = 'Unknown';
    if (doc?['timestamp'] != null) {
      final createdAt = doc?['timestamp'];
      DateTime dt;
      if (createdAt is Timestamp) {
        dt = createdAt.toDate();
      } else if (createdAt is DateTime) {
        dt = createdAt;
      } else {
        dt = DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
      }
      dateStr =
          "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2C3E50)
                      : Colors.white,
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF34495E)
                      : const Color(0xFFF8F9FA),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4A90E2),
                        const Color(0xFF357088),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Task Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        final userInfo = userCache[creatorId];
                        if (userInfo == null && creatorId != 'Unknown') {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            getUserNameAndRole(creatorId, () => setState(() {}));
                          });
                        }
                        final creatorName = userInfo?["name"] ?? 'Unknown';
                        final creatorRole = userInfo?["role"] ?? "Unknown";
                        final taskStatus = _getTaskStatus(title);
                        
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Task Title Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF3A4A5C)
                                    : const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.task_alt,
                                          color: const Color(0xFF4A90E2),
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Task Title',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Status Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF3A4A5C)
                                    : const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: taskStatus == 'Completed'
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : taskStatus == 'Not Completed'
                                              ? Colors.orange.withValues(alpha: 0.1)
                                              : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      taskStatus == 'Completed'
                                          ? Icons.check_circle_outline
                                          : taskStatus == 'Not Completed'
                                              ? Icons.pending_outlined
                                              : Icons.help_outline,
                                      color: taskStatus == 'Completed'
                                          ? Colors.green
                                          : taskStatus == 'Not Completed'
                                              ? Colors.orange
                                              : Colors.grey,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Status:',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: taskStatus == 'Completed'
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : taskStatus == 'Not Completed'
                                                ? Colors.orange.withValues(alpha: 0.1)
                                                : Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        taskStatus,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: taskStatus == 'Completed'
                                              ? Colors.green
                                              : taskStatus == 'Not Completed'
                                                  ? Colors.orange
                                                  : Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Creator Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF3A4A5C)
                                    : const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar and Username Row
                                  Row(
                                    children: [
                                      // Creator Avatar
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              const Color(0xFF4A90E2),
                                              const Color(0xFF357088),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            creatorName.isNotEmpty && creatorName != 'Unknown'
                                                ? creatorName.substring(0, 1).toUpperCase()
                                                : '?',
                                            style:  TextStyle(
                                              color: Colors.white,
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          creatorName,
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : const Color(0xFF2C3E50),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Created By Label and Role Row
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF357088).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.person_outline,
                                          color: const Color(0xFF357088),
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF357088).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            creatorRole,
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: const Color(0xFF357088),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Date Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF3A4A5C)
                                    : const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.access_time,
                                      color: Colors.purple,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Created:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : const Color(0xFF2C3E50),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTaskStatus(String title) {
    if (adminController.completedTaskTitles.contains(title)) {
      return AppStrings.completed;
    } else if (adminController.pendingTaskTitles.contains(title)) {
      return AppStrings.notCompleted;
    } else {
      return AppStrings.unknown;
    }
  }

  void _showAllPendingTasksDialog() {
    final tasks = adminController.pendingTaskTitles;
    final docs = adminController.taskSnapshotDocs;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: math.max(MediaQuery.of(context).size.width * 0.9, 400),
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2C3E50)
                      : Colors.white,
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF34495E)
                      : const Color(0xFFF8F9FA),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4A90E2),
                        const Color(0xFF357088),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_late_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Tasks',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              tasks.isEmpty 
                                  ? 'All tasks completed! 🎉'
                                  : '${tasks.length} task${tasks.length != 1 ? 's' : ''} awaiting completion',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: tasks.isEmpty
                        ? _buildEmptyState()
                        : StatefulBuilder(
                            builder: (ctx, setState) => ListView.builder(
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                          final title = tasks[index];
                          final doc = docs.firstWhereOrNull((d) => d['title'] == title);

                          final creatorId = doc?['createdBy'] ?? 'Unknown';
                          final userInfo = userCache[creatorId];
                          if (userInfo == null && creatorId != 'Unknown') {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              getUserNameAndRole(creatorId, () => setState(() {}));
                            });
                          }
                          final creatorName = userInfo?["name"] ?? 'Unknown';
                          final creatorRole = userInfo?["role"] ?? "Unknown";

                          String dateStr = 'Unknown';
                          final createdAt = doc?['timestamp'];
                          if (createdAt != null) {
                            DateTime dt;
                            if (createdAt is Timestamp) {
                              dt = createdAt.toDate();
                            } else if (createdAt is DateTime) {
                              dt = createdAt;
                            } else {
                              dt = DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
                            }
                            dateStr = "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF3A4A5C)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _showTaskDetailDialog(title);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.task_alt,
                                              color: const Color(0xFF4A90E2),
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 14,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white70
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            flex: 2,
                                            child: Text(
                                              creatorName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white70
                                                    : Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            flex: 1,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF357088).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                creatorRole,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: const Color(0xFF357088),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                       ),
                                       const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white70
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              dateStr,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white70
                                                    : Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2C3E50)
                        : const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Get.find<SettingsController>().triggerFeedback();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4CAF50).withValues(alpha: 0.2),
                        const Color(0xFF8BC34A).withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          // Title
          Text(
            'All Caught Up!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Subtitle
          Text(
            'Great job! There are no pending tasks at the moment.\nEverything is up to date.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          // Decorative elements
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEmptyStateIcon(Icons.task_alt, const Color(0xFF4CAF50)),
              const SizedBox(width: 20),
              _buildEmptyStateIcon(Icons.done_all, const Color(0xFF2196F3)),
              const SizedBox(width: 20),
              _buildEmptyStateIcon(Icons.celebration, const Color(0xFFFF9800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = AppDevices.isTablet(context);
    AppDevices.getScreenWidth(context);

    return Obx(() {
      // Add safety check for build phase
      if (!mounted) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      
      if (adminController.isLoading.value ||
          adminController.isStatsLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        body: SafeArea(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).canvasColor
                  : Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserHeader(isDark: isDark, scaffoldKey: _scaffoldKey),
                
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  
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
                              Get.find<SettingsController>().triggerFeedback();
                              Get.toNamed('/manage-users');
                            },
                            onTotalTasksTap: () {
                              Get.find<SettingsController>().triggerFeedback();
                              _showAllPendingTasksDialog();
                            },
                            onNewsFeedTap: () {
                              Get.find<SettingsController>().triggerFeedback();
                              Get.toNamed('/news');
                            },
                            onOnlineUsersTap: () {
                              Get.find<SettingsController>().triggerFeedback();
                              Get.toNamed('/all-users-chat');
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
                              color: Theme.of(context).colorScheme.onPrimary,
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
                                      onTap: () => Get.toNamed('/create-task'),
                                      child: Container(
                                        width: 34.w,
                                        height: 34.h,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Theme.of(context).colorScheme.onPrimary
                                              : const Color(0xFF3739B7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          size: 22.sp,
                                          color: isDark
                                              ? const Color(0xFF3739B7)
                                              : Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TabBar(
                                controller: _tabController,
                                indicatorColor: isDark
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.primary,
                                labelColor: isDark
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.primary,
                                unselectedLabelColor:
                                    isDark ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7) : Colors.black54,
                                labelStyle: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 15),
                                isScrollable: true,
                                tabs: const [
                                  Tab(text: "Not Completed"),
                                  Tab(text: "Completed"),
                                  Tab(text: "User Performance"),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.48,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _TasksTab(
                                      tasks: adminController.pendingTaskTitles,
                                      taskDocs:
                                          adminController.taskSnapshotDocs,
                                      onTaskTap: _showTaskDetailDialog,
                                      isDark: isDark,
                                      userCache: userCache,
                                      getUserNameAndRole: getUserNameAndRole,
                                    ),
                                    _TasksTab(
                                      tasks:
                                          adminController.completedTaskTitles,
                                      taskDocs:
                                          adminController.taskSnapshotDocs,
                                      onTaskTap: _showTaskDetailDialog,
                                      isDark: isDark,
                                      userCache: userCache,
                                      getUserNameAndRole: getUserNameAndRole,
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
        bottomNavigationBar: const UserNavBar(currentIndex: 0),
      );
    });
  }
}

class _TasksTab extends StatefulWidget {
  final List<dynamic> tasks;
  final List<dynamic> taskDocs;
  final void Function(String title) onTaskTap;
  final bool isDark;
  final Map<String, Map<String, String>> userCache;
  final Future<Map<String, String>> Function(String, VoidCallback)
      getUserNameAndRole;

  const _TasksTab({
    required this.tasks,
    required this.taskDocs,
    required this.onTaskTap,
    required this.isDark,
    required this.userCache,
    required this.getUserNameAndRole,
  });

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {

  @override
  Widget build(BuildContext context) {
    final Color emptyListColor =
        widget.isDark ? Colors.white70 : Colors.black54;

    if (widget.tasks.isEmpty) {
      return Center(
        child: Text("No tasks.", style: TextStyle(color: emptyListColor)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: widget.tasks.length,
      itemBuilder: (context, index) {
        final title = widget.tasks[index];
        final Map<String, dynamic> doc = widget.taskDocs.firstWhere(
          (d) => d['title'] == title,
          orElse: () => <String, dynamic>{},
        );
        if (doc.isEmpty) {
          return const SizedBox.shrink();
        }
        // Map doc to Task object
        final task = Task.fromMap(doc, doc['id'] ?? doc['taskId'] ?? '');
        final taskId = task.taskId;
        if (taskId.toString().isEmpty) {
          debugPrint('Task with missing/null taskId: $task');
          return const SizedBox.shrink();
        }
        // Optionally, check for duplicate keys (not strictly necessary, but helpful for debugging)
        // You could keep a Set of seen ids if you want to debug further.
        return TaskCardWidget(
          key: ValueKey(taskId),
          task: task,
          isCompleted: task.status == 'Completed',
          isDark: widget.isDark,
        );
      },
    );
  }
}
