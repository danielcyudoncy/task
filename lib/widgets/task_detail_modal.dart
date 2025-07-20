// widgets/task_detail_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/models/task_model.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'status_chip.dart';

class TaskDetailModal extends StatelessWidget {
  final Task task;
  final bool isDark;

  const TaskDetailModal({
    super.key,
    required this.task,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Print tags for troubleshooting
    debugPrint('Task tags: ${task.tags}');
    debugPrint('Task tags length: ${task.tags?.length}');
    debugPrint('Task tags isNotEmpty: ${task.tags?.isNotEmpty}');
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    // Theme-aware colors
    final Color bgColor = colorScheme.surface;
    final Color mainText = colorScheme.onSurface;
    final Color subText = colorScheme.onSurfaceVariant;
    final Color accent = colorScheme.primary;
    final Color borderColor = colorScheme.outline.withAlpha((0.3 * 255).toInt());

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500.w,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withAlpha((0.5 * 255).round()) : const Color(0x30000000),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.task_alt,
                    color: accent,
                    size: 24.sp,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Task Details',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: mainText,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Get.find<SettingsController>().triggerFeedback();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.close,
                      color: mainText,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: mainText,
                              fontSize: 22.sp,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        StatusChip(
                          status: task.status,
                          textScale: 1.0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        task.description,
                        style: textTheme.bodyLarge?.copyWith(
                          color: mainText,
                          fontSize: 16.sp,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Task Details Grid
                    _buildDetailSection(
                      context,
                      'Task Information',
                      [
                        _buildDetailRow(context, 'Created by', task.createdBy, Icons.person_outline),
                        if (task.category != null && task.category!.isNotEmpty)
                          _buildDetailRow(context, 'Category', task.category!, Icons.category_outlined),
                        if (task.priority != null && task.priority!.isNotEmpty)
                          _buildDetailRow(context, 'Priority', task.priority!, Icons.flag_outlined, 
                              valueColor: _getPriorityColor(task.priority!)),
                        if (task.dueDate != null)
                          _buildDetailRow(context, 'Due Date', 
                              DateFormat('MMM dd, yyyy HH:mm').format(task.dueDate!), 
                              Icons.schedule_outlined),
                        _buildDetailRow(context, 'Created', 
                            DateFormat('MMM dd, yyyy HH:mm').format(task.timestamp.toDate()), 
                            Icons.access_time_outlined),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Assignment Details
                    _buildDetailSection(
                      context,
                      'Assignment Details',
                      [
                        _buildDetailRow(context, 'Reporter', 
                            task.assignedReporter ?? 'Not assigned', 
                            Icons.person_outline),
                        _buildDetailRow(context, 'Cameraman', 
                            task.assignedCameraman ?? 'Not assigned', 
                            Icons.videocam_outlined),
                        _buildDetailRow(context, 'Driver', 
                            task.assignedDriver ?? 'Not assigned', 
                            Icons.directions_car_outlined),
                        _buildDetailRow(context, 'Librarian', 
                            task.assignedLibrarian ?? 'Not assigned', 
                            Icons.library_books_outlined),
                      ],
                    ),
                    
                    // Tags Section
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      context,
                      'Tags',
                      [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          child: task.tags != null && task.tags!.isNotEmpty
                              ? Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: task.tags!.map((tag) => Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.blue.withOpacity(0.2) : accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? Colors.blue.withOpacity(0.3) : accent.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: isDark ? Colors.white : accent,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )).toList(),
                                )
                              : Text(
                                  'No tags assigned',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: subText,
                                    fontSize: 14.sp,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    
                    // Comments (if available)
                    if (task.comments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        context,
                        'Comments (${task.comments.length})',
                        task.comments.map((comment) => Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          margin: EdgeInsets.only(bottom: 8.h),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            comment,
                            style: textTheme.bodyMedium?.copyWith(
                              color: mainText,
                              fontSize: 14.sp,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withAlpha((0.2 * 255).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: 16.sp,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon, {Color? valueColor}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
              fontSize: 14.sp,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: valueColor ?? colorScheme.onSurface,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 