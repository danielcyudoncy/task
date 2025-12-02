// widgets/dialogs/pending_tasks_dialog.dart
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';

class PendingTasksDialog {
  static void show({
    required BuildContext context,
    required Map<String, Map<String, String>> userCache,
    required Future<Map<String, String>> Function(String, VoidCallback)
        getUserNameAndRole,
    required Function(String) onTaskTap,
  }) {
    final AdminController adminController = Get.find<AdminController>();
    final tasks = adminController.pendingTaskTitles;
    final docs = adminController.taskSnapshotDocs;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C3E50)
              : Colors.white,
          child: Container(
            width: math.max(MediaQuery.of(context).size.width * 0.9, 400),
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2C3E50)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9E9E9E),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(context, tasks),
                _buildContent(context, tasks, docs, userCache,
                    getUserNameAndRole, onTaskTap),
                _buildFooter(context),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildHeader(BuildContext context, List<String> tasks) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
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
              color: Theme.of(context).colorScheme.onPrimary.withAlpha(2),
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
                    color: Theme.of(context).colorScheme.onPrimary,
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
                    color: Theme.of(context).colorScheme.onPrimary.withAlpha(9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.onPrimary.withAlpha(2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildContent(
    BuildContext context,
    List<String> tasks,
    List<Map<String, dynamic>> docs,
    Map<String, Map<String, String>> userCache,
    Future<Map<String, String>> Function(String, VoidCallback)
        getUserNameAndRole,
    Function(String) onTaskTap,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: tasks.isEmpty
            ? SingleChildScrollView(
                child: _buildEmptyState(context),
              )
            : StatefulBuilder(
                builder: (ctx, setState) => ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final title = tasks[index];
                    final doc =
                        docs.firstWhereOrNull((d) => d['title'] == title);

                    final creatorId = doc?['createdBy'] ?? 'Unknown';
                    final userInfo = userCache[creatorId];
                    if (userInfo == null && creatorId != 'Unknown') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        getUserNameAndRole(creatorId, () {
                          // userCache is modified directly, no setState needed
                        });
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
                        dt = DateTime.tryParse(createdAt.toString()) ??
                            DateTime.now();
                      }
                      dateStr =
                          "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                    }

                    return _buildTaskItem(context, title, creatorName,
                        creatorRole, dateStr, onTaskTap);
                  },
                ),
              ),
      ),
    );
  }

  static Widget _buildTaskItem(
    BuildContext context,
    String title,
    String creatorName,
    String creatorRole,
    String dateStr,
    Function(String) onTaskTap,
  ) {
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
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF3A4A5C)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).pop();
            onTaskTap(title);
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
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.task_alt,
                        color: Color(0xFF4A90E2),
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
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          creatorName.isNotEmpty && creatorName != 'Unknown'
                              ? creatorName.substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            creatorName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF2C3E50),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              creatorRole,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF34495E)
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
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
    );
  }

  static Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4CAF50).withValues(alpha: 0.8),
                        const Color(0xFF2196F3).withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'All Caught Up!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No pending tasks at the moment.\nGreat work, team! 🎉',
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

  static Widget _buildEmptyStateIcon(IconData icon, Color color) {
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
}
