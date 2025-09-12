import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_controller.dart';
import '../../models/report_completion_info.dart';

class TaskDetailDialog {
  static void show({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> taskSnapshotDocs,
    required Map<String, Map<String, String>> userCache,
    required Future<Map<String, String>> Function(String, VoidCallback) getUserNameAndRole,
  }) {
    final doc = taskSnapshotDocs.firstWhereOrNull((d) => d['title'] == title);

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
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C3E50)
              : Colors.white,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9E9E9E),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                _buildContent(context, title, creatorId, dateStr, userCache, getUserNameAndRole),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildHeader(BuildContext context) {
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
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Task Details',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
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
    String title,
    String creatorId,
    String dateStr,
    Map<String, Map<String, String>> userCache,
    Future<Map<String, String>> Function(String, VoidCallback) getUserNameAndRole,
  ) {
    return Flexible(
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
            // First try to get createdByName from the task document, then fall back to userCache
            final doc = Get.find<AdminController>().taskSnapshotDocs.firstWhereOrNull((d) => d['title'] == title);
            final creatorName = doc?['createdByName'] ?? userInfo?["name"] ?? 'Unknown';
            final creatorRole = userInfo?["role"] ?? "Unknown";
            final taskStatus = _getTaskStatus(title, context);
            
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTaskTitleSection(context, title),
                  const SizedBox(height: 12),
                  _buildStatusSection(context, taskStatus),
                  const SizedBox(height: 12),
                  _buildCreatorSection(context, creatorName, creatorRole),
                  const SizedBox(height: 12),
                  _buildDateSection(context, dateStr),
                  if (taskStatus == 'Completed') ..._buildCompletionComments(context, title),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _buildTaskTitleSection(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.task_alt,
                  color: Theme.of(context).colorScheme.onPrimary,
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
    );
  }

  static Widget _buildStatusSection(BuildContext context, String taskStatus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: taskStatus == 'Completed'
                  ? const Color(0xFFE8F5E8)
                  : taskStatus == 'Not Completed'
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFF5F5F5),
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
                    ? Colors.green
                    : taskStatus == 'Not Completed'
                        ? Colors.orange
                        : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                taskStatus,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCreatorSection(BuildContext context, String creatorName, String creatorRole) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    creatorName.isNotEmpty && creatorName != 'Unknown'
                        ? creatorName.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    creatorRole,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Theme.of(context).colorScheme.onPrimary,
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
    );
  }

  static Widget _buildDateSection(BuildContext context, String dateStr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: Colors.green,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Created:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dateStr,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<Widget> _buildCompletionComments(BuildContext context, String title) {
    try {
      final adminController = Get.find<AdminController>();
      final doc = adminController.taskSnapshotDocs.firstWhereOrNull((d) => d['title'] == title);
      
      if (doc == null || doc['reportCompletionInfo'] == null) {
        return [];
      }
      
      final reportCompletionInfoMap = Map<String, dynamic>.from(doc['reportCompletionInfo'] ?? {});
      
      if (reportCompletionInfoMap.isEmpty) {
        return [];
      }
      
      List<Widget> widgets = [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.comment_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Completion Comments',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...reportCompletionInfoMap.entries.map((entry) {
                final completionData = Map<String, dynamic>.from(entry.value ?? {});
                final reportCompletionInfo = ReportCompletionInfo.fromMap(completionData);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Has Aired: ${reportCompletionInfo.hasAired ? "Yes" : "No"}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      if (reportCompletionInfo.airTime != null)
                        Text(
                          'Air Time: ${DateFormat('MMM dd, yyyy HH:mm').format(reportCompletionInfo.airTime!)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      if (reportCompletionInfo.videoEditorName != null && reportCompletionInfo.videoEditorName!.isNotEmpty)
                        Text(
                          'Video Editor: ${reportCompletionInfo.videoEditorName}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      if (reportCompletionInfo.comments != null && reportCompletionInfo.comments!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Comments: ${reportCompletionInfo.comments}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ];
      
      return widgets;
    } catch (e) {
      return [];
    }
  }

  static String _getTaskStatus(String title, BuildContext context) {
    try {
      // Get AdminController to access task documents
      final adminController = Get.find<AdminController>();
      final doc = adminController.taskSnapshotDocs.firstWhereOrNull((d) => d['title'] == title);
      
      if (doc == null) return 'Unknown';
      
      final status = (doc['status'] ?? '').toString().toLowerCase();
      if (status != 'completed') {
        return 'Not Completed';
      }
      
      // Check if all assigned users have completed the task (same logic as AdminController)
      final completedByUserIds = List<String>.from(doc['completedByUserIds'] ?? []);
      final assignedUserIds = <String>[];
      
      // Collect all assigned user IDs
      if (doc['assignedReporterId'] != null && doc['assignedReporterId'].toString().isNotEmpty) {
        assignedUserIds.add(doc['assignedReporterId'].toString());
      }
      if (doc['assignedCameramanId'] != null && doc['assignedCameramanId'].toString().isNotEmpty) {
        assignedUserIds.add(doc['assignedCameramanId'].toString());
      }
      if (doc['assignedDriverId'] != null && doc['assignedDriverId'].toString().isNotEmpty) {
        assignedUserIds.add(doc['assignedDriverId'].toString());
      }
      if (doc['assignedLibrarianId'] != null && doc['assignedLibrarianId'].toString().isNotEmpty) {
        assignedUserIds.add(doc['assignedLibrarianId'].toString());
      }
      
      // If no users are assigned, treat as completed (backward compatibility)
      if (assignedUserIds.isEmpty) {
        return 'Completed';
      }
      
      // If completedByUserIds is empty, it's using old logic, so count as completed
      if (completedByUserIds.isEmpty) {
        return 'Completed';
      }
      
      // Check if all assigned users have completed the task
      final allCompleted = assignedUserIds.every((userId) => completedByUserIds.contains(userId));
      return allCompleted ? 'Completed' : 'Not Completed';
    } catch (e) {
      return 'Unknown';
    }
  }
}